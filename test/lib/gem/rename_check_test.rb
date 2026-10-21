require "test_helper"
require "tmpdir"
require "open3"
require "rbconfig"
require "json"

# Golden tests for the rename judge (.claude/scripts/gem/rename_check.rb): upstream shadcn names and rename history
# pass, every old spelling of the gem is reported with file:line and its replacement, so the rename items of the
# chadcn-rebrand epic have a gate that cannot silently stop catching leftovers.
class RenameCheckTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join(".claude/scripts/gem/rename_check.rb").to_s

  UPSTREAM = <<~MD
    # Credits
    Ported from shadcn/ui (https://ui.shadcn.com), theme in shadcn format.
    The oracle lives in gems/chadcn/dev/react-shadcn-catalog; tooling in .claude/scripts/shadcn/layout.rb.
    Run /shadcn-plan, /shadcn-run, /shadcn-audit and /shadcn-golden; see the shadcn-port and radix-stimulus skills.
    History: epic phlex-shadcn-adoption (label epic:phlex-shadcn-hardening),
    item #175 of phlex-shadcn-adoption-followups.
  MD

  EXPECTED_MAPPING = [
    [ "doncan-orozco/phlex-shadcn", "doncan-orozco/chadcn" ],
    [ "gems/phlex-shadcn", "gems/chadcn" ],
    [ "app/assets/tailwind/phlex-shadcn", "app/assets/tailwind/chadcn" ],
    [ "skills/phlex-shadcn", "skills/chadcn" ],
    [ "phlex-shadcn.gemspec", "chadcn.gemspec" ],
    [ "phlex-shadcn.yml", "chadcn.yml" ],
    [ "phlex-shadcn:start", "chadcn:start" ],
    [ "phlex-shadcn:end", "chadcn:end" ],
    [ "phlex-shadcn", "chadcn" ],
    [ "lib/generators/phlex/shadcn", "lib/generators/chadcn" ],
    [ "lib/phlex/shadcn", "lib/chadcn" ],
    [ "test/phlex/shadcn", "test/chadcn" ],
    [ "phlex/shadcn", "chadcn" ],
    [ "phlex:shadcn:install", "chadcn:install" ],
    [ "phlex:shadcn:eject", "chadcn:eject" ],
    [ "phlex:shadcn", "chadcn" ],
    [ "gem_phlex_shadcn", "gem_chadcn" ],
    [ "config.phlex_shadcn", "config.chadcn" ],
    [ "phlex_shadcn:", "chadcn:" ],
    [ "phlex_shadcn", "chadcn" ],
    [ "PHLEX_SHADCN_", "CHADCN_" ],
    [ "PHLEX_SHADCN", "CHADCN" ],
    [ "Phlex::Shadcn", "Chadcn" ],
    [ "PhlexShadcn", "Chadcn" ],
    [ "module Shadcn", "module Chadcn" ],
    [ "Shadcn::", "Chadcn::" ],
    [ "Shadcn.", "Chadcn." ],
    [ "for_gem_extension(Phlex)", "for_gem" ],
    [ "shadcn---probe-", "chadcn---probe-" ],
    [ "shadcn--", "chadcn--" ],
    [ "shadcn__", "chadcn__" ],
    [ "app/javascript/controllers/shadcn", "app/javascript/controllers/chadcn" ],
    [ "controllers/shadcn", "controllers/chadcn" ],
    [ "app/javascript/shadcn", "app/javascript/chadcn" ],
    [ "javascript/shadcn", "javascript/chadcn" ],
    [ "shadcn/primitives", "chadcn/primitives" ],
    [ 'under: "shadcn"', 'under: "chadcn"' ]
  ].freeze

  setup do
    @dir = Dir.mktmpdir("rename-check")
    @host = File.join(@dir, "host")
    @engine = File.join(@dir, "engine")
    write(@host, "docs/credits.md", UPSTREAM)
  end

  teardown { FileUtils.remove_entry(@dir) }

  def write(root, path, content)
    absolute_path = File.join(root, path)
    FileUtils.mkdir_p(File.dirname(absolute_path))
    File.binwrite(absolute_path, content)
  end

  def git_init(root, force: [])
    FileUtils.mkdir_p(root)
    system("git", "init", "-q", root, exception: true)
    system("git", "-C", root, "add", "-A", exception: true)
    force.each { |path| system("git", "-C", root, "add", "-f", path, exception: true) }
  end

  def run_script(*args)
    out, err, status = Open3.capture3(RbConfig.ruby, SCRIPT, *args)
    [ out, err, status.exitstatus ]
  end

  # Runs the judge on @host (engine "none" by default; nil omits --engine-dir) -> [json report, stderr, exit code]
  def check(*args, engine: "none", force: [])
    git_init(@host, force:)
    engine_args = engine ? [ "--engine-dir", engine ] : []
    out, err, code = run_script("--root", @host, *engine_args, "--format", "json", *args)
    [ (JSON.parse(out) unless out.empty?), err, code ]
  end

  def spellings(report) = report["findings"].map { |finding| finding["old"] }

  def tuples(report, *keys) = report["findings"].map { |finding| finding.values_at(*keys) }

  test "upstream shadcn names and rename history pass both stages" do
    report, _, code = check("--stage", "all")

    assert_equal 0, code, report.inspect
    assert report["pass"]
  end

  test "each Ruby-side spelling is reported with file, line and replacement" do
    write(@host, "lib/x.rb", <<~RUBY)
      require "phlex/shadcn"
      Phlex::Shadcn::Button.new
      ENV["PHLEX_SHADCN_DEV_ROOT"]
      config.phlex_shadcn.theme_dir
      # bin/rails g phlex:shadcn:install
    RUBY
    report, _, code = check("--stage", "ruby")

    assert_equal 1, code
    assert_includes tuples(report, "file", "line", "old", "new"), [ "lib/x.rb", 2, "Phlex::Shadcn", "Chadcn" ]
    assert_includes tuples(report, "file", "line", "old", "new"), [ "lib/x.rb", 1, "phlex/shadcn", "chadcn" ]
    assert_includes spellings(report), "PHLEX_SHADCN_"
    assert_includes spellings(report), "config.phlex_shadcn"
    assert_includes spellings(report), "phlex:shadcn:install"
  end

  test "the nested module form and relative Shadcn constants are leftovers" do
    write(@host, "lib/y.rb", "module Phlex\n  module Shadcn\n    X = Shadcn.config\n  end\nend\n")
    report, _, code = check("--stage", "ruby")

    assert_equal 1, code
    assert_equal [ 2, 3 ], report["findings"].map { |finding| finding["line"] }
  end

  test "Shadcn.config in prose is not a Ruby-source leftover" do
    write(@host, "docs/notes.md", "Call Shadcn.config to read the settings.\n")
    report, _, code = check("--stage", "ruby")

    assert_equal 0, code, report.inspect
  end

  test "Stimulus spellings belong to the stimulus stage only" do
    write(@host, "app/views/z.rb", %(div(data: { controller: "shadcn--dialog", shadcn__dialog_target: "x" })\n))
    write(@host, "app/javascript/a.js", %(import { presence } from "shadcn/primitives/presence"\n))
    ruby_report, _, ruby_code = check("--stage", "ruby")
    report, _, code = check("--stage", "stimulus")

    assert_equal 0, ruby_code, ruby_report.inspect
    assert_equal 1, code
    assert_equal [ "shadcn--", "shadcn__", "shadcn/primitives" ].sort, spellings(report).uniq.sort
  end

  test "the new chadcn spellings never match" do
    write(@host, "app/javascript/b.js", %(import x from "chadcn/primitives/presence"\nconst c = "chadcn--dialog"\n))
    report, _, code = check("--stage", "all")

    assert_equal 0, code, report.inspect
  end

  test "masked upstream and history names do not hide a leftover on the same line" do
    write(@host, "docs/mixed.md", "Ported from shadcn/ui; see gems/phlex-shadcn and epic/phlex-shadcn/107-publish\n")
    report, _, code = check("--stage", "all")

    assert_equal 1, code
    assert_equal [ [ "docs/mixed.md", 1, "gems/phlex-shadcn" ] ], tuples(report, "file", "line", "old")
  end

  test "an upstream name inside an old spelling does not mask it" do
    write(@host, "docs/port.md", "See the phlex-shadcn-portable notes and the shadcn-port skill.\n")
    report, _, code = check("--stage", "ruby")

    assert_equal 1, code
    assert_equal [ [ "docs/port.md", 1, "phlex-shadcn" ] ], tuples(report, "file", "line", "old")
  end

  test "file paths that still carry an old name are reported once each under the most specific row" do
    path = "gems/phlex-shadcn/app/javascript/controllers/shadcn/dialog_controller.js"
    write(@host, path, "export default class {}\n")
    report, _, = check("--stage", "all")

    assert_equal(
      [ [ path, "path", "gems/phlex-shadcn" ], [ path, "path", "app/javascript/controllers/shadcn" ] ],
      tuples(report, "file", "kind", "old")
    )
  end

  test "the epic's own docs may name the old spellings" do
    write(@host, "docs/features/chadcn-rebrand/ARCHITECTURE.md",
          "Phlex::Shadcn becomes Chadcn; gems/phlex-shadcn moves.\n")
    report, _, code = check("--stage", "all")

    assert_equal 0, code, report.inspect
  end

  test "the checker and its test may name the old spellings" do
    write(@host, ".claude/scripts/gem/rename_check.rb", "Phlex::Shadcn\n")
    write(@host, "test/lib/gem/rename_check_test.rb", "gems/phlex-shadcn\n")
    report, _, code = check("--stage", "all")

    assert_equal 0, code, report.inspect
  end

  test "a tracked node_modules file is never scanned" do
    write(@host, "node_modules/pkg/index.js", "phlex-shadcn\n")
    write(@host, ".gitignore", "node_modules/\n")
    report, _, code = check("--stage", "all", force: [ "node_modules/pkg/index.js" ])

    assert_equal 0, code, report.inspect
  end

  test "gitignored files are not scanned" do
    write(@host, ".gitignore", "scratch.txt\n")
    write(@host, "scratch.txt", "Phlex::Shadcn\n")
    report, _, code = check("--stage", "all")

    assert_equal 0, code, report.inspect
  end

  test "a binary tracked file holding an old name is reported without a line" do
    write(@host, "doc/root.dat", "\x00\x01Phlex::Shadcn\x00")
    report, _, code = check("--stage", "ruby")

    assert_equal 1, code
    assert_equal [ [ "doc/root.dat", nil, "binary" ] ], tuples(report, "file", "line", "kind")
  end

  test "a CHANGELOG line recording the rename passes, another CHANGELOG line does not" do
    write(@host, "gems/chadcn/CHANGELOG.md", "- Renamed phlex-shadcn to chadcn.\n- Fixed Phlex::Shadcn::Button.\n")
    report, _, code = check("--stage", "ruby")

    assert_equal 1, code
    assert_equal [ 2 ], report["findings"].map { |finding| finding["line"] }
  end

  test "the engine checkout is scanned too" do
    write(@engine, "app/views/v.rb", "Phlex::Shadcn::Card\n")
    git_init(@engine)
    report, _, code = check("--stage", "ruby", engine: @engine)

    assert_equal 1, code
    assert_equal "engine/app/views/v.rb", report["findings"].first["file"]
  end

  test "the mapping table is the exact ordered old to new list and only module Shadcn is manual" do
    out, _, code = run_script("--mapping")
    mapping = JSON.parse(out)

    assert_equal 0, code
    assert_equal EXPECTED_MAPPING, mapping.map { |row| row.values_at("old", "new") }
    assert_equal [ "module Shadcn" ], mapping.select { |row| row["rewrite"] == "manual" }.map { |row| row["old"] }
    assert_equal %w[stage old new pattern ruby_source_only rewrite note].sort, mapping.first.keys.sort
  end

  %w[ruby stimulus all].each do |stage|
    test "the self-test passes for the #{stage} stage" do
      _, err, code = run_script("--stage", stage, "--self-test")

      assert_equal 0, code, err
    end
  end

  test "an unknown stage is a usage error" do
    _, _, code = run_script("--stage", "css")

    assert_equal 2, code
  end

  test "a missing engine without --engine-dir is an environment error, not a silent skip" do
    _, err, code = check("--stage", "ruby", engine: nil)

    assert_equal 2, code
    assert_includes err, "--engine-dir none"
  end

  test "stray positional arguments are a usage error" do
    _, err, code = run_script("--stage", "ruby", "--engine-dir", "none", "stray")

    assert_equal 2, code
    assert_includes err, "unexpected argument"
  end

  test "usage errors exit 2" do
    _, _, no_stage = check
    _, err, absent_engine = check("--stage", "ruby", engine: File.join(@dir, "absent"))
    plain = File.join(@dir, "plain")
    FileUtils.mkdir_p(plain)
    _, _, not_git = run_script("--root", plain, "--engine-dir", "none", "--stage", "ruby")

    assert_equal 2, no_stage
    assert_equal 2, absent_engine
    assert_includes err, "does not exist"
    assert_equal 2, not_git
  end

  test "the text format lists file:line: old -> new and a summary naming the scanned roots" do
    write(@host, "lib/x.rb", "Phlex::Shadcn\n")
    git_init(@host)
    out, _, code = run_script("--root", @host, "--engine-dir", "none", "--stage", "ruby", "--format", "text")

    assert_equal 1, code
    assert_includes out.lines.map(&:chomp), "lib/x.rb:1: Phlex::Shadcn -> Chadcn"
    assert_equal "rename_check (ruby): 1 leftover(s) in 1 file(s); scanned #{@host}", out.lines.last.chomp
  end

  test "the text format marks a path finding with its kind" do
    path = "gems/phlex-shadcn/README.md"
    write(@host, path, "hello\n")
    git_init(@host)
    out, _, code = run_script("--root", @host, "--engine-dir", "none", "--stage", "ruby", "--format", "text")

    assert_equal 1, code
    assert_includes out.lines.map(&:chomp), "#{path}:-: gems/phlex-shadcn -> gems/chadcn  (path)"
  end
end
