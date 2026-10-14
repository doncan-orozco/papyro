# frozen_string_literal: true

require_relative "engine_helper"

class EngineTest::Wiring < Minitest::Test
  GEM_ROOT = Phlex::Shadcn.root
  ASSETS = GEM_ROOT.join("app/assets/tailwind/phlex-shadcn")
  Theme = Phlex::Shadcn::Theme

  # importmap-rails asks a resolver for the digested URL of every pinned asset; the logical path is all these tests need.
  Resolver = Struct.new(:unused) do
    def path_to_asset(path) = "/assets/#{path}"
  end

  def app = EngineTest::Application

  def imports = JSON.parse(app.importmap.to_json(resolver: Resolver.new))["imports"]

  # A fresh Rake application with the app's (and the engines') tasks loaded; the previous one is put back afterwards.
  def with_tasks
    previous = Rake.application
    Rake.application = Rake::Application.new
    app.load_tasks
    yield
  ensure
    Rake.application = previous
  end

  def seed_theme
    FileUtils.rm_rf(EngineTest::THEME_DIR)
    FileUtils.mkdir_p(EngineTest::THEME_DIR.join("presets"))
    FileUtils.cp(ASSETS.join("theme.css"), EngineTest::THEME_DIR)
    FileUtils.cp(Dir[ASSETS.join("presets/*.css").to_s], EngineTest::THEME_DIR.join("presets"))
  end

  def test_the_engine_is_registered_under_the_name_tailwindcss_rails_expects
    assert_includes Rails::Engine.subclasses, Phlex::Shadcn::Engine
    assert_equal "phlex-shadcn", Phlex::Shadcn::Engine.engine_name
    assert_equal GEM_ROOT.to_s, Phlex::Shadcn::Engine.root.to_s
  end

  def test_the_gem_javascript_directories_are_on_the_asset_load_path
    paths = app.config.assets.paths.map(&:to_s)

    assert_includes paths, GEM_ROOT.join("app/javascript").to_s
    assert_includes paths, GEM_ROOT.join("vendor/javascript").to_s
    assert_equal paths.uniq, paths, "an asset directory was added twice"
  end

  def test_the_tailwind_entry_is_excluded_from_propshaft_once
    excluded = app.config.assets.excluded_paths.map(&:to_s)

    assert_equal 1, excluded.count(GEM_ROOT.join("app/assets/tailwind").to_s)
  end

  def test_importmap_pins_the_controllers_the_primitives_and_floating_ui
    pins = imports

    assert_equal "/assets/controllers/shadcn/dialog_controller.js", pins["controllers/shadcn/dialog_controller"]
    assert_equal "/assets/shadcn/primitives/presence.js", pins["shadcn/primitives/presence"]
    assert_equal "/assets/@floating-ui--dom.js", pins["@floating-ui/dom"]
    assert_equal "/assets/@floating-ui--utils--dom.js", pins["@floating-ui/utils/dom"]
  end

  def test_every_pinned_gem_file_exists
    pins = imports.select { |name, _| name.start_with?("controllers/shadcn/", "shadcn/", "@floating-ui/") }

    refute_empty pins
    missing = pins.values.reject do |url|
      logical = url.delete_prefix("/assets/")
      %w[app/javascript vendor/javascript].any? { |dir| GEM_ROOT.join(dir, logical).file? }
    end

    assert_empty missing
  end

  def test_the_development_cache_sweeper_watches_the_gem_javascript
    watched = app.config.importmap.cache_sweepers.map(&:to_s)

    assert_includes watched, GEM_ROOT.join("app/javascript").to_s
    assert_includes watched, GEM_ROOT.join("vendor/javascript").to_s
  end

  def test_a_relative_theme_directory_is_rooted_at_the_app_not_at_the_working_directory
    refute_equal EngineTest::ROOT.to_s, Dir.pwd, "the test needs a working directory that differs from the app root"
    assert_equal EngineTest::THEME_DIR.to_s, Theme.dir
    assert_equal EngineTest::THEME_DIR.join("theme.css").to_s, Theme.theme_file
  end

  def test_the_namespaced_theme_tasks_exist_and_the_short_aliases_too_when_the_host_has_no_theme_rake
    with_tasks do
      %w[list use import check].each do |name|
        assert Rake::Task.task_defined?("phlex_shadcn:theme:#{name}"), "phlex_shadcn:theme:#{name}"
        assert Rake::Task.task_defined?("theme:#{name}"), "theme:#{name}"
      end
    end
  end

  def test_no_short_aliases_while_the_host_still_has_its_own_theme_rake
    host_tasks = EngineTest::ROOT.join("lib/tasks/theme.rake")
    FileUtils.mkdir_p(host_tasks.dirname)
    FileUtils.touch(host_tasks)

    with_tasks do
      assert Rake::Task.task_defined?("phlex_shadcn:theme:use")
      %w[list use import check].each { |name| refute Rake::Task.task_defined?("theme:#{name}"), "theme:#{name} would run twice" }
    end
  ensure
    FileUtils.rm_f(host_tasks)
  end

  def test_the_alias_forwards_its_argument_and_switches_the_preset
    seed_theme
    with_tasks do
      capture_io { Rake::Task["theme:use"].invoke("slate") }
    end
    slate = Theme.parse(ASSETS.join("presets/slate.css").read).root

    assert_equal slate, Theme.parse(EngineTest::THEME_DIR.join("theme.css").read).root
  end

  def test_an_unknown_preset_exits_with_the_message_and_changes_nothing
    seed_theme
    before = EngineTest::THEME_DIR.join("theme.css").read
    error = nil
    with_tasks do
      capture_io do
        error = assert_raises(SystemExit) { Rake::Task["phlex_shadcn:theme:use"].invoke("nope") }
      end
    end

    refute_predicate error, :success?
    assert_equal before, EngineTest::THEME_DIR.join("theme.css").read
  end

  def test_the_check_task_fails_on_a_missing_theme_file_with_a_message_instead_of_a_stack_trace
    FileUtils.rm_rf(EngineTest::THEME_DIR)
    stderr = nil
    with_tasks do
      _out, stderr = capture_io do
        assert_raises(SystemExit) { Rake::Task["phlex_shadcn:theme:check"].invoke }
      end
    end

    assert_match(/theme\.css/, stderr)
  end

  def test_the_tailwind_entry_point_is_bundled_for_the_host
    Tailwindcss::Engines.bundle
    bundle = EngineTest::ROOT.join("app/assets/builds/tailwind/phlex-shadcn.css")
    entry = ASSETS.join("engine.css")

    assert_predicate bundle, :file?
    assert_includes bundle.read, %(@import "#{entry}";)
    imports = entry.read.scan(%r{@import "\./([^"]+)";}).flatten

    refute_empty imports
    imports.each { |file| assert_predicate entry.dirname.join(file), :file?, file }
  end

  def test_the_entry_point_scans_the_gems_ruby_files_relative_to_itself
    source = ASSETS.join("engine.css").read[/@source "([^"]+)";/, 1]

    refute_nil source, "engine.css needs its own @source: the absolute path in the host's CSS goes stale on a gem update"
    assert_predicate ASSETS.join(source).cleanpath.join("button.rb"), :file?
  end

  def test_the_shipped_assets_are_complete
    %w[engine.css theme.css tokens.css vendor/shadcn-tailwind.css vendor/tw-animate.css].each { |file| assert_predicate ASSETS.join(file), :file?, file }
    presets = ASSETS.join("presets").children.map { |file| file.basename(".css").to_s }

    assert_includes presets, "slate"
    assert_includes presets, "zinc"
    refute_predicate ASSETS.join("legacy-compat.css"), :exist?, "legacy-compat.css stays host-only"
  end
end
