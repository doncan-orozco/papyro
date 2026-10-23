#!/usr/bin/env ruby
# frozen_string_literal: true

# Finds what still uses the legacy UI library (app/components/ui and its ui-- Stimulus controllers), so a script, not a
# reading of the diff, judges "this file no longer uses the legacy UI" during the retire-legacy-ui epic.
#
#   legacy_ui_refs.rb [paths...]            # file:line:match per reference; exit 0 clean, 1 found, 2 bad input
#   legacy_ui_refs.rb --json [paths...]     # { total, files: { path => count }, findings: [...] }
#   legacy_ui_refs.rb --engine DIR          # engine checkout for the no-path scan
#
# With paths it scans only those files and directories (relative to the current directory). Without paths it scans the
# host's app/ lib/ config/ test/ and the papyro_studio engine's, the engine found through --engine, then
# BUNDLE_LOCAL__PAPYRO_STUDIO (environment, then the host's .bundle/config), then ../papyro_studio. The legacy library
# itself (LEGACY_DIRS) is never reported: it is what the epic deletes last.

require "json"
require "optparse"
require "yaml"

module LegacyUiRefs
  PATTERNS = {
    "namespace" => /\bComponents::Ui\b/,
    "constant" => /(?<![\w:])Ui::[A-Z]\w*/,
    "controller" => /(?<![\w-])ui--[a-z0-9][\w-]*/,
    "import" => %r{\bcontrollers/ui/}
  }.freeze
  SCAN_DIRS = %w[app lib config test].freeze
  LEGACY_DIRS = %w[app/components/ui app/javascript/controllers/ui test/components/ui].freeze
  ENGINE_KEY = "BUNDLE_LOCAL__PAPYRO_STUDIO"

  Finding = Data.define(:file, :line, :kind, :match) do
    def to_s = "#{file}:#{line}:#{match}"
  end

  class Error < StandardError; end

  # Scans the given paths (files or directories, relative to root) and returns findings ordered by path, then line.
  class Scanner
    def initialize(root:)
      @root = File.expand_path(root)
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
      LEGACY_DIRS.any? { |dir| path == File.join(@root, dir) || path.start_with?(File.join(@root, dir, "")) }
    end

    def scan_file(file)
      content = File.binread(file)
      return [] if content.include?("\0")

      display = display_path(file)
      content.force_encoding(Encoding::UTF_8).scrub.each_line.with_index(1).flat_map do |text, number|
        PATTERNS.flat_map { |kind, pattern| matches(text, pattern).map { |at, match| [ at, kind, match ] } }
          .sort.map { |_at, kind, match| Finding.new(file: display, line: number, kind: kind, match: match) }
      end
    end

    # [offset, text] of every match, so findings on one line keep the order they appear in.
    def matches(text, pattern)
      text.to_enum(:scan, pattern).map { [ Regexp.last_match.begin(0), Regexp.last_match[0] ] }
    end

    def display_path(file)
      file.start_with?(File.join(@root, "")) ? file.delete_prefix(File.join(@root, "")) : file
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
      findings = Scanner.new(root: @root).scan(paths.empty? ? default_paths(options[:engine]) : checked(paths))
      options[:json] ? @out.puts(JSON.pretty_generate(report(findings))) : findings.each { |finding| @out.puts(finding) }
      findings.empty? ? 0 : 1
    rescue Error, OptionParser::ParseError => e
      @err.puts("legacy_ui_refs: #{e.message}")
      2
    end

    private

    def parse(argv)
      options = {}
      paths = OptionParser.new do |parser|
        parser.on("--json") { options[:json] = true }
        parser.on("--engine DIR") { |dir| options[:engine] = dir }
      end.parse(argv)
      [ options, paths ]
    end

    def checked(paths)
      missing = paths.reject { |path| File.exist?(File.expand_path(path, @root)) }
      raise Error, "no such file or directory: #{missing.join(', ')}" if missing.any?

      paths
    end

    def default_paths(engine)
      engine = File.expand_path(engine || engine_dir, @root)
      [ @root, engine ].product(SCAN_DIRS).map { |base, dir| File.join(base, dir) }.select { |dir| File.directory?(dir) }
    end

    def engine_dir
      @env[ENGINE_KEY] || bundle_config[ENGINE_KEY] || File.join(@root, "..", "papyro_studio")
    end

    def bundle_config
      path = File.join(@root, ".bundle", "config")
      File.file?(path) ? YAML.safe_load_file(path) || {} : {}
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
