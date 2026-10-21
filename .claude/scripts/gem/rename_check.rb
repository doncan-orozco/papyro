#!/usr/bin/env ruby
# frozen_string_literal: true

# Judge of the chadcn rename (epic chadcn-rebrand): lists every leftover old spelling of the gem in the git-tracked
# files of the host repo (gem included) and of the papyro_studio engine. Plain Ruby, no gems, no network.
#
#   ruby .claude/scripts/gem/rename_check.rb --stage ruby|stimulus|all [--root .] [--engine-dir DIR|none]
#                                            [--format text|json]
#   ruby .claude/scripts/gem/rename_check.rb --stage ruby --self-test   # proves the judge catches every MAPPING row
#   ruby .claude/scripts/gem/rename_check.rb --mapping                  # the old -> new table as JSON
#
# Exit 0 clean, 1 leftovers or failed self-test, 2 usage/environment error (git missing, engine not found without
# --engine-dir none, stray arguments).
#
# Stages: `ruby` = gem name, require path, module, lib/test/generator dirs, rake/generator/config/env names, CSS
# markers, workflow and job names; `stimulus` = the `shadcn--` controller prefix, `shadcn__` data keys, the
# controllers/primitives dirs and their importmap names. File PATHS are checked as well as contents; a binary
# tracked file that holds an old spelling is reported without a line. node_modules is never scanned. Without
# --engine-dir the engine is the
# `papyro_studio` sibling of --root or of the main checkout (worktrees included); when none is found the run fails with
# exit 2 (pass `--engine-dir DIR` or `--engine-dir none`).
#
# MAPPING is the single old -> new table: the rename items rewrite with it and this judge reports with it, so they
# cannot disagree. `pattern` is Ruby regex source. Rewriters apply the `rewrite: :literal` rows in table order (most
# specific first); `:manual` rows need a hand edit described by `note`. Each match is reported once, under the first
# row that covers it.
#
# Not leftovers (masked before matching): names of upstream shadcn/ui and our port tooling for it (UPSTREAM), the slugs
# of the closed phlex-shadcn epics (HISTORY: labels, branches and notes of closed issues keep their names), CHANGELOG
# lines that record the rename (they name chadcn too), the epic's own docs (docs/features/chadcn-rebrand/) and this
# checker with its test. Issue and PR history on GitHub is never scanned.

require "fileutils"
require "json"
require "open3"
require "optparse"
require "tmpdir"

