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
    RUBY

    status, out, = run_cli("app")

    assert_equal 0, status
    assert_empty out
  end

  test "a clean path exits 0 with no output" do
    write(@host, "app/components/parity/catalog.rb", "class Catalog; end\n")

    assert_equal [ 0, "", "" ], run_cli("app/components/parity")
  end

  test "the legacy directories themselves are never reported, even when asked for" do
    write(@host, "app/components/ui/button.rb", "class #{CONST}; end\n")
    write(@host, "app/javascript/controllers/ui/dialog_controller.js", %(import B from "#{IMPORT}"\n))
    write(@host, "test/components/ui/button_test.rb", "#{CONST}.new\n")

    assert_equal 0, run_cli("app", "test").first
    assert_equal 0, run_cli("app/components/ui").first
    assert_equal 0, run_cli("app/components/ui/button.rb").first
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
    assert_equal %W[app/a.rb config/c.rb lib/b.rb test/d_test.rb #{@engine}/app/views/studio/e.rb #{@engine}/test/f_test.rb],
      out.lines(chomp: true).map { |line| line.split(":").first }
  end

  test "the engine directory comes from BUNDLE_LOCAL__PAPYRO_STUDIO, then the host bundle config, then the sibling" do
    write(@engine, "app/e.rb", "#{CONST}\n")
    sibling = File.join(@dir, "papyro_studio")
    write(sibling, "app/s.rb", "#{CONST}\n")

    assert_match(%r{\A#{sibling}/app/s\.rb:}, run_cli[1])

    write(@host, ".bundle/config", %(---\nBUNDLE_LOCAL__PAPYRO_STUDIO: "#{@engine}"\n))

    assert_match(%r{\A#{@engine}/app/e\.rb:}, run_cli[1])

    other = File.join(@dir, "other")
    write(other, "app/o.rb", "#{CONST}\n")

    assert_match(%r{\A#{other}/app/o\.rb:}, run_cli(env: { "BUNDLE_LOCAL__PAPYRO_STUDIO" => other })[1])
  end

  test "a missing engine directory is skipped in no-path mode, a host-only scan still works" do
    write(@host, "app/a.rb", "#{CONST}\n")

    status, out, = run_cli("--engine", File.join(@dir, "nope"))

    assert_equal 1, status
    assert_equal [ "app/a.rb:1:#{CONST}" ], out.lines(chomp: true)
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
  end

  test "--json on a clean path exits 0 with an empty report" do
    write(@host, "app/c.rb", "clean\n")

    status, out, = run_cli("--json", "app")

    assert_equal 0, status
    assert_equal({ "total" => 0, "files" => {}, "findings" => [] }, JSON.parse(out))
  end

  test "bad input exits 2 with a message on stderr" do
    status, out, err = run_cli("app/nope")

    assert_equal 2, status
    assert_empty out
    assert_match(/no such file or directory: app\/nope/, err)
    assert_equal 2, run_cli("--frobnicate").first
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
