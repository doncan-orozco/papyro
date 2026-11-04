require "test_helper"
require "tmpdir"
require "open3"
require "rbconfig"
require "stringio"
require Rails.root.join(".claude/scripts/markdown_gem/requirements_check").to_s

# The judge every markdown gem research item gates on. Failure cases are the passing fixture with one thing broken,
# written to a tmp dir so the line numbers in the messages are easy to predict.
class RequirementsCheckTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join(".claude/scripts/markdown_gem/requirements_check.rb").to_s
  FIXTURE = Rails.root.join("test/lib/markdown_gem/fixtures/passing.md").to_s
  REQUIREMENTS_DIR = Rails.root.join("docs/features/markdown-editor/requirements").to_s
  PASSING = File.read(FIXTURE)

  setup { @dir = Dir.mktmpdir("requirements-check") }
  teardown { FileUtils.remove_entry(@dir) }

  def write(name, content)
    path = File.join(@dir, name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  def run_cli(*argv)
    out = StringIO.new
    err = StringIO.new
    status = MarkdownGemRequirements::CLI.new(out: out, err: err).run(argv)
    [ status, out.string, err.string ]
  end

  def check_area(content, *extra, area: "DX")
    path = write("doc.md", content)
    status, out, err = run_cli("--area", area, path, *extra)
    [ status, out.lines(chomp: true).map { it.delete_prefix("#{path}:") }, err ]
  end

  def line_of(content, text) = content.lines.index { it.include?(text) } + 1

  def broken(from, to)
    assert_includes PASSING, from
    PASSING.sub(from, to)
  end

  test "the passing fixture exits 0 and says what it counted" do
    status, out, err = run_cli("--area", "DX", FIXTURE)

    assert_equal 0, status
    assert_equal "requirements_check: ok: #{FIXTURE} (area DX, 3 requirements, 5 sources)\n", out
    assert_empty err
  end

  test "the template fails on its placeholders, its requirement line and its sources" do
    template = File.join(REQUIREMENTS_DIR, "TEMPLATE.md")
    status, out, = run_cli("--area", "DX", template)

    assert_equal 1, status
    assert_match(/\A#{Regexp.escape(template)}:\d+: placeholder "<[^"]+>"$/, out.lines.first)
    assert_match(/:\d+: requirement does not open with "\*\*DX-NN\*\* \(MUST\|SHOULD\|COULD\)"$/, out)
    assert_match(/:\d+: Sources lists 0 distinct URLs, at least 5 required$/, out)
    assert_includes out, %(placeholder "<One paragraph: what this area covers and why it matters...>")
    assert(out.scan(/placeholder "([^"]+)"/).flatten.all? { it.length <= MarkdownGemRequirements::MARKER_ECHO })
  end

  test "a missing required section is reported by name" do
    content = broken("## Open decisions\n", "## Decisions\n")
    status, out, = check_area(content)

    assert_equal 1, status
    assert_equal [ "#{line_of(content, '## Decisions')}: missing required section \"## Open decisions\"" ], out
  end

  test "every missing section is reported, each once" do
    status, out, = check_area("# Empty\n")

    assert_equal 1, status
    assert_equal MarkdownGemRequirements::SECTIONS.map { "1: missing required section \"## #{it}\"" }, out
  end

  test "TODO and TBD are placeholders, named with their line" do
    content = broken("Each requirement above", "TODO: each requirement above").sub("Recommendation:", "Recommendation: TBD,")
    status, out, = check_area(content)

    assert_equal 1, status
    assert_equal [ "#{line_of(content, 'TODO:')}: placeholder \"TODO\"",
                   "#{line_of(content, 'TBD,')}: placeholder \"TBD\"" ], out
  end

  test "template markers in prose are placeholders; code, HTML tags and autolinks are not" do
    content = broken("How a Rails developer", "<one paragraph: what this area covers> How a Rails developer")
    status, out, = check_area(content)

    assert_equal 1, status
    assert_equal [ "#{line_of(content, '<one paragraph')}: placeholder \"<one paragraph: what this area covers>\"" ], out
  end

  test "an uppercase area marker is a placeholder" do
    status, out, = check_area(broken("# Developer experience", "# <AREA> Developer experience"))

    assert_equal 1, status
    assert_equal [ "1: placeholder \"<AREA>\"" ], out
  end

  test "a requirement without the ID and priority shape is named with its line" do
    content = broken("- **DX-02** (SHOULD)", "- **DX-2** (SHOULD)").sub("1. **DX-03** (COULD)", "1. DX-03 (WONT)")
    status, out, = check_area(content)

    assert_equal 1, status
    shape = 'requirement does not open with "**DX-NN** (MUST|SHOULD|COULD)"'

    assert_equal [ "#{line_of(content, 'DX-2**')}: #{shape}", "#{line_of(content, 'DX-03 (WONT)')}: #{shape}" ], out
  end

  test "a requirement of another area is not this doc's" do
    content = broken("**DX-02**", "**RAILS-02**")
    status, out, = check_area(content)

    assert_equal 1, status
    assert_equal [ "#{line_of(content, 'RAILS-02')}: requirement RAILS-02 belongs to area RAILS, this doc is DX" ], out
  end

  test "a requirement without an Acceptance clause is named with its ID and line" do
    content = broken("Acceptance: every deprecation warning names the new API.", "Every warning names the new API.")
    status, out, = check_area(content)

    assert_equal 1, status
    assert_equal [ "#{line_of(content, 'DX-03')}: requirement DX-03 has no \"Acceptance:\" clause" ], out
  end

  test "an Acceptance clause on a continuation line counts, an empty one does not" do
    assert_equal 0, check_area(broken("Acceptance: a new Rails app", "\n  Acceptance: a new Rails app")).first,
                 "the clause may sit on an indented continuation line"

    content = broken("Acceptance: every deprecation warning names the new API.", "Acceptance:")

    assert_equal [ "#{line_of(content, 'DX-03')}: requirement DX-03 has no \"Acceptance:\" clause" ], check_area(content)[1]
  end

  test "a repeated ID names both lines" do
    content = broken("**DX-03**", "**DX-01**")
    status, out, = check_area(content)

    assert_equal 1, status
    assert_equal [ "#{line_of(content, '1. **DX-01**')}: requirement DX-01 repeats (first at line #{line_of(content, '- **DX-01**')})" ],
                 out
  end

  test "a Requirements section without requirements fails" do
    content = PASSING.sub(/^- \*\*DX-01\*\*.*?(?=^## Developer)/m, "")
    status, out, = check_area(content)

    assert_equal 1, status
    assert_equal [ "#{line_of(content, '## Requirements')}: Requirements lists no requirement" ], out
  end

  test "Sources counts distinct URLs against --min-sources" do
    status, out, = check_area(PASSING, "--min-sources", "6")

    assert_equal 1, status
    assert_equal [ "#{line_of(PASSING, '## Sources')}: Sources lists 5 distinct URLs, at least 6 required" ], out
    assert_equal 0, check_area(PASSING, "--min-sources", "5").first
  end

  test "URLs outside Sources do not count" do
    content = PASSING.sub(%r{^- https://github.com/varvet/pundit.*\n}, "")
    content = content.sub("## Scope\n", "## Scope\n\nSee https://github.com/varvet/pundit.\n")
    status, out, = check_area(content)

    assert_equal 1, status
    assert_equal [ "#{line_of(content, '## Sources')}: Sources lists 4 distinct URLs, at least 5 required" ], out
  end

  test "a heading inside a fenced code block is not a section" do
    content = broken("## Sources\n", "```\n## Sources\n```\n")
    status, out, = check_area(content)

    assert_equal 1, status
    assert_includes out, "#{line_of(content, '## Open decisions')}: missing required section \"## Sources\""
  end

  test "an unknown area code, a missing file and a bad --min-sources are bad input" do
    assert_equal [ 2, "", "requirements_check: unknown area \"DOCS\"; known: #{MarkdownGemRequirements::AREAS.keys.join(', ')}\n" ],
                 run_cli("--area", "DOCS", FIXTURE)
    assert_equal [ 2, "", "requirements_check: no such file: #{@dir}/nope.md\n" ], run_cli("--area", "DX", "#{@dir}/nope.md")
    assert_equal 2, run_cli("--area", "DX", FIXTURE, "--min-sources", "zero").first
    assert_equal 2, run_cli("--area", "DX", FIXTURE, "--min-sources", "0").first
  end

  test "no mode, two modes, a wrong file count or an unknown flag are bad input" do
    assert_match(/give --area CODE FILE or --synthesis FILE DIR/, run_cli(FIXTURE)[2])
    assert_match(/give --area CODE FILE or --synthesis FILE DIR/, run_cli("--area", "DX", "--synthesis", FIXTURE, @dir)[2])
    assert_match(/--area takes one FILE/, run_cli("--area", "DX", FIXTURE, FIXTURE)[2])
    assert_match(/--synthesis takes FILE DIR/, run_cli("--synthesis", FIXTURE)[2])
    assert_match(/invalid option/, run_cli("--frobnicate")[2])
    assert_equal [ 2, 2, 2, 2, 2 ], [ run_cli(FIXTURE), run_cli("--area", "DX", "--synthesis", FIXTURE, @dir),
                                      run_cli("--area", "DX", FIXTURE, FIXTURE), run_cli("--synthesis", FIXTURE),
                                      run_cli("--frobnicate") ].map(&:first)
  end

  test "--help prints the usage and exits 0" do
    status, out, err = run_cli("--help")

    assert_equal 0, status
    assert_match(/--area CODE FILE/, out)
    assert_match(/--synthesis FILE DIR/, out)
    assert_empty err
  end

  def research_dir
    write("requirements/developer-experience.md", PASSING)
    write("requirements/editor-ux.md", "## Requirements\n\n- **EDIT-01** (MUST) Undo works. Acceptance: undo restores text.\n")
    write("requirements/TEMPLATE.md", "## Requirements\n\n- **DX-99** (MUST) Example. Acceptance: example.\n")
    write("requirements/README.md", "## IDs\n\n- **RENDER-01** (MUST) Example. Acceptance: example.\n")
    File.join(@dir, "requirements")
  end

  def traceability(*ids)
    rows = ids.map { "| #{it} | Requirement | 0.1 |" }
    <<~MD
      # Requirements

      DX-02 is mentioned in prose but not in the table.

      ## Traceability

      | ID | Requirement | Release |
      |----|-------------|---------|
      #{rows.join("\n")}

      ## Release plan

      | DX-03 | outside the traceability section |
    MD
  end

  test "--synthesis passes when every ID defined in the research docs is in the traceability table" do
    synthesis = write("REQUIREMENTS.md", traceability("DX-01", "DX-02", "DX-03", "EDIT-01"))
    status, out, = run_cli("--synthesis", synthesis, research_dir)

    assert_equal 0, status
    assert_equal "requirements_check: ok: #{synthesis} (4 requirement IDs from 2 docs traced)\n", out
  end

  test "--synthesis reports every missing ID with the line that defines it" do
    dir = research_dir
    synthesis = write("REQUIREMENTS.md", traceability("DX-01"))
    status, out, = run_cli("--synthesis", synthesis, dir)

    assert_equal 1, status
    doc = File.join(dir, "developer-experience.md")

    assert_equal [
      "#{synthesis}:#{line_of(traceability, '## Traceability')}: DX-02 missing from the traceability table " \
      "(defined at #{doc}:#{line_of(PASSING, '**DX-02**')})",
      "#{synthesis}:#{line_of(traceability, '## Traceability')}: DX-03 missing from the traceability table " \
      "(defined at #{doc}:#{line_of(PASSING, '**DX-03**')})",
      "#{synthesis}:#{line_of(traceability, '## Traceability')}: EDIT-01 missing from the traceability table " \
      "(defined at #{File.join(dir, 'editor-ux.md')}:3)"
    ], out.lines(chomp: true)
  end

  test "--synthesis without a Traceability section fails" do
    synthesis = write("REQUIREMENTS.md", "# Requirements\n\n| DX-01 |\n")
    status, out, = run_cli("--synthesis", synthesis, research_dir)

    assert_equal 1, status
    assert_equal "#{synthesis}:1: missing required section \"## Traceability\"", out.lines(chomp: true).first
  end

  test "--synthesis on a directory without research docs is bad input, never green" do
    write("empty/TEMPLATE.md", "## Requirements\n")
    synthesis = write("REQUIREMENTS.md", traceability)

    assert_equal [ 2, "", "requirements_check: no research docs in #{@dir}/empty\n" ],
                 run_cli("--synthesis", synthesis, File.join(@dir, "empty"))
    assert_equal 2, run_cli("--synthesis", synthesis, File.join(@dir, "nope")).first
  end

  test "the executable runs from the shell with the same exit codes" do
    out, status = Open3.capture2e(RbConfig.ruby, SCRIPT, "--area", "DX", FIXTURE)

    assert_equal [ 0, "requirements_check: ok: #{FIXTURE} (area DX, 3 requirements, 5 sources)\n" ], [ status.exitstatus, out ]

    _, status = Open3.capture2e(RbConfig.ruby, SCRIPT, "--area", "DX", File.join(REQUIREMENTS_DIR, "TEMPLATE.md"))

    assert_equal 1, status.exitstatus

    _, status = Open3.capture2e(RbConfig.ruby, SCRIPT, "--help")

    assert_equal 0, status.exitstatus
  end

  test "the README lists every area code with the doc that owns it" do
    readme = File.read(File.join(REQUIREMENTS_DIR, "README.md"))

    MarkdownGemRequirements::AREAS.each do |code, doc|
      assert_match(/^\| `#{code}` \| `#{Regexp.escape(doc)}` \|/, readme, "README area table misses #{code}")
    end
    assert_equal %w[DX RAILS ASSETS VIEWS THEME EDIT RENDER AGENT PRIOR PAPYRO], MarkdownGemRequirements::AREAS.keys
  end
end
