# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "generators/phlex/shadcn/install/sprockets_manifest"
require_relative "engine_helper"

# Sprockets support (dev/decisions/sprockets.md): the engine declares its JavaScript precompiled, boots without Propshaft's
# options, and the doctor names the pipeline. The in-process application uses Propshaft; a Sprockets app is proven by
# `bin/smoke --app --assets sprockets`, so here Sprockets' options object is imitated.
class EngineTest::Sprockets < Minitest::Test
  Generators = Phlex::Shadcn::Generators
  Context = Phlex::Shadcn::Doctor::Context
  Check = Phlex::Shadcn::Doctor::Checks::AssetPipeline
  Options = Struct.new(:precompile)
  ENGINE = Phlex::Shadcn::Engine

  def setup = @root = Pathname.new(Dir.mktmpdir("phlex-shadcn-sprockets"))

  def teardown = FileUtils.remove_entry(@root)

  def sprockets = ENGINE.const_get(:SprocketsAssets)

  def engine_directories = %w[app/javascript vendor/javascript].map { |dir| ENGINE.root.join(dir) }

  def context(gems = {}, manifest: nil)
    if manifest
      FileUtils.mkdir_p(@root.join(Generators::SprocketsManifest::PATH).dirname)
      File.write(@root.join(Generators::SprocketsManifest::PATH), manifest)
    end
    Context.new(root: @root, gems: gems.transform_values { |version| Gem::Version.new(version) })
  end

  def test_the_gems_controllers_primitives_and_vendored_files_are_declared
    paths = sprockets.logical_paths(engine_directories)

    assert_includes paths, "controllers/shadcn/dialog_controller.js"
    assert_includes paths, "shadcn/primitives/presence.js"
    assert_includes paths, "@floating-ui--dom.js"
    assert_equal paths.sort, paths
  end

  def test_every_importmap_pin_of_the_gem_is_declared
    declared = sprockets.logical_paths(engine_directories)
    pinned = File.read(ENGINE.root.join("config/importmap.rb")).scan(/to: "([^"]+)"/).flatten

    assert_empty pinned - declared
  end

  def test_install_appends_once_to_a_sprockets_precompile_list
    options = Options.new([ "manifest.js" ])

    assert_equal :declared, sprockets.install(options, directories: engine_directories)
    size = options.precompile.size

    assert_includes options.precompile, "controllers/shadcn/dialog_controller.js"
    assert_equal :declared, sprockets.install(options, directories: engine_directories)
    assert_equal size, options.precompile.size
  end

  def test_install_leaves_propshaft_options_alone
    assert_equal :skipped, sprockets.install(Options.new(nil), directories: engine_directories)
    assert_equal :skipped, sprockets.install(Object.new, directories: engine_directories)
    assert_equal :skipped, sprockets.install(ActiveSupport::OrderedOptions.new, directories: engine_directories)
  end

  def test_the_engine_does_not_declare_anything_in_the_propshaft_application
    refute_includes EngineTest::Application.config.assets.precompile.to_a, "controllers/shadcn/dialog_controller.js"
  end

  # Sprockets' `config.assets` is an options object without excluded_paths: reading it answers nil, and the initializer used to crash on it.
  def test_the_tailwind_input_exclusion_is_skipped_without_excluded_paths
    app = Struct.new(:config).new(Struct.new(:assets).new(ActiveSupport::OrderedOptions.new))
    initializer = ENGINE.initializers.find { |candidate| candidate.name == "phlex_shadcn.exclude_tailwind_inputs" }

    initializer.bind(ENGINE.instance).run(app)

    assert_nil app.config.assets.excluded_paths
  end

  def test_the_doctor_names_propshaft
    result = Check.call(context({ "propshaft" => "1.3.0" }))

    assert_equal :pass, result.status
    assert_includes result.message, "Propshaft 1.3.0"
  end

  def test_the_doctor_names_sprockets_and_accepts_a_manifest_linking_the_builds
    result = Check.call(context({ "sprockets-rails" => "3.5.2" }, manifest: "//= link_tree ../images\n//= link_tree ../builds\n"))

    assert_equal :pass, result.status
    assert_includes result.message, "Sprockets (sprockets-rails 3.5.2)"
  end

  def test_the_doctor_accepts_a_manifest_that_links_the_tailwind_css_directly
    assert_equal :pass, Check.call(context({ "sprockets-rails" => "3.5.2" }, manifest: "//= link tailwind.css\n")).status
  end

  def test_the_doctor_warns_about_a_sprockets_manifest_without_the_builds
    result = Check.call(context({ "sprockets-rails" => "3.5.2" }, manifest: "//= link_tree ../images\n"))

    assert_equal :warn, result.status
    assert_includes result.fix, "link_tree ../builds"
  end

  def test_the_doctor_warns_about_a_missing_sprockets_manifest
    result = Check.call(context({ "sprockets-rails" => "3.5.2" }))

    assert_equal :warn, result.status
    assert_includes result.message, "not found"
  end

  def test_the_doctor_warns_about_two_pipelines_and_about_none
    both = Check.call(context({ "propshaft" => "1.3.0", "sprockets-rails" => "3.5.2" }))
    none = Check.call(context)

    assert_equal :warn, both.status
    assert_includes both.message, "both"
    assert_equal :warn, none.status
    assert_includes none.message, "neither"
  end
end
