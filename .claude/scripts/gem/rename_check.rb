#!/usr/bin/env ruby
# frozen_string_literal: true

# Judge of the chadcn rename (epic chadcn-rebrand): lists every leftover old spelling of the gem in the git-tracked files of the host
# repo (gem included) and of the papyro_studio engine. Plain Ruby, no gems, no network.
#
#   ruby .claude/scripts/gem/rename_check.rb --stage ruby|stimulus|all [--root .] [--engine-dir ../papyro_studio|none] [--format text|json]
#   ruby .claude/scripts/gem/rename_check.rb --stage ruby --self-test    # proves the judge still catches every row of MAPPING
#   ruby .claude/scripts/gem/rename_check.rb --mapping                   # the old -> new table as JSON, for the rename items
#
# Exit 0 clean, 1 leftovers (or a failed self-test), 2 usage error.
#
# Stages: `ruby` = gem name, require path, module, lib/test/generator dirs, rake/generator/config/env names, CSS markers, workflow
# and job names; `stimulus` = the `shadcn--` controller prefix, `shadcn__` data keys, the controllers/primitives dirs and their
# importmap names. File PATHS are checked as well as contents; a binary tracked file that holds an old spelling is reported without
# a line. node_modules is never scanned. The engine defaults to the `papyro_studio` sibling of the main checkout (worktrees
# included); when it is not there it is skipped with a warning.
#
# MAPPING is the single old -> new table: the rename items rewrite with it and this judge reports with it, so they cannot disagree.
# Rows are ordered most specific first; each match is reported once, under the first row that covers it.
#
# Not leftovers (masked before matching): names of upstream shadcn/ui and our port tooling for it (UPSTREAM), the slugs of the
# closed phlex-shadcn epics (HISTORY: labels, branches and notes of closed issues keep their names), CHANGELOG lines that record the
# rename (they name chadcn too), the epic's own docs (docs/features/chadcn-rebrand/) and this checker with its test. Issue and PR
# history on GitHub is never scanned.

require "fileutils"
require "json"
require "open3"
require "optparse"
require "tmpdir"

