# frozen_string_literal: true

require "stringio"
require_relative "engine_helper"

# tailwindcss-rails writes `app/assets/builds/tailwind/<engine>.css`, a stub whose absolute `@import` only the Tailwind CLI can resolve.
# That directory is inside the host's own `app/assets/builds` root, so `stylesheet_link_tag :app` would link it and the browser would 404
# on the import (and the stub would disclose the gem's filesystem path). It is Tailwind input, never a browser stylesheet.
class EngineTest::StubCss < Minitest::Test
  BUILDS = EngineTest::ROOT.join("app/assets/builds")

  def setup
    FileUtils.rm_rf(BUILDS)
    FileUtils.mkdir_p(BUILDS.join("tailwind"))
    File.write(BUILDS.join("tailwind.css"), "/* compiled */")
    File.write(BUILDS.join("tailwind/phlex-shadcn.css"), %(@import "/abs/engine.css";))
    File.write(BUILDS.join("tailwind/other-engine.css"), %(@import "/abs/other.css";))
    File.write(BUILDS.join("application.css"), "/* app */")
  end

  def teardown = FileUtils.rm_rf(BUILDS)

  def load_path
    Propshaft::LoadPath.new([ BUILDS ], compilers: EngineTest::Application.assets.load_path.compilers)
  end

  def test_the_filter_hooks_a_method_this_propshaft_still_defines
    assert Propshaft::LoadPath.private_method_defined?(:without_dotfiles),
           "Propshaft renamed LoadPath#without_dotfiles: move TailwindStubFilter to the new hook"
    assert(Propshaft::LoadPath.ancestors.any? { |mod| mod.name == "Phlex::Shadcn::Engine::TailwindStubFilter" })
  end

  def test_propshafts_own_dotfile_filter_still_runs
    File.write(BUILDS.join(".keep"), "")

    assert_nil load_path.find(".keep")
  end

  def test_the_compiled_application_css_is_still_served
    assert load_path.find("tailwind.css")
    assert load_path.find("application.css")
  end

  def test_the_engine_stub_is_not_among_the_served_assets
    assert_nil load_path.find("tailwind/phlex-shadcn.css")
    assert_nil load_path.find("tailwind/other-engine.css")
    refute_includes load_path.assets.map { |asset| asset.logical_path.to_s }, "tailwind/phlex-shadcn.css"
  end

  def test_stylesheet_link_tag_app_does_not_list_the_stub
    css = load_path.asset_paths_by_glob("#{EngineTest::ROOT.join('app/assets')}/**/*.css")

    assert_equal %w[application.css tailwind.css], css
  end

  def test_stylesheet_link_tag_all_does_not_list_the_stub
    assert_equal %w[application.css tailwind.css], load_path.asset_paths_by_type("css")
  end

  def test_other_files_in_a_tailwind_directory_outside_the_builds_are_untouched
    elsewhere = EngineTest::ROOT.join("vendor/assets")
    FileUtils.mkdir_p(elsewhere.join("tailwind"))
    File.write(elsewhere.join("tailwind/keep.css"), "x")
    paths = Propshaft::LoadPath.new([ elsewhere ], compilers: EngineTest::Application.assets.load_path.compilers)

    assert paths.find("tailwind/keep.css")
  ensure
    FileUtils.rm_rf(elsewhere)
  end

  # TailwindStubFilter.install is the seam of the recorded ruby-gem-conventions R4 exception: the initializer calls it with
  # `config.phlex_shadcn.hide_tailwind_stubs`, and it prepends nothing unless the private one-argument hook is really there.
  def test_install_is_a_no_op_when_disabled
    target = fake_target

    assert_equal :disabled, install(target, enabled: false)
    refute_includes target.ancestors, filter
  end

  def test_install_warns_and_skips_a_target_without_the_hook
    target = fake_target(hook: :none)
    io = StringIO.new

    assert_equal :unsupported, install(target, logger: Logger.new(io))
    refute_includes target.ancestors, filter
    assert_match "hide_tailwind_stubs", io.string
    assert_match "tailwind", io.string
  end

  def test_install_warns_and_skips_a_hook_with_another_arity
    target = fake_target(hook: :two_arguments)
    io = StringIO.new

    assert_equal :unsupported, install(target, logger: Logger.new(io))
    refute_includes target.ancestors, filter
  end

  def test_install_prepends_once
    target = fake_target

    2.times { assert_equal :installed, install(target) }
    assert_equal 1, target.ancestors.count(filter)
  end

  def test_an_installed_fake_target_hides_only_the_stubs
    target = fake_target
    install(target)
    stub = BUILDS.join("tailwind/phlex-shadcn.css").to_s
    compiled = BUILDS.join("tailwind.css").to_s

    assert_equal [ compiled ], target.new.send(:without_dotfiles, [ stub, compiled ])
  end

  private

  def filter = Phlex::Shadcn::Engine.const_get(:TailwindStubFilter)

  def install(target, enabled: true, logger: Logger.new(IO::NULL))
    filter.install(target, stubs_dir: BUILDS.join("tailwind"), enabled: enabled, logger: logger)
  end

  # A stand-in for Propshaft::LoadPath: `hook: true` has the private one-argument filter, `:two_arguments` a filter with another
  # signature, `:none` no filter at all.
  def fake_target(hook: true)
    Class.new.tap do |target|
      case hook
      when true then target.define_method(:without_dotfiles) { |files| files }
      when :two_arguments then target.define_method(:without_dotfiles) { |files, more| files + more }
      end
      target.class_eval { private :without_dotfiles } unless hook == :none
    end
  end
end
