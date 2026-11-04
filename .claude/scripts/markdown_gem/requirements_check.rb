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
# docs, bad flags). Fenced code blocks and inline code spans are never read as headings, placeholders, URLs or
# Acceptance clauses; a span that wraps onto the next line is followed inside a requirement only, so keep other
# spans on one line. A traceability row traces the requirement ID in its first cell only.

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

  FENCE = /\A {0,3}(`{3,}|~{3,})/
  SECTION_HEADING = /\A##\s+\S/
  ANY_HEADING = /\A {0,3}\#{1,6}(?:\s|\z)/
  LIST_ITEM = /\A(?:[-*+]|\d+[.)])\s+/
  REQUIREMENT = /\A(?:[-*+]|\d+[.)])\s+\*\*(?<id>(?<area>[A-Z]+)-\d{2,})\*\*\s+\((?:MUST|SHOULD|COULD)\)\s+\S/
  ACCEPTANCE = /\bAcceptance:\s*\S/
  TRACED_ID = /\A[A-Z]+-\d{2,}\z/
  WORD_PLACEHOLDER = /\b(?:TODO|TBD)\b/
  ANGLE_SPAN = /<[^<>\n]+>/
  # A lowercase HTML tag with quoted attributes (`<kbd>`, `</kbd>`, `<br/>`, `<a href="...">`) is markup, not a marker.
  HTML_TAG = %r{\A</?[a-z][a-z0-9-]*(?:\s+[a-z][\w:-]*=(?:"[^"]*"|'[^']*'))*\s*/?>\z}
  # `<https://...>` and `<name@host>` are autolinks; `<%`, `<!--`, `<?` and `<=` never open a template marker.
  NOT_A_MARKER = %r{\A<(?:(?:[a-z][a-z0-9+.-]+:[^\s<>]*|[^\s@<>]+@[^\s@<>]+)>\z|[\s%!?=/-])}i
  URL = %r{https?://[^\s<>()\[\]`"']+}
  # A code span may wrap onto the next line of its paragraph (CommonMark 6.1).
  CODE_SPAN = /(`+).*?\1/m

  Finding = Data.define(:file, :line, :message) do
    def to_s = "#{file}:#{line}: #{message}"
  end

  # One numbered line of a markdown file; `fenced` lines open, close or sit inside a fenced code block.
  Line = Data.define(:number, :text, :fenced) do
    # The line with inline code spans removed; nil inside fenced code.
    def prose = fenced ? nil : text.gsub(CODE_SPAN, "")

    def blank? = text.strip.empty?

    def heading? = !fenced && text.match?(ANY_HEADING)

    def section_heading? = !fenced && text.match?(SECTION_HEADING)
  end

  class Error < StandardError; end

  # A markdown file split into numbered lines (fenced code flagged) and H2 sections.
  class Document
    Section = Data.define(:title, :line, :lines)

    attr_reader :path, :lines

    def initialize(path, text)
      @path = path
      @lines = number_lines(text).freeze
    end

    def self.read(path)
      raise Error, "no such file: #{path}" unless File.file?(path)

      new(path, File.read(path, encoding: Encoding::UTF_8).scrub)
    end

    def sections
      @sections ||= section_headings.each_with_index.map do |heading, index|
        section_end = section_headings[index + 1]&.number || (lines.size + 1)
        Section.new(title: heading.text.sub(/\A##\s+/, "").strip, line: heading.number,
                    lines: lines[heading.number...(section_end - 1)])
      end
    end

    def section(title) = sections.find { |candidate| candidate.title == title }

    def first_section_line = section_headings.first&.number || 1

    # Where a missing required section belongs: the first H2 after the closest present section that precedes it in
    # `order`, else that section's own heading, else the first H2, else line 1.
    def expected_line(title, order)
      previous_title = order.take(order.index(title)).reverse_each.find { |preceding| section(preceding) }
      return first_section_line unless previous_title

      previous_line = section(previous_title).line
      section_headings.find { |heading| heading.number > previous_line }&.number || previous_line
    end

    private

    def section_headings = @section_headings ||= lines.select(&:section_heading?)

    def number_lines(text)
      open_fence = nil
      text.each_line.with_index(1).map do |raw, number|
        content = raw.chomp
        if open_fence
          open_fence = nil if closes?(content, open_fence)
          Line.new(number:, text: content, fenced: true)
        else
          open_fence = content[FENCE, 1]
          Line.new(number:, text: content, fenced: !open_fence.nil?)
        end
      end
    end

    # A closing fence repeats the opening character at least as often and carries no info string (CommonMark 4.5).
    def closes?(content, open_fence)
      content.match?(/\A {0,3}#{Regexp.escape(open_fence[0])}{#{open_fence.size},}[ \t]*\z/)
    end
  end

  # One requirement of a Requirements section: a top-level list item and the lines that continue it.
  Requirement = Data.define(:line, :last_line, :text) do
    def self.listed_in(section)
      section.lines.each_with_object([]) do |line, requirements|
        if line.prose&.match?(LIST_ITEM)
          requirements << new(line: line.number, last_line: line.number, text: line.text)
        elsif requirements.last&.continued_by?(line)
          requirements[-1] = requirements.last.continued_with(line)
        end
      end
    end

    # [id, line] of every well-formed requirement of the doc, whatever its area.
    def self.definitions(document)
      section = document.section("Requirements")
      return [] unless section

      listed_in(section).filter_map { |requirement| requirement.id && [ requirement.id, requirement.line ] }
    end

    def id = opening&.[](:id)

    def area = opening&.[](:area)

    def acceptance_clause? = prose.match?(ACCEPTANCE)

    # A non-blank, non-heading line right under the requirement continues it; a blank line or a heading ends it.
    def continued_by?(line) = line.number == last_line + 1 && !line.blank? && !line.heading?

    # Fenced lines keep the requirement going but add no text, so code never supplies its Acceptance clause.
    def continued_with(line) = with(last_line: line.number, text: "#{text}\n#{line.fenced ? '' : line.text}")

    private

    # The requirement without its code spans, a span wrapped across its lines included.
    def prose = text.gsub(CODE_SPAN, "")

    def opening = REQUIREMENT.match(prose)
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

    def requirement_count = requirements.count(&:id)

    def source_count = urls.size

    private

    def finding(line, message) = Finding.new(file: @document.path, line:, message:)

    def missing_sections
      SECTIONS.reject { |title| @document.section(title) }
        .map { |title| finding(@document.expected_line(title, SECTIONS), %(missing required section "## #{title}")) }
    end

    def placeholders
      @document.lines.flat_map do |line|
        prose = line.prose
        next [] unless prose

        markers(prose).map { |marker| finding(line.number, %(placeholder "#{marker}")) }
      end
    end

    def markers(prose)
      word_markers = occurrences(prose, WORD_PLACEHOLDER)
      template_markers = occurrences(prose, ANGLE_SPAN)
        .reject { |_offset, span| span.match?(HTML_TAG) || span.match?(NOT_A_MARKER) }
      (word_markers + template_markers).sort.map { |_offset, marker| abbreviate(marker) }
    end

    # [offset, text] of every match, so markers on one line keep the order they appear in.
    def occurrences(prose, pattern)
      prose.to_enum(:scan, pattern).map { [ Regexp.last_match.begin(0), Regexp.last_match[0] ] }
    end

    def abbreviate(marker) = marker.length > MARKER_ECHO ? "#{marker[0, MARKER_ECHO - 4]}...>" : marker

    def requirements_section = @document.section("Requirements")

    def requirements = @requirements ||= requirements_section ? Requirement.listed_in(requirements_section) : []

    def requirement_findings
      return [] unless requirements_section
      return [ finding(requirements_section.line, "Requirements lists no requirement") ] if requirements.empty?

      first_lines = {}
      requirements.filter_map do |requirement|
        message = requirement_message(requirement, first_lines[requirement.id])
        first_lines[requirement.id] ||= requirement.line if requirement.area == @area
        message && finding(requirement.line, message)
      end
    end

    def requirement_message(requirement, first_line)
      if requirement.id.nil?
        %(requirement does not open with "**#{@area}-NN** (MUST|SHOULD|COULD)")
      elsif requirement.area != @area
        "requirement #{requirement.id} belongs to area #{requirement.area}, this doc is #{@area}"
      elsif first_line
        "requirement #{requirement.id} repeats (first at line #{first_line})"
      elsif !requirement.acceptance_clause?
        %(requirement #{requirement.id} has no "Acceptance:" clause)
      end
    end

    def source_findings
      section = @document.section("Sources")
      return [] if section.nil? || urls.size >= @min_sources

      [ finding(section.line, "Sources lists #{urls.size} distinct URLs, at least #{@min_sources} required") ]
    end

    def urls
      @urls ||= (@document.section("Sources")&.lines || []).flat_map do |line|
        line.prose.to_s.scan(URL).map { |url| normalize_url(url) }
      end.uniq
    end

    # Trailing sentence punctuation and a trailing slash do not make a new source.
    def normalize_url(url) = url.sub(/[.,;:!?]+\z/, "").delete_suffix("/")
  end

  # The synthesis: every requirement ID defined in the research docs has a row in its Traceability table.
  class SynthesisCheck
    def initialize(synthesis, research_docs)
      @synthesis = synthesis
      @research_docs = research_docs
    end

    def findings
      section = @synthesis.section(TRACEABILITY)
      return [ finding(@synthesis.first_section_line, %(missing required section "## #{TRACEABILITY}")) ] unless section

      traced = traced_ids(section)
      definitions.reject { |id, _doc, _line| traced.include?(id) }.map do |id, doc, line|
        finding(section.line, "#{id} missing from the traceability table (defined at #{doc.path}:#{line})")
      end
    end

    def requirement_count = definitions.size

    private

    def finding(line, message) = Finding.new(file: @synthesis.path, line:, message:)

    def definitions
      @definitions ||= @research_docs.flat_map do |doc|
        Requirement.definitions(doc).map { |id, line| [ id, doc, line ] }
      end
    end

    def traced_ids(section) = section.lines.filter_map { |line| traced_id(line) }.to_set

    # The first cell of a table row when it holds a requirement ID (backticks and bold allowed); IDs in other cells
    # ("merged with DX-02") do not trace.
    def traced_id(line)
      return if line.fenced || !line.text.lstrip.start_with?("|")

      cell = line.text.lstrip.delete_prefix("|").split("|", 2).first.to_s.delete("`*").strip
      cell if cell.match?(TRACED_ID)
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
      --synthesis FILE DIR  check that FILE's Traceability table has a row for every requirement ID of DIR/*.md
                            (#{KIT_FILES.join(' and ')} are not research docs)

      Exit 0 pass, 1 findings (file:line: message), 2 bad input.
    TEXT

    def initialize(out: $stdout, err: $stderr)
      @out = out
      @err = err
    end

    def run(argv)
      options, operands = parse(argv)
      return help if options[:help]

      options[:synthesis] ? check_synthesis(operands) : check_area(options, operands)
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
      operands = OptionParser.new do |parser|
        parser.on("--area CODE") { |code| options[:area] = code }
        parser.on("--synthesis") { options[:synthesis] = true }
        parser.on("--min-sources N", Integer) { |minimum| options[:min_sources] = minimum }
        parser.on("-h", "--help") { options[:help] = true }
      end.parse(argv)
      validate(options)
      [ options, operands ]
    end

    def validate(options)
      return if options[:help]
      raise Error, "give --area CODE FILE or --synthesis FILE DIR" unless options.key?(:area) ^ options.key?(:synthesis)
      raise Error, "--min-sources must be at least 1" if options[:min_sources] < 1
      return if options[:synthesis] || AREAS.key?(options[:area])

      raise Error, %(unknown area "#{options[:area]}"; known: #{AREAS.keys.join(', ')})
    end

    def check_area(options, operands)
      raise Error, "--area takes one FILE" unless operands.size == 1

      file = operands.first
      check = AreaCheck.new(Document.read(file), area: options[:area], min_sources: options[:min_sources])
      report(check.findings) do
        "#{file} (area #{options[:area]}, #{check.requirement_count} requirements, #{check.source_count} sources)"
      end
    end

    def check_synthesis(operands)
      raise Error, "--synthesis takes FILE DIR" unless operands.size == 2

      file, dir = operands
      docs = research_docs(dir)
      check = SynthesisCheck.new(Document.read(file), docs)
      report(check.findings) { "#{file} (#{check.requirement_count} requirement IDs from #{docs.size} docs traced)" }
    end

    def research_docs(dir)
      raise Error, "no such directory: #{dir}" unless File.directory?(dir)

      doc_names = Dir.children(dir).select { |name| name.end_with?(".md") && !KIT_FILES.include?(name) }.sort
      raise Error, "no research docs in #{dir}" if doc_names.empty?

      doc_names.map { |name| Document.read(File.join(dir, name)) }
    end

    def report(findings)
      findings.each { |finding| @out.puts(finding) }
      return FOUND if findings.any?

      @out.puts("requirements_check: ok: #{yield}")
      PASS
    end
  end
end

exit MarkdownGemRequirements::CLI.new.run(ARGV) if $PROGRAM_NAME == __FILE__