module RenameCheck
  B = "(?<![A-Za-z0-9])" # left boundary: `gems/phlex-shadcn`, `data-shadcn--x`, `"shadcn__x` all match; `chadcn--` never does
  Row = Struct.new(:stage, :old, :new, :pattern, :ruby_only, :sample, keyword_init: true)

  row = ->(stage, old, new, pattern: nil, ruby_only: false, sample: old) do
    Row.new(stage:, old:, new:, pattern: pattern || /#{B}#{Regexp.escape(old)}/, ruby_only:, sample:)
  end

  MAPPING = [
    row.call(:ruby, "doncan-orozco/phlex-shadcn", "doncan-orozco/chadcn"),
    row.call(:ruby, "gems/phlex-shadcn", "gems/chadcn"),
    row.call(:ruby, "app/assets/tailwind/phlex-shadcn", "app/assets/tailwind/chadcn"),
    row.call(:ruby, "skills/phlex-shadcn", "skills/chadcn"),
    row.call(:ruby, "phlex-shadcn.gemspec", "chadcn.gemspec"),
    row.call(:ruby, "phlex-shadcn.yml", "chadcn.yml"),
    row.call(:ruby, "phlex-shadcn:start", "chadcn:start"),
    row.call(:ruby, "phlex-shadcn:end", "chadcn:end"),
    row.call(:ruby, "phlex-shadcn", "chadcn"),
    row.call(:ruby, "lib/generators/phlex/shadcn", "lib/generators/chadcn"),
    row.call(:ruby, "lib/phlex/shadcn", "lib/chadcn"),
    row.call(:ruby, "test/phlex/shadcn", "test/chadcn"),
    row.call(:ruby, "phlex/shadcn", "chadcn"),
    row.call(:ruby, "phlex:shadcn:install", "chadcn:install"),
    row.call(:ruby, "phlex:shadcn:eject", "chadcn:eject"),
    row.call(:ruby, "phlex:shadcn", "chadcn"),
    row.call(:ruby, "gem_phlex_shadcn", "gem_chadcn"),
    row.call(:ruby, "config.phlex_shadcn", "config.chadcn"),
    row.call(:ruby, "phlex_shadcn:", "chadcn:", sample: "phlex_shadcn:doctor"),
    row.call(:ruby, "phlex_shadcn", "chadcn"),
    row.call(:ruby, "PHLEX_SHADCN_", "CHADCN_"),
    row.call(:ruby, "PHLEX_SHADCN", "CHADCN"),
    row.call(:ruby, "Phlex::Shadcn", "Chadcn"),
    row.call(:ruby, "PhlexShadcn", "Chadcn"),
    row.call(:ruby, "module Shadcn", "module Chadcn (top level)", pattern: /\bmodule\s+Shadcn\b/),
    row.call(:ruby, "Shadcn::", "Chadcn::", pattern: /(?<![\w:])Shadcn::/, sample: "Shadcn::Theme"),
    row.call(:ruby, "Shadcn.", "Chadcn.", pattern: /(?<![\w:])Shadcn\.(?=[a-z_])/, ruby_only: true, sample: "Shadcn.config"),
    row.call(:ruby, "for_gem_extension(Phlex)", "for_gem", pattern: /for_gem_extension\(\s*Phlex\s*\)/),
    row.call(:stimulus, "shadcn---probe-", "chadcn---probe-"),
    row.call(:stimulus, "shadcn--", "chadcn--"),
    row.call(:stimulus, "shadcn__", "chadcn__"),
    row.call(:stimulus, "app/javascript/controllers/shadcn", "app/javascript/controllers/chadcn", pattern: %r{#{B}app/javascript/controllers/shadcn(?![\w-])}),
    row.call(:stimulus, "controllers/shadcn", "controllers/chadcn", pattern: %r{#{B}controllers/shadcn(?![\w-])}),
    row.call(:stimulus, "app/javascript/shadcn", "app/javascript/chadcn", pattern: %r{#{B}app/javascript/shadcn(?![\w-])}),
    row.call(:stimulus, "javascript/shadcn", "javascript/chadcn", pattern: %r{#{B}javascript/shadcn(?![\w-])}),
    row.call(:stimulus, "shadcn/primitives", "chadcn/primitives", pattern: %r{(?<![\w./-])shadcn/primitives\b}),
    row.call(:stimulus, 'under: "shadcn"', 'under: "chadcn"')
  ].freeze
  STAGES = MAPPING.map(&:stage).uniq.freeze

  # Upstream shadcn/ui and the port tooling that names it: never renamed (epic body, "What does NOT rename").
  UPSTREAM = [
    %r{(?<![\w/.-])shadcn/ui\b}, /ui\.shadcn\.com/, /react-shadcn-catalog/, %r{\.claude/scripts/shadcn/},
    %r{/shadcn-(?:plan|run|audit|golden)\b}, /shadcn-port/, /radix-stimulus/
  ].freeze
  # Closed epics keep their slugs (labels `epic:<slug>`, branches `epic/<slug>/...`, notes "item #N (<slug>)").
  HISTORY = [
    /phlex-shadcn-(?:adoption-followups|adoption|hardening)(?![\w-])/,
    %r{(?:epic[:/ ]|--epic )phlex-shadcn(?![\w-])}, /phlex-shadcn epic\b/
  ].freeze
  MASKS = (UPSTREAM + HISTORY).freeze
  ALLOWED_PATHS = Regexp.union(%r{\Adocs/features/chadcn-rebrand/}, %r{\A\.claude/scripts/gem/rename_check\.rb\z}, %r{\Atest/lib/gem/rename_check_test\.rb\z}).freeze
  CHANGELOG = %r{(?:\A|/)CHANGELOG[^/]*\z}i
  RENAME_RECORD = /renam.*chadcn|chadcn.*renam/i
  RUBY_FILE = %r{(?:\.(?:rb|rake|gemspec|ru)|(?:\A|/)(?:Gemfile|Rakefile))\z}
  SKIPPED = %r{(?:\A|/)node_modules/}
  PREFILTER = /shadcn|for_gem_extension/i

  module_function

  def rows(stage) = stage == :all ? MAPPING : MAPPING.select { |r| r.stage == stage }

  def mask(text) = MASKS.reduce(text) { |t, re| t.gsub(re) { |m| "~" * m.size } }

  # Every leftover in one string: [row, ...], one per match, first (most specific) row wins an overlap.
  def matches(text, rows, ruby_file:)
    return [] unless text.match?(PREFILTER)

    masked = mask(text)
    taken = []
    rows.each_with_object([]) do |r, found|
      next if r.ruby_only && !ruby_file

      masked.to_enum(:scan, r.pattern).each do
        span = Regexp.last_match.offset(0)
        next if taken.any? { |a, b| span[0] < b && a < span[1] }

        taken << span
        found << r
      end
    end
  end

  def tracked(dir)
    out, err, status = Open3.capture3("git", "-C", dir, "ls-files", "-z")
    raise ArgumentError, "#{dir}: git ls-files failed: #{err.strip}" unless status.success?

    out.split("\0").reject { |f| f.match?(SKIPPED) }
  end

  def finding(file, line, r, text = nil) = { file:, line:, old: r.old, new: r.new, stage: r.stage, text: text&.strip&.slice(0, 160) }

  # roots: [[label prefix, dir], ...] -> findings
  def scan(roots, stage)
    selected = rows(stage)
    roots.flat_map do |prefix, dir|
      tracked(dir).flat_map do |rel|
        next [] if rel.match?(ALLOWED_PATHS)

        name = "#{prefix}#{rel}"
        ruby_file = rel.match?(RUBY_FILE)
        found = matches(rel, selected, ruby_file: false).map { |r| finding(name, nil, r, "path") }
        path = File.join(dir, rel)
        next found unless File.file?(path)

        found + scan_content(name, File.binread(path), selected, ruby_file:, changelog: rel.match?(CHANGELOG))
      end
    end
  end

  def scan_content(name, bytes, selected, ruby_file:, changelog:)
    if bytes.include?("\0")
      hit = matches(bytes.b.scrub, selected, ruby_file:).first
      return hit ? [ finding(name, nil, hit, "binary file") ] : []
    end

    bytes.force_encoding(Encoding::UTF_8).scrub.each_line.with_index(1).flat_map do |line, n|
      next [] if changelog && line.match?(RENAME_RECORD)

      matches(line, selected, ruby_file:).map { |r| finding(name, n, r, line) }
    end
  end

  # The `papyro_studio` sibling of the checkout, or of the main checkout when this is a worktree.
  def default_engine(root)
    common, _, status = Open3.capture3("git", "-C", root, "rev-parse", "--path-format=absolute", "--git-common-dir")
    bases = [ root ]
    bases << File.dirname(common.strip) if status.success?
    bases.map { |b| File.expand_path("../papyro_studio", b) }.find { |d| Dir.exist?(d) }
  end

  # Seeds a repo with only allowed names (must pass) and one sample per row (each must be reported under its own row).
  def self_test(stage)
    failures = []
    Dir.mktmpdir("rename-check-self-test") do |dir|
      clean = File.join(dir, "clean")
      seeded = File.join(dir, "seeded")
      write_repo(clean, "docs/credits.md" => <<~MD, "CHANGELOG.md" => "- Renamed phlex-shadcn to chadcn (Phlex::Shadcn is now Chadcn).\n")
        Ported from shadcn/ui (https://ui.shadcn.com); oracle gems/chadcn/dev/react-shadcn-catalog; tooling .claude/scripts/shadcn/layout.rb.
        Commands /shadcn-plan /shadcn-run /shadcn-audit /shadcn-golden; skills shadcn-port and radix-stimulus; controllers chadcn--dialog.
        History: epic phlex-shadcn-adoption, label epic:phlex-shadcn-hardening, branch epic/phlex-shadcn/107-publish, the phlex-shadcn epic.
      MD
      leftovers = scan([ [ "", clean ] ], stage)
      failures << "allowed names reported: #{leftovers.map { |f| "#{f[:file]}:#{f[:line]} #{f[:old]}" }.join(', ')}" if leftovers.any?

      selected = rows(stage)
      write_repo(seeded, "lib/seeded.rb" => selected.map { |r| "x = #{r.sample}\n" }.join)
      found = scan([ [ "", seeded ] ], stage).group_by { |f| f[:line] }
      selected.each.with_index(1) do |r, n|
        olds = (found[n] || []).map { |f| f[:old] }
        failures << "row #{r.old.inspect}: sample #{r.sample.inspect} reported as #{olds.inspect}" unless olds == [ r.old ]
      end
    end
    failures
  end

  def write_repo(dir, files)
    files.each do |rel, content|
      path = File.join(dir, rel)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end
    system("git", "init", "-q", dir, exception: true)
    system("git", "-C", dir, "add", "-A", exception: true)
  end
end

if $PROGRAM_NAME == __FILE__
  opts = { stage: nil, root: File.expand_path("../../..", __dir__), engine: nil, format: "text" }
  begin
    OptionParser.new do |o|
      o.on("--stage STAGE", %w[ruby stimulus all]) { |v| opts[:stage] = v.to_sym }
      o.on("--root DIR") { |v| opts[:root] = File.expand_path(v) }
      o.on("--engine-dir DIR") { |v| opts[:engine] = v }
      o.on("--format FORMAT", %w[text json]) { |v| opts[:format] = v }
      o.on("--self-test") { opts[:self_test] = true }
      o.on("--mapping") { opts[:mapping] = true }
    end.parse!
  rescue OptionParser::ParseError => e
    warn "rename_check: #{e.message}"
    exit 2
  end

  if opts[:mapping]
    puts JSON.pretty_generate(RenameCheck::MAPPING.map { |r| { stage: r.stage, old: r.old, new: r.new, pattern: r.pattern.source, ruby_only: r.ruby_only } })
    exit 0
  end
  unless opts[:stage]
    warn "rename_check: --stage ruby|stimulus|all is required"
    exit 2
  end

  if opts[:self_test]
    failures = RenameCheck.self_test(opts[:stage])
    failures.each { |f| warn "self-test: #{f}" }
    puts "rename_check self-test (#{opts[:stage]}): #{failures.empty? ? 'ok' : "#{failures.size} failure(s)"}, #{RenameCheck.rows(opts[:stage]).size} rows"
    exit(failures.empty? ? 0 : 1)
  end

  engine = case opts[:engine]
  when "none" then nil
  when nil then RenameCheck.default_engine(opts[:root])
  else File.expand_path(opts[:engine])
  end
  warn "rename_check: papyro_studio not found next to #{opts[:root]}; engine not scanned" if engine.nil? && opts[:engine].nil?
  if engine && !Dir.exist?(engine)
    warn "rename_check: --engine-dir #{engine} does not exist"
    exit 2
  end

  roots = [ [ "", opts[:root] ] ]
  roots << [ "#{File.basename(engine)}/", engine ] if engine
  begin
    findings = RenameCheck.scan(roots, opts[:stage])
  rescue ArgumentError => e
    warn "rename_check: #{e.message}"
    exit 2
  end

  if opts[:format] == "json"
    puts JSON.pretty_generate(stage: opts[:stage], roots: roots.map(&:last), pass: findings.empty?, count: findings.size, findings:)
  else
    findings.each { |f| puts "#{f[:file]}:#{f[:line] || '-'}: #{f[:old]} -> #{f[:new]}#{"  (#{f[:text]})" if f[:line].nil?}" }
    puts "rename_check (#{opts[:stage]}): #{findings.empty? ? 'clean' : "#{findings.size} leftover(s) in #{findings.map { |f| f[:file] }.uniq.size} file(s)"}"
  end
  exit(findings.empty? ? 0 : 1)
end
