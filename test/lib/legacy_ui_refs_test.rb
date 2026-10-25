require "test_helper"
require "tmpdir"
require "open3"
require "rbconfig"
require "stringio"
require Rails.root.join(".claude/scripts/ui/legacy_ui_refs").to_s

# The judge every retire-legacy-ui item uses for "this file no longer uses the legacy UI". Fixtures live in tmp dirs;
# the reference strings are assembled at runtime so this file never reports itself.
class LegacyUiRefsTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join(".claude/scripts/ui/legacy_ui_refs.rb").to_s
  NAMESPACE = [ "Components", "Ui" ].join("::")
  CONST = [ "Ui", "Button" ].join("::")
  CONTROLLER = [ "ui", "dialog" ].join("--")
  IMPORT = [ "controllers", "ui", "base_controller" ].join("/")
  DATA_KEY = [ "ui", "_dialog_target" ].join("_")
  LIB_CONTROLLER = File.join("app/javascript", File.dirname(IMPORT), "dialog_controller.js")
  HTML_TARGET = [ "data-ui", "dialog-target" ].join("--")

  setup do
    @dir = Dir.mktmpdir("legacy-ui-refs")
    @host = File.join(@dir, "host")
    @engine = File.join(@dir, "engine")
  end

  teardown { FileUtils.remove_entry(@dir) }

  def write(root, path, content)
    file = File.join(root, path)
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, content)
    file
  end

  def run_cli(*argv, env: {})
    out = StringIO.new
    err = StringIO.new
    status = LegacyUiRefs::CLI.new(out: out, err: err, root: @host, env: env).run(argv)
    [ status, out.string, err.string ]
  end

  test "each reference kind is reported as file:line:match and exits 1" do
    write(@host, "app/views/page.rb", <<~RUBY)
      class Page
        def view_template
          render #{NAMESPACE}::Card.new
          render #{CONST}.new(variant: :ghost)
          div(data: { controller: "#{CONTROLLER}" })
        end
      end
    RUBY
    write(@host, "config/importmap.rb", %(pin "#{IMPORT}"\n))

    status, out, = run_cli("app", "config")

    assert_equal 1, status
    assert_equal [
      "app/views/page.rb:3:#{NAMESPACE}",
      "app/views/page.rb:4:#{CONST}",
      "app/views/page.rb:5:#{CONTROLLER}",
      "config/importmap.rb:1:#{[ 'controllers', 'ui', '' ].join('/')}"
    ], out.lines(chomp: true)
  end

  test "a namespaced constant is reported once, not also as a bare constant" do
    write(@host, "app/a.rb", "render #{NAMESPACE}::Button.new\n")

    _, out, = run_cli("app/a.rb")

    assert_equal [ "app/a.rb:1:#{NAMESPACE}" ], out.lines(chomp: true)
  end

  test "lookalikes are not references" do
    write(@host, "app/clean.rb", <<~RUBY)
      render Chadcn::Button.new(data: { controller: "chadcn--dialog" })
      MyUi::Button
      Foo::Ui::Thing
      "build--ui--x"
      # app/controllers/uix/thing.rb
      "#{[ 'controllers', 'uix' ].join('/')}"
    RUBY

    status, out, = run_cli("app")

    assert_equal 0, status
    assert_empty out
  end

  test "root-anchored constants and bare controller directory paths are references" do
    write(@host, "app/a.rb", "render ::#{CONST}.new\n")
    write(@host, "config/importmap.rb", %(pin_all_from "app/javascript/#{File.dirname(IMPORT)}"\n))

    status, out, = run_cli("--json", "app", "config")

    assert_equal 1, status
    assert_equal %w[constant import], JSON.parse(out)["findings"].map { |finding| finding["kind"] }
  end

  test "a clean path exits 0 with no output" do
    write(@host, "app/components/parity/catalog.rb", "class Catalog; end\n")

    assert_equal [ 0, "", "" ], run_cli("app/components/parity")
  end

  test "a re-created legacy library is reported" do
    write(@host, "app/components/ui/button.rb", "class #{CONST}; end\n")
    write(@host, File.join("app/javascript", File.dirname(IMPORT), "dialog_controller.js"), %(import B from "#{IMPORT}"\n))
    write(@host, "test/components/ui/button_test.rb", "#{CONST}.new\n")

    status, out, = run_cli("app", "test")

    assert_equal 1, status
    assert_equal [ "app/components/ui/button.rb", LIB_CONTROLLER, "test/components/ui/button_test.rb" ],
                 out.lines(chomp: true).map { it.split(":").first }.uniq
    assert_equal 1, run_cli("app/components/ui").first
  end

  test "binary files are skipped" do
    write(@host, "app/assets/images/logo.png", "\x89PNG\x00#{CONST}")

    assert_equal 0, run_cli("app").first
  end

  test "no paths scans host and engine app, lib, config and test and nothing else" do
    write(@host, "app/a.rb", "#{CONST}\n")
    write(@host, "lib/b.rb", "#{CONST}\n")
    write(@host, "config/c.rb", "#{CONST}\n")
    write(@host, "test/d_test.rb", "#{CONST}\n")
    write(@host, "db/seeds.rb", "#{CONST}\n")
    write(@engine, "app/views/studio/e.rb", "#{CONST}\n")
    write(@engine, "test/f_test.rb", "#{CONST}\n")
    write(@engine, "docs/g.md", "#{CONST}\n")

    status, out, = run_cli("--engine", @engine)

    assert_equal 1, status
    assert_equal %W[app/a.rb lib/b.rb config/c.rb test/d_test.rb #{@engine}/app/views/studio/e.rb #{@engine}/test/f_test.rb],
      out.lines(chomp: true).map { |line| line.split(":").first }
  end

  test "the engine directory comes from BUNDLE_LOCAL__PAPYRO_STUDIO in the environment first" do
    write(@host, "app/a.rb", "clean\n")
    other = File.join(@dir, "other")
    write(other, "app/o.rb", "#{CONST}\n")
    write(@engine, "app/e.rb", "#{CONST}\n")
    write(@host, ".bundle/config", %(---\nBUNDLE_LOCAL__PAPYRO_STUDIO: "#{@engine}"\n))

    assert_equal [ "#{other}/app/o.rb:1:#{CONST}" ], run_cli(env: { "BUNDLE_LOCAL__PAPYRO_STUDIO" => other })[1].lines(chomp: true)
  end

  test "a padded environment value is stripped before it is used" do
    write(@host, "app/a.rb", "clean\n")
    other = File.join(@dir, "other")
    write(other, "app/o.rb", "#{CONST}\n")

    assert_equal [ "#{other}/app/o.rb:1:#{CONST}" ], run_cli(env: { "BUNDLE_LOCAL__PAPYRO_STUDIO" => "  #{other}  " })[1].lines(chomp: true)
  end

  test "a blank --engine is treated as absent" do
    write(@host, "app/a.rb", "#{CONST}\n")

    status, out, err = run_cli("--engine", "")

    assert_equal 1, status
    assert_equal [ "app/a.rb:1:#{CONST}" ], out.lines(chomp: true)
    assert_match(/warning: no engine checkout/, err)
  end

  test "the engine directory comes from the host bundle config before the sibling" do
    write(@host, "app/a.rb", "clean\n")
    write(@engine, "app/e.rb", "#{CONST}\n")
    write(File.join(@dir, "papyro_studio"), "app/s.rb", "#{CONST}\n")
    write(@host, ".bundle/config", %(---\nBUNDLE_LOCAL__PAPYRO_STUDIO: "#{@engine}"\n))

    assert_equal [ "#{@engine}/app/e.rb:1:#{CONST}" ], run_cli[1].lines(chomp: true)
  end

  test "the engine directory falls back to the sibling papyro_studio" do
    write(@host, "app/a.rb", "clean\n")
    sibling = File.join(@dir, "papyro_studio")
    write(sibling, "app/s.rb", "#{CONST}\n")

    assert_match(%r{\A#{sibling}/app/s\.rb:}, run_cli[1])
  end

  test "an empty BUNDLE_LOCAL__PAPYRO_STUDIO falls through to the next source" do
    write(@host, "app/a.rb", "clean\n")
    write(@engine, "app/e.rb", "#{CONST}\n")
    write(@host, ".bundle/config", %(---\nBUNDLE_LOCAL__PAPYRO_STUDIO: "#{@engine}"\n))

    assert_equal [ "#{@engine}/app/e.rb:1:#{CONST}" ], run_cli(env: { "BUNDLE_LOCAL__PAPYRO_STUDIO" => "  " })[1].lines(chomp: true)
  end

  test "an engine that resolves to the host root is bad input" do
    write(@host, "app/a.rb", "clean\n")

    status, out, err = run_cli("--engine", ".")

    assert_equal 2, status
    assert_empty out
    assert_match(/resolves to the host root/, err)
  end

  test "an explicit engine directory that is missing is bad input" do
    write(@host, "app/a.rb", "#{CONST}\n")

    status, out, err = run_cli("--engine", File.join(@dir, "nope"))

    assert_equal 2, status
    assert_empty out
    assert_match(/no engine checkout at .*nope/, err)
  end

  test "a missing sibling engine warns and scans the host only" do
    write(@host, "app/a.rb", "#{CONST}\n")

    status, out, err = run_cli

    assert_equal 1, status
    assert_equal [ "app/a.rb:1:#{CONST}" ], out.lines(chomp: true)
    assert_match(/warning: no engine checkout/, err)
  end

  test "a malformed bundle config is bad input, not a finding" do
    write(@host, "app/a.rb", "clean\n")
    write(@host, ".bundle/config", "---\n: : [\n")

    status, out, err = run_cli

    assert_equal 2, status
    assert_empty out
    assert_match(/legacy_ui_refs:/, err)
  end

  test "a bundle config that is not a YAML mapping is bad input" do
    write(@host, "app/a.rb", "clean\n")
    write(@host, ".bundle/config", "- a\n- b\n")

    status, out, err = run_cli

    assert_equal 2, status
    assert_empty out
    assert_match(/is not a YAML mapping/, err)
  end

  test "no-path mode outside a host root is bad input, never clean" do
    FileUtils.mkdir_p(@host)

    status, out, err = run_cli

    assert_equal 2, status
    assert_empty out
    assert_match(/run from the host root/, err)
  end

  test "Phlex data keys and HTML data attributes of legacy controllers are references" do
    write(@host, "app/a.rb", "data: { #{DATA_KEY}: true }\n")
    write(@host, "app/b.html", %(<div #{HTML_TARGET}></div>\n))

    status, out, = run_cli("--json", "app")

    assert_equal 1, status
    assert_equal %w[data_key controller], JSON.parse(out)["findings"].map { |finding| finding["kind"] }
  end

  test "--json lists every finding and the count per file" do
    write(@host, "app/a.rb", "#{CONST}\n#{CONST} #{NAMESPACE}::Card\n")
    write(@host, "app/b.rb", %(data: { controller: "#{CONTROLLER}" }\n))
    write(@host, "app/c.rb", "clean\n")

    status, out, = run_cli("--json", "app")
    report = JSON.parse(out)

    assert_equal 1, status
    assert_equal 4, report["total"]
    assert_equal({ "app/a.rb" => 3, "app/b.rb" => 1 }, report["files"])
    assert_equal({ "file" => "app/a.rb", "line" => 2, "kind" => "constant", "match" => CONST }, report["findings"][1])
    assert_equal %w[constant constant namespace controller], report["findings"].map { |finding| finding["kind"] }
  end

  test "--json on a clean path exits 0 with an empty report" do
    write(@host, "app/c.rb", "clean\n")

    status, out, = run_cli("--json", "app")

    assert_equal 0, status
    assert_equal({ "total" => 0, "files" => {}, "findings" => [] }, JSON.parse(out))
  end

  test "a missing path exits 2 with a message on stderr" do
    status, out, err = run_cli("app/nope")

    assert_equal 2, status
    assert_empty out
    assert_match(/no such file or directory: app\/nope/, err)
  end

  test "an unknown flag exits 2 with a message on stderr" do
    status, out, err = run_cli("--frobnicate")

    assert_equal 2, status
    assert_empty out
    assert_match(/invalid option/, err)
  end

  test "the executable runs from the shell with the same exit codes" do
    write(@host, "app/a.rb", "#{CONST}\n")
    write(@host, "app/clean/b.rb", "clean\n")

    out, status = Open3.capture2e(RbConfig.ruby, SCRIPT, "app/a.rb", chdir: @host)

    assert_equal 1, status.exitstatus
    assert_equal "app/a.rb:1:#{CONST}\n", out
    assert_equal 0, Open3.capture2e(RbConfig.ruby, SCRIPT, "app/clean", chdir: @host).last.exitstatus
  end
end
