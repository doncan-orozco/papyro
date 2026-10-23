#!/usr/bin/env ruby
# frozen_string_literal: true

# Finds what still uses the legacy UI library (app/components/ui and its ui-- Stimulus controllers), so a script, not a
# reading of the diff, judges "this file no longer uses the legacy UI" during the retire-legacy-ui epic.
#
#   legacy_ui_refs.rb [paths...]            # file:line:match per reference; exit 0 clean, 1 found, 2 bad input
#   legacy_ui_refs.rb --json [paths...]     # { total, files: { path => count }, findings: [...] }
#   legacy_ui_refs.rb --engine DIR          # engine checkout for the no-path scan
#
# Reference kinds: namespace, constant, controller (the double-dash Stimulus identifier, also inside HTML data
# attributes), data_key (its Phlex underscore form) and import (the controllers directory path). See PATTERNS.
#
# With paths it scans only those files and directories (relative to the current directory). Without paths it scans the
# host's app/ lib/ config/ test/ and the papyro_studio engine's, the engine found through --engine, then
# BUNDLE_LOCAL__PAPYRO_STUDIO (environment, then the host's .bundle/config; blank values are ignored), then
# ../papyro_studio. An explicit or configured engine that is missing exits 2; a missing sibling only warns on stderr and
# the host is scanned alone. No-path mode in a directory with none of app/lib/config/test exits 2. The legacy library
# itself (LEGACY_DIRS) is never reported: it is what the epic deletes last.
#
# #297 should run it in CI with: legacy_ui_refs.rb --engine "$(bundle info --path papyro_studio)"

require "json"
require "optparse"
require "yaml"

module LegacyUiRefs
  PATTERNS = {
    "namespace" => /\bComponents::Ui\b/,
    "constant" => /(?<!\w::|\w)(?:::)?Ui::[A-Z]\w*/,
    "controller" => /(?:(?<=data-)|(?<![\w-]))ui--[a-z0-9][\w-]*/,
    "data_key" => /(?<!\w)ui__[a-z]\w*/,
    "import" => %r{\bcontrollers/ui(?:/|\b)}
  }.freeze
  SCAN_DIRS = %w[app lib config test].freeze
  LEGACY_DIRS = [ "app/components/ui", File.join("app/javascript/controllers", "ui"), "test/components/ui" ].freeze
  ENGINE_KEY = "BUNDLE_LOCAL__PAPYRO_STUDIO"
  SIBLING_ENGINE = File.join("..", "papyro_studio")
  CLEAN = 0
  FOUND = 1
  BAD_INPUT = 2

  Finding = Data.define(:file, :line, :kind, :match) do
    def to_s = "#{file}:#{line}:#{match}"
  end

  class Error < StandardError; end

  # Scans the given paths (files or directories, relative to root) and returns findings ordered by path, then line.
  class Scanner
    def initialize(root:)
      @root = File.expand_path(root)
      @root_prefix = File.join(@root, "")
      @legacy_roots = LEGACY_DIRS.map { File.join(@root, it) }
    end

    def scan(paths)
      paths.flat_map { |path| files_under(File.expand_path(path, @root)) }.uniq.flat_map { |file| scan_file(file) }
    end

    private

    def files_under(path)
      return [] if legacy?(path)
      return [ path ] if File.file?(path)

      Dir.glob("**/*", File::FNM_DOTMATCH, base: path).sort
        .map { |relative| File.join(path, relative) }
        .select { |file| File.file?(file) && !legacy?(file) }
    end

    def legacy?(path)
      @legacy_roots.any? { |dir| path == dir || path.start_with?(File.join(dir, "")) }
    end

    def scan_file(file)
      content = File.binread(file)
      return [] if content.include?("\0")

      display = display_path(file)
      content.force_encoding(Encoding::UTF_8).scrub.each_line.with_index(1).flat_map do |text, number|
        PATTERNS.flat_map { |kind, pattern| matches(text, pattern).map { |offset, match| [ offset, kind, match ] } }
          .sort.map { |_offset, kind, match| Finding.new(file: display, line: number, kind: kind, match: match) }
      end
    end

    # [offset, text] of every match, so findings on one line keep the order they appear in.
    def matches(text, pattern)
      text.to_enum(:scan, pattern).map { [ Regexp.last_match.begin(0), Regexp.last_match[0] ] }
    end

    def display_path(file)
      file.delete_prefix(@root_prefix)
    end
  end

  # Command line: parses arguments, picks the paths, prints the report and answers with the exit code.
  class CLI
    def initialize(out: $stdout, err: $stderr, root: Dir.pwd, env: ENV)
      @out = out
      @err = err
      @root = File.expand_path(root)
      @env = env
    end

    def run(argv)
      options, paths = parse(argv)
      findings = Scanner.new(root: @root).scan(paths.empty? ? default_paths(options[:engine]) : require_existing(paths))
      print_report(findings, as_json: options[:as_json])
      findings.empty? ? CLEAN : FOUND
    rescue Error, OptionParser::ParseError, Psych::Exception, SystemCallError => e
      @err.puts("legacy_ui_refs: #{e.message}")
      BAD_INPUT
    end

    private

    def parse(argv)
      options = {}
      paths = OptionParser.new do |parser|
        parser.on("--json") { options[:as_json] = true }
        parser.on("--engine DIR") { |dir| options[:engine] = dir }
      end.parse(argv)
      [ options, paths ]
    end

    def require_existing(paths)
      missing = paths.reject { |path| File.exist?(File.expand_path(path, @root)) }
      raise Error, "no such file or directory: #{missing.join(', ')}" if missing.any?

      paths
    end

    def print_report(findings, as_json:)
      return @out.puts(JSON.pretty_generate(report(findings))) if as_json

      findings.each { |finding| @out.puts(finding) }
    end

    def default_paths(engine_option)
      host = scan_dirs_in(@root)
      raise Error, "#{@root} has none of #{SCAN_DIRS.join(', ')}: run from the host root or pass paths" if host.empty?

      host + engine_scan_dirs(engine_option)
    end

    def engine_scan_dirs(engine_option)
      requested_engine = present_dir(engine_option) || configured_engine
      engine = File.expand_path(requested_engine || SIBLING_ENGINE, @root)
      raise Error, "engine directory resolves to the host root: #{engine}" if engine == @root

      dirs = scan_dirs_in(engine)
      return dirs if dirs.any?
      raise Error, "no engine checkout at #{engine}" if requested_engine

      @err.puts("legacy_ui_refs: warning: no engine checkout at #{engine}; scanned the host only")
      []
    end

    def scan_dirs_in(base)
      SCAN_DIRS.map { File.join(base, it) }.select { File.directory?(it) }
    end

    def configured_engine
      present_dir(@env[ENGINE_KEY]) || present_dir(bundle_config[ENGINE_KEY])
    end

    def present_dir(value)
      value.strip if value.is_a?(String) && !value.strip.empty?
    end

    def bundle_config
      path = File.join(@root, ".bundle", "config")
      config = File.file?(path) ? YAML.safe_load_file(path) : nil
      raise Error, "#{path} is not a YAML mapping" unless config.nil? || config.is_a?(Hash)

      config || {}
    end

    def report(findings)
      {
        total: findings.size,
        files: findings.map(&:file).tally,
        findings: findings.map(&:to_h)
      }
    end
  end
end

exit LegacyUiRefs::CLI.new.run(ARGV) if $PROGRAM_NAME == __FILE__