module RenameCheck
  class GitError < StandardError; end
  class UnknownStage < StandardError; end
  class UsageError < StandardError; end

  # Left boundary: `gems/phlex-shadcn`, `data-shadcn--x`, `"shadcn__x` all match; `chadcn--` never does.
  LEFT_BOUNDARY = "(?<![A-Za-z0-9])"
  SNIPPET_LENGTH = 160
  Row = Struct.new(:stage, :old, :new, :pattern, :ruby_source_only, :sample, :rewrite, :note, keyword_init: true)
  Finding = Data.define(:file, :line, :kind, :old, :new, :stage, :rewrite, :text)

  build_row = ->(stage, old, new, pattern: nil, ruby_source_only: false, sample: old, rewrite: :literal, note: nil) do
    pattern ||= /#{LEFT_BOUNDARY}#{Regexp.escape(old)}/
    Row.new(stage:, old:, new:, pattern:, ruby_source_only:, sample:, rewrite:, note:)
  end

  MAPPING = [
    build_row.call(:ruby, "doncan-orozco/phlex-shadcn", "doncan-orozco/chadcn"),
    build_row.call(:ruby, "gems/phlex-shadcn", "gems/chadcn"),
    build_row.call(:ruby, "app/assets/tailwind/phlex-shadcn", "app/assets/tailwind/chadcn"),
    build_row.call(:ruby, "skills/phlex-shadcn", "skills/chadcn"),
    build_row.call(:ruby, "phlex-shadcn.gemspec", "chadcn.gemspec"),
    build_row.call(:ruby, "phlex-shadcn.yml", "chadcn.yml"),
    build_row.call(:ruby, "phlex-shadcn:start", "chadcn:start"),
    build_row.call(:ruby, "phlex-shadcn:end", "chadcn:end"),
    build_row.call(:ruby, "phlex-shadcn", "chadcn"),
    build_row.call(:ruby, "lib/generators/phlex/shadcn", "lib/generators/chadcn"),
    build_row.call(:ruby, "lib/phlex/shadcn", "lib/chadcn"),
    build_row.call(:ruby, "test/phlex/shadcn", "test/chadcn"),
    build_row.call(:ruby, "phlex/shadcn", "chadcn"),
    build_row.call(:ruby, "phlex:shadcn:install", "chadcn:install"),
    build_row.call(:ruby, "phlex:shadcn:eject", "chadcn:eject"),
    build_row.call(:ruby, "phlex:shadcn", "chadcn"),
    build_row.call(:ruby, "gem_phlex_shadcn", "gem_chadcn"),
    build_row.call(:ruby, "config.phlex_shadcn", "config.chadcn"),
    build_row.call(:ruby, "phlex_shadcn:", "chadcn:", sample: "phlex_shadcn:doctor"),
    build_row.call(:ruby, "phlex_shadcn", "chadcn"),
    build_row.call(:ruby, "PHLEX_SHADCN_", "CHADCN_"),
    build_row.call(:ruby, "PHLEX_SHADCN", "CHADCN"),
    build_row.call(:ruby, "Phlex::Shadcn", "Chadcn"),
    build_row.call(:ruby, "PhlexShadcn", "Chadcn"),
    build_row.call(:ruby, "module Shadcn", "module Chadcn", pattern: /\bmodule\s+Shadcn\b/, rewrite: :manual,
                   note: "unwrap the enclosing `module Phlex`: Chadcn is top level"),
    build_row.call(:ruby, "Shadcn::", "Chadcn::", pattern: /(?<![\w:])Shadcn::/, sample: "Shadcn::Theme"),
    build_row.call(:ruby, "Shadcn.", "Chadcn.", pattern: /(?<![\w:])Shadcn\.(?=[a-z_])/, ruby_source_only: true,
                   sample: "Shadcn.config"),
    build_row.call(:ruby, "for_gem_extension(Phlex)", "for_gem", pattern: /for_gem_extension\(\s*Phlex\s*\)/),
    build_row.call(:stimulus, "shadcn---probe-", "chadcn---probe-"),
    build_row.call(:stimulus, "shadcn--", "chadcn--"),
    build_row.call(:stimulus, "shadcn__", "chadcn__"),
    build_row.call(:stimulus, "app/javascript/controllers/shadcn", "app/javascript/controllers/chadcn",
                   pattern: %r{#{LEFT_BOUNDARY}app/javascript/controllers/shadcn(?![\w-])}),
    build_row.call(:stimulus, "controllers/shadcn", "controllers/chadcn",
                   pattern: %r{#{LEFT_BOUNDARY}controllers/shadcn(?![\w-])}),
    build_row.call(:stimulus, "app/javascript/shadcn", "app/javascript/chadcn",
                   pattern: %r{#{LEFT_BOUNDARY}app/javascript/shadcn(?![\w-])}),
    build_row.call(:stimulus, "javascript/shadcn", "javascript/chadcn",
                   pattern: %r{#{LEFT_BOUNDARY}javascript/shadcn(?![\w-])}),
    build_row.call(:stimulus, "shadcn/primitives", "chadcn/primitives", pattern: %r{(?<![\w./-])shadcn/primitives\b}),
    build_row.call(:stimulus, 'under: "shadcn"', 'under: "chadcn"')
  ].freeze
  STAGES = MAPPING.map(&:stage).uniq.freeze

  # Upstream shadcn/ui and the port tooling that names it: never renamed (epic body, "What does NOT rename").
  UPSTREAM = [
    %r{(?<![\w/.-])shadcn/ui\b}, /ui\.shadcn\.com/, /react-shadcn-catalog/, %r{\.claude/scripts/shadcn/},
    %r{/shadcn-(?:plan|run|audit|golden)\b}, /(?<![\w-])shadcn-port/, /radix-stimulus/
  ].freeze
  # Closed epics keep their slugs (labels `epic:<slug>`, branches `epic/<slug>/...`, notes "item #N (<slug>)").
  HISTORY = [
    /phlex-shadcn-(?:adoption-followups|adoption|hardening)(?![\w-])/,
    %r{(?:epic[:/ ]|--epic )phlex-shadcn(?![\w-])}, /phlex-shadcn epic\b/
  ].freeze
  MASKS = (UPSTREAM + HISTORY).freeze
  ALLOWED_PATHS = Regexp.union(
    %r{\Adocs/features/chadcn-rebrand/},
    %r{\A\.claude/scripts/gem/rename_check\.rb\z},
    %r{\Atest/lib/gem/rename_check_test\.rb\z}
  ).freeze
  CHANGELOG = %r{(?:\A|/)CHANGELOG[^/]*\z}i
  RENAME_RECORD = /renam.*chadcn|chadcn.*renam/i
  RUBY_FILE = %r{(?:\.(?:rb|rake|gemspec|ru)|(?:\A|/)(?:Gemfile|Rakefile))\z}
  RENAME_RECORD_LINE = "- Renamed phlex-shadcn to chadcn (Phlex::Shadcn is now Chadcn).\n"
  SKIPPED = %r{(?:\A|/)node_modules/}
  PREFILTER = /shadcn|for_gem_extension/i

  module_function

  def rows(stage)
    return MAPPING if stage == :all
    unless STAGES.include?(stage)
      raise UnknownStage, "unknown stage #{stage.inspect} (expected #{(STAGES + [ :all ]).join(', ')})"
    end

    MAPPING.select { |row| row.stage == stage }
  end

  def mask(text)
    MASKS.reduce(text) { |masked, mask_pattern| masked.gsub(mask_pattern) { |hit| "~" * hit.size } }
  end

  # Every leftover in one string: [row, ...], one per match, first (most specific) row wins an overlap.
  def matches(text, selected_rows, ruby_source:)
    return [] unless text.match?(PREFILTER)

    masked = mask(text)
    claimed_spans = []
    selected_rows.each_with_object([]) do |row, hit_rows|
      next if row.ruby_source_only && !ruby_source

      masked.scan(row.pattern) do
        span = $~.offset(0)
        next if claimed_spans.any? { |(from, upto)| span[0] < upto && from < span[1] }

        claimed_spans << span
        hit_rows << row
      end
    end
  end

  # stdout of `git <args>`; a failing or missing git is a GitError.
  def git_stdout(*args)
    out, err, status = Open3.capture3("git", *args)
    raise GitError, "git #{args.join(' ')} failed: #{err.strip}" unless status.success?

    out
  rescue Errno::ENOENT => error
    raise GitError, "git is not available: #{error.message}"
  end

  def tracked(dir)
    paths = git_stdout("-C", dir, "ls-files", "-z").force_encoding(Encoding::UTF_8).split("\0")
    invalid = paths.reject(&:valid_encoding?)
    raise GitError, "#{dir}: tracked paths are not valid UTF-8: #{invalid.map(&:inspect).join(', ')}" if invalid.any?

    paths.reject { |file| file.match?(SKIPPED) }
  end

  def finding(file:, mapping_row:, kind:, line: nil, text: nil)
    Finding.new(
      file:, line:, kind:,
      old: mapping_row.old, new: mapping_row.new, stage: mapping_row.stage, rewrite: mapping_row.rewrite,
      text: text&.strip&.slice(0, SNIPPET_LENGTH)
    )
  end

  # roots: [[label prefix, dir], ...] -> findings
  def scan(roots, stage)
    selected_rows = rows(stage)
    roots.flat_map do |prefix, dir|
      tracked(dir).flat_map do |relative_path|
        next [] if relative_path.match?(ALLOWED_PATHS)

        name = "#{prefix}#{relative_path}"
        findings = matches(relative_path, selected_rows, ruby_source: false).map do |row|
          finding(file: name, mapping_row: row, kind: :path)
        end
        absolute_path = File.join(dir, relative_path)
        next findings unless File.file?(absolute_path)

        findings + scan_content(
          name, File.binread(absolute_path), selected_rows,
          ruby_source: relative_path.match?(RUBY_FILE), rename_record_allowed: relative_path.match?(CHANGELOG)
        )
      end
    end
  end

  def scan_content(name, bytes, selected_rows, ruby_source:, rename_record_allowed:)
    text = String.new(bytes, encoding: Encoding::UTF_8).scrub
    if bytes.include?("\0")
      first_row = matches(text, selected_rows, ruby_source:).first
      return first_row ? [ finding(file: name, mapping_row: first_row, kind: :binary) ] : []
    end

    text.each_line.with_index(1).flat_map do |line, line_number|
      next [] if rename_record_allowed && line.match?(RENAME_RECORD)

      matches(line, selected_rows, ruby_source:).map do |row|
        finding(file: name, mapping_row: row, kind: :content, line: line_number, text: line)
      end
    end
  end

  # The `papyro_studio` sibling of the checkout, or of the main checkout when this is a worktree.
  def default_engine(root)
    git_common_dir, _, status = Open3.capture3(
      "git", "-C", root, "rev-parse", "--path-format=absolute", "--git-common-dir"
    )
    bases = [ root ]
    bases << File.dirname(git_common_dir.strip) if status.success?
    bases.map { |base| File.expand_path("../papyro_studio", base) }.find { |candidate| Dir.exist?(candidate) }
  end

  # Seeds a repo with only allowed names (must pass) and one sample per row (each must be reported under its own row).
  def self_test(stage)
    failures = []
    Dir.mktmpdir("rename-check-self-test") do |dir|
      clean = File.join(dir, "clean")
      seeded = File.join(dir, "seeded")
      seed_repo(clean, "docs/credits.md" => <<~MD, "CHANGELOG.md" => RENAME_RECORD_LINE)
        Ported from shadcn/ui (https://ui.shadcn.com); oracle gems/chadcn/dev/react-shadcn-catalog;
        tooling .claude/scripts/shadcn/layout.rb.
        Commands /shadcn-plan /shadcn-run /shadcn-audit /shadcn-golden; skills shadcn-port and radix-stimulus;
        controllers chadcn--dialog.
        History: epic phlex-shadcn-adoption, label epic:phlex-shadcn-hardening,
        branch epic/phlex-shadcn/107-publish, the phlex-shadcn epic.
        Also --epic phlex-shadcn and the phlex-shadcn epic.
      MD
      leftovers = scan([ [ "", clean ] ], stage)
      if leftovers.any?
        described = leftovers.map { |leftover| "#{leftover.file}:#{leftover.line} #{leftover.old}" }
        failures << "allowed names reported: #{described.join(', ')}"
      end

      selected_rows = rows(stage)
      seed_repo(seeded, "lib/seeded.rb" => selected_rows.map { |row| "x = #{row.sample}\n" }.join)
      findings_by_line = scan([ [ "", seeded ] ], stage).group_by(&:line)
      selected_rows.each.with_index(1) do |row, line_number|
        reported_spellings = (findings_by_line[line_number] || []).map(&:old)
        next if reported_spellings == [ row.old ]

        failures << "row #{row.old.inspect}: sample #{row.sample.inspect} reported as #{reported_spellings.inspect}"
      end
    end
    failures
  end

  def seed_repo(dir, files)
    files.each do |relative_path, content|
      absolute_path = File.join(dir, relative_path)
      FileUtils.mkdir_p(File.dirname(absolute_path))
      File.write(absolute_path, content)
    end
    git_stdout("init", "-q", dir)
    git_stdout("-C", dir, "add", "-A")
  end

  # CLI entry: returns the exit code (0 clean, 1 leftovers, 2 usage/environment error).
  def main(argv, out: $stdout, err: $stderr)
    options = parse_options(argv)
    if options[:mapping]
      out.puts mapping_json
      return 0
    end
    raise UsageError, "--stage ruby|stimulus|all is required" unless options[:stage]
    return run_self_test(options[:stage], out:, err:) if options[:self_test]

    engine = resolve_engine(options)
    roots = [ [ "", options[:root] ] ]
    roots << [ "#{File.basename(engine)}/", engine ] if engine
    report(scan(roots, options[:stage]), options, roots.map(&:last), out:)
  rescue OptionParser::ParseError, UsageError, UnknownStage, GitError, SystemCallError => error
    report_error(err, error.message)
  end

  def parse_options(argv)
    options = { stage: nil, root: File.expand_path("../../..", __dir__), engine: nil, format: "text" }
    remaining = OptionParser.new do |parser|
      parser.on("--stage STAGE", (STAGES + [ :all ]).map(&:to_s)) { |value| options[:stage] = value.to_sym }
      parser.on("--root DIR") { |value| options[:root] = File.expand_path(value) }
      parser.on("--engine-dir DIR") { |value| options[:engine] = value }
      parser.on("--format FORMAT", %w[text json]) { |value| options[:format] = value }
      parser.on("--self-test") { options[:self_test] = true }
      parser.on("--mapping") { options[:mapping] = true }
    end.parse(argv)
    raise UsageError, "unexpected argument(s): #{remaining.join(' ')}" if remaining.any?

    options
  end

  # The engine checkout to scan, or nil for `--engine-dir none`; a missing engine never passes silently.
  def resolve_engine(options)
    case options[:engine]
    when "none" then nil
    when nil
      default_engine(options[:root]) ||
        raise(UsageError,
              "papyro_studio not found next to #{options[:root]}; pass --engine-dir DIR or --engine-dir none")
    else
      engine = File.expand_path(options[:engine])
      raise UsageError, "--engine-dir #{engine} does not exist" unless Dir.exist?(engine)

      engine
    end
  end

  # Prints the error and returns the usage/environment exit code.
  def report_error(err, message)
    err.puts "rename_check: #{message}"
    2
  end

  def run_self_test(stage, out:, err:)
    failures = self_test(stage)
    failures.each { |failure| err.puts "self-test: #{failure}" }
    outcome = failures.empty? ? "ok" : "#{failures.size} failure(s)"
    out.puts "rename_check self-test (#{stage}): #{outcome}, #{rows(stage).size} rows"
    failures.empty? ? 0 : 1
  end

  def report(findings, options, roots, out:)
    if options[:format] == "json"
      out.puts JSON.pretty_generate(
        stage: options[:stage], roots:, pass: findings.empty?, count: findings.size, findings: findings.map(&:to_h)
      )
    else
      findings.each do |finding|
        suffix = "  (#{finding.kind})" unless finding.kind == :content
        out.puts "#{finding.file}:#{finding.line || '-'}: #{finding.old} -> #{finding.new}#{suffix}"
      end
      file_count = findings.map(&:file).uniq.size
      summary = findings.empty? ? "clean" : "#{findings.size} leftover(s) in #{file_count} file(s)"
      out.puts "rename_check (#{options[:stage]}): #{summary}; scanned #{roots.join(', ')}"
    end
    findings.empty? ? 0 : 1
  end

  def mapping_json
    table = MAPPING.map do |row|
      {
        stage: row.stage, old: row.old, new: row.new, pattern: row.pattern.source,
        ruby_source_only: row.ruby_source_only, rewrite: row.rewrite, note: row.note
      }
    end
    JSON.pretty_generate(table)
  end
end

exit RenameCheck.main(ARGV) if $PROGRAM_NAME == __FILE__
