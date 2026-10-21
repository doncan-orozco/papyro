require "test_helper"
require "tmpdir"
require "open3"
require "rbconfig"
require "json"

# Golden tests for the rename judge (.claude/scripts/gem/rename_check.rb): upstream shadcn names and rename history pass, every old
# spelling of the gem is reported with file:line and its replacement, so the rename items of the chadcn-rebrand epic have a gate
# that cannot silently stop catching leftovers.
class RenameCheckTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join(".claude/scripts/gem/rename_check.rb").to_s

  UPSTREAM = <<~MD
    # Credits
    Ported from shadcn/ui (https://ui.shadcn.com), theme in shadcn format.
    The oracle lives in gems/chadcn/dev/react-shadcn-catalog; tooling in .claude/scripts/shadcn/layout.rb.
    Run /shadcn-plan, /shadcn-run, /shadcn-audit and /shadcn-golden; see the shadcn-port and radix-stimulus skills.
    History: epic phlex-shadcn-adoption (label epic:phlex-shadcn-hardening), item #175 of phlex-shadcn-adoption-followups.
  MD

  setup do
    @dir = Dir.mktmpdir("rename-check")
    @host = File.join(@dir, "host")
    @engine = File.join(@dir, "engine")
    write(@host, "docs/credits.md", UPSTREAM)
  end

  teardown { FileUtils.remove_entry(@dir) }

  def write(root, path, content)
    full = File.join(root, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.binwrite(full, content)
  end

  def git_init(root)
    FileUtils.mkdir_p(root)
    system("git", "init", "-q", root, exception: true)
    system("git", "-C", root, "add", "-A", exception: true)
  end

  def check(*args, engine: "none")
    git_init(@host)
    out, err, status = Open3.capture3(RbConfig.ruby, SCRIPT, "--root", @host, "--engine-dir", engine, "--format", "json", *args)
    [ (JSON.parse(out) unless out.empty?), err, status.exitstatus ]
  end

  def spellings(report) = report["findings"].map { |f| f["old"] }

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
    finding = report["findings"].find { |f| f["old"] == "Phlex::Shadcn" }

    assert_equal [ "lib/x.rb", 2, "Chadcn" ], finding.values_at("file", "line", "new")
    assert_includes spellings(report), "PHLEX_SHADCN_"
    assert_includes spellings(report), "config.phlex_shadcn"
    assert_includes spellings(report), "phlex:shadcn:install"
  end

  test "the nested module form and relative Shadcn constants are leftovers" do
    write(@host, "lib/y.rb", "module Phlex\n  module Shadcn\n    X = Shadcn.config\n  end\nend\n")
    report, _, code = check("--stage", "ruby")

    assert_equal 1, code
    assert_equal [ 2, 3 ], report["findings"].map { |f| f["line"] }
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

  test "file paths that still carry an old name are reported" do
    write(@host, "gems/phlex-shadcn/app/javascript/controllers/shadcn/dialog_controller.js", "export default class {}\n")
    report, _, = check("--stage", "all")
    paths = report["findings"].select { |f| f["line"].nil? }.map { |f| f["old"] }

    assert_includes paths, "gems/phlex-shadcn"
    assert_includes paths, "app/javascript/controllers/shadcn"
  end

  test "node_modules and untracked files are not scanned" do
    write(@host, "node_modules/pkg/index.js", "phlex-shadcn\n")
    write(@host, ".gitignore", "node_modules/\nscratch.txt\n")
    write(@host, "scratch.txt", "Phlex::Shadcn\n")
    _, _, code = check("--stage", "all")

    assert_equal 0, code
  end

  test "a binary tracked file holding an old name is reported without a line" do
    write(@host, "doc/root.dat", "\x00\x01Phlex::Shadcn\x00")
    report, _, code = check("--stage", "ruby")

    assert_equal 1, code
    assert_equal [ [ "doc/root.dat", nil ] ], report["findings"].map { |f| f.values_at("file", "line") }
  end

  test "a CHANGELOG line recording the rename passes, another CHANGELOG line does not" do
    write(@host, "gems/chadcn/CHANGELOG.md", "- Renamed phlex-shadcn to chadcn.\n- Fixed Phlex::Shadcn::Button.\n")
    report, _, code = check("--stage", "ruby")

    assert_equal 1, code
    assert_equal [ 2 ], report["findings"].map { |f| f["line"] }
  end

  test "the engine checkout is scanned too" do
    write(@engine, "app/views/v.rb", "Phlex::Shadcn::Card\n")
    git_init(@engine)
    report, _, code = check("--stage", "ruby", engine: @engine)

    assert_equal 1, code
    assert_equal "engine/app/views/v.rb", report["findings"].first["file"]
  end

  test "the mapping table covers every identifier spelling of the epic" do
    out, _, status = Open3.capture3(RbConfig.ruby, SCRIPT, "--mapping")
    olds = JSON.parse(out).map { |row| row["old"] }

    assert_predicate status, :success?
    %w[phlex-shadcn phlex_shadcn Phlex::Shadcn phlex/shadcn phlex:shadcn PHLEX_SHADCN_ gems/phlex-shadcn lib/phlex/shadcn
       phlex:shadcn:install phlex:shadcn:eject config.phlex_shadcn phlex_shadcn: phlex-shadcn:start phlex-shadcn:end
       app/assets/tailwind/phlex-shadcn skills/phlex-shadcn phlex-shadcn.yml gem_phlex_shadcn doncan-orozco/phlex-shadcn
       for_gem_extension(Phlex) shadcn-- shadcn---probe- controllers/shadcn javascript/shadcn].each { |old| assert_includes olds, old }
  end

  test "the self-test passes" do
    _, err, status = Open3.capture3(RbConfig.ruby, SCRIPT, "--stage", "ruby", "--self-test")

    assert_equal 0, status.exitstatus, err
  end

  test "an unknown stage is a usage error" do
    _, _, status = Open3.capture3(RbConfig.ruby, SCRIPT, "--stage", "css")

    assert_equal 2, status.exitstatus
  end
end
