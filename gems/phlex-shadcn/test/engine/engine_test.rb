# frozen_string_literal: true

require_relative "engine_helper"

class EngineTest::EngineTest < Minitest::Test
  GEM_ROOT = Phlex::Shadcn.root

  # importmap-rails asks a resolver for the digested URL of every pinned asset; the logical path is all these tests need.
  Resolver = Struct.new(:unused) do
    def path_to_asset(path) = "/assets/#{path}"
  end

  def app = EngineTest::Application

  def imports = JSON.parse(app.importmap.to_json(resolver: Resolver.new))["imports"]

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

  def test_the_theme_directory_follows_the_configuration
    assert_equal EngineTest::THEME_DIR.to_s, Phlex::Shadcn::Theme.dir
    assert_equal EngineTest::THEME_DIR.join("theme.css").to_s, Phlex::Shadcn::Theme.theme_file
  end

  def test_the_theme_tasks_are_defined_with_short_aliases_when_the_host_has_none
    Rake.application = Rake::Application.new
    app.load_tasks

    %w[list use import check].each do |name|
      assert Rake::Task.task_defined?("phlex_shadcn:theme:#{name}"), "phlex_shadcn:theme:#{name}"
      assert Rake::Task.task_defined?("theme:#{name}"), "theme:#{name}"
    end
  end

  def test_the_tailwind_entry_point_is_bundled_for_the_host
    Tailwindcss::Engines.bundle
    bundle = EngineTest::ROOT.join("app/assets/builds/tailwind/phlex-shadcn.css")
    entry = GEM_ROOT.join("app/assets/tailwind/phlex-shadcn/engine.css")

    assert_predicate bundle, :file?
    assert_includes bundle.read, %(@import "#{entry}";)
    imports = entry.read.scan(%r{@import "\./([^"]+)";}).flatten

    refute_empty imports
    imports.each { |file| assert_predicate entry.dirname.join(file), :file?, file }
  end

  def test_the_shipped_assets_are_complete
    assets = GEM_ROOT.join("app/assets/tailwind/phlex-shadcn")

    %w[engine.css theme.css tokens.css vendor/shadcn-tailwind.css vendor/tw-animate.css].each { |file| assert_predicate assets.join(file), :file?, file }
    assert_equal %w[gray neutral slate stone zinc zinc-radius0], assets.join("presets").children.map { |file| file.basename(".css").to_s }.sort
    refute_predicate assets.join("legacy-compat.css"), :exist?, "legacy-compat.css stays host-only"
  end
end
