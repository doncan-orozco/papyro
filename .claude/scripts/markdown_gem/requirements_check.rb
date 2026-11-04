#!/usr/bin/env ruby
# frozen_string_literal: true

# The judge of the markdown gem research: every area doc under docs/features/markdown-editor/requirements/ and the
# synthesis in docs/features/markdown-editor/REQUIREMENTS.md gate on it. The format it enforces is documented in
# docs/features/markdown-editor/requirements/README.md.
#
#   requirements_check.rb --area CODE FILE [--min-sources N]   # one research doc of area CODE
#   requirements_check.rb --synthesis FILE DIR                 # every requirement ID of DIR/*.md traced in FILE
#
# Findings print as file:line: message; exit 0 pass, 1 findings, 2 bad input (unknown area, missing file, no research
# docs, bad flags). Fenced code blocks and inline code spans are never read as headings, placeholders or URLs.

require "optparse"

module MarkdownGemRequirements
  AREAS = {
    "DX" => "developer-experience.md",
    "RAILS" => "rails-framework-integration.md",
    "ASSETS" => "asset-pipeline-integration.md",
    "VIEWS" => "view-and-form-integration.md",
    "THEME" => "theming-and-customization.md",
    "EDIT" => "editor-ux.md",
    "RENDER" => "render-and-viewer.md",
    "AGENT" => "agent-layer.md",
    "PRIOR" => "prior-art-teardown.md",
    "PAPYRO" => "papyro-as-consumer.md"
  }.freeze
  SECTIONS = [ "Scope", "Questions", "Findings", "Requirements", "Developer experience notes", "Open decisions",
               "Sources" ].freeze
  TRACEABILITY = "Traceability"
  # Files of the requirements directory that are not research docs.
  KIT_FILES = %w[README.md TEMPLATE.md].freeze
  DEFAULT_MIN_SOURCES = 5
  # Longest template marker echoed in full; longer ones are cut so a finding stays one readable line.
  MARKER_ECHO = 60
  PASS = 0
  FOUND = 1
  BAD_INPUT = 2

  LIST_ITEM = /\A(?:[-*+]|\d+[.)])\s+/
  REQUIREMENT = /\A(?:[-*+]|\d+[.)])\s+\*\*(?<id>(?<code>[A-Z]+)-\d{2,})\*\*\s+\((?:MUST|SHOULD|COULD)\)\s+\S/
  ACCEPTANCE = /\bAcceptance:\s*\S/
  REQUIREMENT_ID = /\b[A-Z]+-\d{2,}\b/
  WORD_PLACEHOLDER = /\b(?:TODO|TBD)\b/
  ANGLE_SPAN = /<[^<>\n]+>/
  # A lowercase HTML tag with quoted attributes (`<kbd>`, `</kbd>`, `<br/>`, `<a href="...">`) is markup, not a marker.
  HTML_TAG = %r{\A</?[a-z][a-z0-9-]*(?:\s+[a-z][\w:-]*=(?:"[^"]*"|'[^']*'))*\s*/?>\z}
  # `<https://...>` and `<name@host>` are autolinks; `<%`, `<!--`, `<?` and `<=` never open a template marker.
  NOT_A_MARKER = %r{\A<(?:(?:[a-z][a-z0-9+.-]+:[^\s<>]*|[^\s@<>]+@[^\s@<>]+)>\z|[\s%!?=/-])}i
  URL = %r{https?://[^\s<>()\[\]`"']+}
  CODE_SPAN = /(`+).*?\1/

  Finding = Data.define(:file, :line, :message) do
    def to_s = "#{file}:#{line}: #{message}"
  end

  Line = Data.define(:number, :text, :code)

  class Error < StandardError; end

  # A markdown file split into numbered lines (fenced code flagged) and H2 sections.
  class Document
    Section = Data.define(:title, :line, :lines)

    attr_reader :path, :lines

    def initialize(path, text)
      @path = path
      @lines = number_lines(text)
    end

    def self.read(path)
      raise Error, "no such file: #{path}" unless File.file?(path)

      new(path, File.read(path, encoding: Encoding::UTF_8).scrub)
    end

    def sections
      @sections ||= headings.each_with_index.map do |heading, index|
        last = headings[index + 1]&.number || (lines.size + 1)
        Section.new(title: heading.text.sub(/\A##\s+/, "").strip, line: heading.number,
                    lines: lines.select { (heading.number + 1...last).cover?(it.number) })
      end
    end

    def section(title) = sections.find { it.title == title }

    # Where a missing required section belongs: the first H2 after the closest present section that precedes it in
    # `order`, else that section's own heading, else the first H2, else line 1.
    def expected_line(title, order)
      previous = order.take(order.index(title)).reverse.filter_map { section(it) }.first
      return headings.first&.number || 1 unless previous

      headings.find { it.number > previous.line }&.number || previous.line
    end

    # Prose of a line with inline code spans removed; nil inside fenced code.
    def self.prose(line) = line.code ? nil : line.text.gsub(CODE_SPAN, "")

    private

    def headings = @headings ||= lines.select { !it.code && it.text.match?(/\A##\s+\S/) }

    def number_lines(text)
      fence = nil
      text.each_line.with_index(1).map do |raw, number|
        content = raw.chomp
        marker = content[/\A {0,3}(`{3,}|~{3,})/, 1]
        if fence.nil? && marker
          fence = marker
          next Line.new(number:, text: content, code: true)
        end
        if fence && marker&.start_with?(fence)
          fence = nil
          next Line.new(number:, text: content, code: true)
        end
        Line.new(number:, text: content, code: !fence.nil?)
      end
    end
  end

  # The requirement items of a Requirements section: each top-level list item with its continuation lines.
  module Requirements
    Item = Data.define(:line, :text) do
      def match = REQUIREMENT.match(text)
    end

    def self.items(section)
      section.lines.each_with_object([]) do |line, items|
        prose = Document.prose(line)
        if prose&.match?(LIST_ITEM)
          items << Item.new(line: line.number, text: prose)
        elsif items.any? && continuation?(line, items.last)
          items[-1] = items.last.with(text: "#{items.last.text}\n#{line.text}")
        end
      end
    end

    # A continuation is any non-blank, non-heading line directly under the item (blank lines end it).
    def self.continuation?(line, item)
      return false if line.text.strip.empty? || line.text.start_with?("#")

      item.line + item.text.count("\n") + 1 == line.number
    end

    def self.definitions(document)
      section = document.section("Requirements")
      return [] unless section

      items(section).filter_map { |item| item.match && [ item.match[:id], item.line ] }
    end
  end

  # One research doc of one area: sections, placeholders, requirement lines, IDs and sources.
  class AreaCheck
    def initialize(document, area:, min_sources:)
      @document = document
      @area = area
      @min_sources = min_sources
    end

    # Ordered by line; findings on one line keep the order the checks produce them in (sort_by alone is not stable).
    def findings
      (missing_sections + placeholders + requirement_findings + source_findings)
        .each_with_index.sort_by { |finding, index| [ finding.line, index ] }.map(&:first)
    end

    def requirement_count = definitions.size

    def source_count = urls.size

    private

    def finding(line, message) = Finding.new(file: @document.path, line:, message:)

    def missing_sections
      SECTIONS.reject { @document.section(it) }
        .map { finding(@document.expected_line(it, SECTIONS), %(missing required section "## #{it}")) }
    end

    def placeholders
      @document.lines.flat_map do |line|
        prose = Document.prose(line)
        next [] unless prose

        markers(prose).map { finding(line.number, %(placeholder "#{it}")) }
      end
    end

    def markers(prose)
      words = prose.to_enum(:scan, WORD_PLACEHOLDER).map { [ Regexp.last_match.begin(0), Regexp.last_match[0] ] }
      spans = prose.to_enum(:scan, ANGLE_SPAN).map { [ Regexp.last_match.begin(0), Regexp.last_match[0] ] }
        .reject { |_offset, span| span.match?(HTML_TAG) || span.match?(NOT_A_MARKER) }
      (words + spans).sort.map { |_offset, marker| abbreviate(marker) }
    end

    def abbreviate(marker) = marker.length > MARKER_ECHO ? "#{marker[0, MARKER_ECHO - 4]}...>" : marker

    def requirement_findings
      section = @document.section("Requirements")
      return [] unless section

      items = Requirements.items(section)
      return [ finding(section.line, "Requirements lists no requirement") ] if items.empty?

      first_lines = {}
      items.filter_map { |item| item_finding(item, first_lines) }
    end

    def item_finding(item, first_lines)
      match = item.match
      return finding(item.line, %(requirement does not open with "**#{@area}-NN** (MUST|SHOULD|COULD)")) unless match

      id = match[:id]
      if match[:code] != @area
        finding(item.line, "requirement #{id} belongs to area #{match[:code]}, this doc is #{@area}")
      elsif first_lines.key?(id)
        finding(item.line, "requirement #{id} repeats (first at line #{first_lines[id]})")
      elsif !item.text.match?(ACCEPTANCE)
        first_lines[id] = item.line
        finding(item.line, %(requirement #{id} has no "Acceptance:" clause))
      else
        first_lines[id] = item.line
        nil
      end
    end

    def definitions = @definitions ||= Requirements.definitions(@document)

    def source_findings
      section = @document.section("Sources")
      return [] if section.nil? || urls.size >= @min_sources

      [ finding(section.line, "Sources lists #{urls.size} distinct URLs, at least #{@min_sources} required") ]
    end

    def urls
      @urls ||= (@document.section("Sources")&.lines || []).flat_map do |line|
        Document.prose(line).to_s.scan(URL).map { it.sub(%r{[.,;:!?]+\z}, "").delete_suffix("/") }
      end.uniq
    end
  end

  # The synthesis: every requirement ID defined in the research docs appears in its Traceability table.
  class SynthesisCheck
    def initialize(document, docs)
      @document = document
      @docs = docs
    end

    def findings
      section = @document.section(TRACEABILITY)
      unless section
        return [ Finding.new(file: @document.path, line: @document.expected_line(TRACEABILITY, [ TRACEABILITY ]),
                             message: %(missing required section "## #{TRACEABILITY}")) ]
      end

      traced = traced_ids(section)
      definitions.reject { |id, _doc, _line| traced.include?(id) }.map do |id, doc, line|
        Finding.new(file: @document.path, line: section.line,
                    message: "#{id} missing from the traceability table (defined at #{doc.path}:#{line})")
      end
    end

    def definitions
      @definitions ||= @docs.flat_map { |doc| Requirements.definitions(doc).map { |id, line| [ id, doc, line ] } }
    end

    private

    def traced_ids(section)
      section.lines.filter_map { Document.prose(it) }.select { it.lstrip.start_with?("|") }
        .flat_map { it.scan(REQUIREMENT_ID) }.to_set
    end
  end

  # Command line: parses arguments, runs one check, prints findings and answers with the exit code.
  class CLI
    USAGE = <<~TEXT
      Usage:
        requirements_check.rb --area CODE FILE [--min-sources N]
        requirements_check.rb --synthesis FILE DIR

      --area CODE FILE      check one research doc of area CODE (#{AREAS.keys.join(', ')})
      --min-sources N       distinct URLs the Sources section needs (default #{DEFAULT_MIN_SOURCES})
      --synthesis FILE DIR  check that FILE's Traceability table lists every requirement ID of DIR/*.md
                            (#{KIT_FILES.join(' and ')} are not research docs)

      Exit 0 pass, 1 findings (file:line: message), 2 bad input.
    TEXT

    def initialize(out: $stdout, err: $stderr)
      @out = out
      @err = err
    end

    def run(argv)
      options, args = parse(argv)
      return help if options[:help]

      options[:synthesis] ? synthesis(args) : area(options, args)
    rescue Error, OptionParser::ParseError, SystemCallError => e
      @err.puts("requirements_check: #{e.message}")
      BAD_INPUT
    end

    private

    def help
      @out.puts(USAGE)
      PASS
    end

    def parse(argv)
      options = { min_sources: DEFAULT_MIN_SOURCES }
      args = OptionParser.new do |parser|
        parser.on("--area CODE") { |code| options[:area] = code }
        parser.on("--synthesis") { options[:synthesis] = true }
        parser.on("--min-sources N", Integer) { |count| options[:min_sources] = count }
        parser.on("-h", "--help") { options[:help] = true }
      end.parse(argv)
      validate(options)
      [ options, args ]
    end

    def validate(options)
      return if options[:help]
      raise Error, "give --area CODE FILE or --synthesis FILE DIR" unless options.key?(:area) ^ options.key?(:synthesis)
      raise Error, "--min-sources must be at least 1" if options[:min_sources] < 1
      return if options[:synthesis] || AREAS.key?(options[:area])

      raise Error, %(unknown area "#{options[:area]}"; known: #{AREAS.keys.join(', ')})
    end

    def area(options, args)
      raise Error, "--area takes one FILE" unless args.size == 1

      check = AreaCheck.new(Document.read(args.first), area: options[:area], min_sources: options[:min_sources])
      report(check.findings) do
        "#{args.first} (area #{options[:area]}, #{check.requirement_count} requirements, #{check.source_count} sources)"
      end
    end

    def synthesis(args)
      raise Error, "--synthesis takes FILE DIR" unless args.size == 2

      file, dir = args
      docs = research_docs(dir)
      check = SynthesisCheck.new(Document.read(file), docs)
      report(check.findings) { "#{file} (#{check.definitions.size} requirement IDs from #{docs.size} docs traced)" }
    end

    def research_docs(dir)
      raise Error, "no such directory: #{dir}" unless File.directory?(dir)

      names = Dir.children(dir).select { it.end_with?(".md") && !KIT_FILES.include?(it) }.sort
      raise Error, "no research docs in #{dir}" if names.empty?

      names.map { Document.read(File.join(dir, it)) }
    end

    def report(findings)
      findings.each { @out.puts(it) }
      return FOUND if findings.any?

      @out.puts("requirements_check: ok: #{yield}")
      PASS
    end
  end
end

exit MarkdownGemRequirements::CLI.new.run(ARGV) if $PROGRAM_NAME == __FILE__
