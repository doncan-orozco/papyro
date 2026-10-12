#!/usr/bin/env ruby
# frozen_string_literal: true

# Minimal stand-in for the `gh` CLI, backed by a JSON file (WORK_FAKE_DB), used to test .claude/scripts/epic/work_board.rb
# without touching GitHub. Output shapes follow `gh` 2.87: issue number/title/state (OPEN|CLOSED)/labels [{name}]/body/
# createdAt/comments [{body, createdAt, author{login}}]. The file is locked, so concurrent processes can race safely.
#
# Used two ways: in-process (FakeGh.call(argv), fast, most tests) or as an executable (WORK_GH="ruby fake_gh.rb", the real
# subprocess path, used by the concurrency test).
# Supported: issue create|list|view|edit|comment|close|reopen, label create.

require "json"
require "time"

class FakeGh
  class Error < StandardError; end

  def self.call(argv) = new(ENV.fetch("WORK_FAKE_DB")).call(argv)

  def initialize(path)
    @path = path
  end

  def call(argv)
    group, verb, *args = argv
    case [ group, verb ]
    when %w[issue create] then create(args)
    when %w[issue list] then list(args)
    when %w[issue view] then JSON.generate(view(find(args.first)))
    when %w[issue edit] then edit(args)
    when %w[issue comment] then comment(args)
    when %w[issue close], %w[issue reopen] then mutate(args.first) { |i| i["state"] = verb == "close" ? "CLOSED" : "OPEN" }
    when %w[label create] then locked { |db| db["labels"] |= [ args.first ] } && ""
    else raise Error, "fake gh: unsupported #{argv.first(2).join(' ')}"
    end
  end

  private

  def locked
    File.open("#{@path}.lock", File::CREAT | File::RDWR) do |lock|
      lock.flock(File::LOCK_EX)
      db = File.exist?(@path) ? JSON.parse(File.read(@path)) : { "issues" => [], "labels" => [], "next" => 1 }
      result = yield db
      File.write(@path, JSON.generate(db))
      result
    end
  end

  def flag(args, name) = (i = args.index(name)) ? args[i + 1] : nil
  def flag_values(args, name) = args.each_index.flat_map { |i| args[i] == name ? args[i + 1].to_s.split(",") : [] }
  def body_of(args) = flag(args, "--body-file") ? File.read(flag(args, "--body-file")) : flag(args, "--body").to_s
  def view(issue) = issue.slice("number", "title", "state", "labels", "body", "createdAt", "comments")

  def find(number)
    locked { |db| db["issues"].find { |i| i["number"] == number.to_i } } || raise(Error, "issue #{number} not found")
  end

  def mutate(number)
    locked do |db|
      issue = db["issues"].find { |i| i["number"] == number.to_i } or raise Error, "issue #{number} not found"
      yield issue
    end
    ""
  end

  # Real gh rejects labels that do not exist in the repository (create, add and remove alike).
  def require_labels!(db, names)
    missing = names - db["labels"]
    raise Error, "'#{missing.first}' not found" if missing.any?
  end

  def create(args)
    body = body_of(args)
    number = locked do |db|
      require_labels!(db, flag_values(args, "--label"))
      n = db["next"]
      db["next"] += 1
      db["issues"] << { "number" => n, "title" => flag(args, "--title"), "state" => "OPEN", "body" => body,
                        "labels" => flag_values(args, "--label").map { |l| { "name" => l } }, "createdAt" => Time.now.utc.iso8601, "comments" => [] }
      n
    end
    "https://github.test/owner/repo/issues/#{number}"
  end

  def list(args)
    wanted = flag_values(args, "--label")
    state = flag(args, "--state") || "open"
    rows = locked { |db| db["issues"].dup }
    rows = rows.select { |i| (wanted - i["labels"].map { |l| l["name"] }).empty? }
    rows = rows.select { |i| state == "all" || i["state"].downcase == state }
    JSON.generate(rows.map { |i| view(i) })
  end

  def edit(args)
    locked { |db| require_labels!(db, flag_values(args, "--add-label") + flag_values(args, "--remove-label")) }
    mutate(args.first) do |i|
      names = i["labels"].map { |l| l["name"] }
      names |= flag_values(args, "--add-label")
      names -= flag_values(args, "--remove-label")
      i["labels"] = names.map { |n| { "name" => n } }
    end
  end

  def comment(args)
    body = body_of(args)
    mutate(args.first) { |i| i["comments"] << { "body" => body, "createdAt" => Time.now.utc.iso8601, "author" => { "login" => "fake" } } }
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    out = FakeGh.call(ARGV)
    puts out unless out.empty?
  rescue FakeGh::Error => e
    warn e.message
    exit 1
  end
end
