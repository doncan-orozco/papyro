require "test_helper"
require "rake"

class PhlexShadcnEngineIntegrationTest < ActiveSupport::TestCase
  test "application.css imports the phlex-shadcn engine bundle" do
    css = Rails.root.join("app/assets/tailwind/application.css").read

    assert_includes css, "/* phlex-shadcn:start"
    assert_includes css, "/* phlex-shadcn:end */"
    assert_includes css, '@import "../builds/tailwind/phlex-shadcn";'
    assert_includes css, '@import "./theme/legacy-compat.css";'
    assert_includes css, '@import "./domains/articles/reader.css";'
  end

  test "application.css no longer carries duplicated vendor or token imports" do
    css = Rails.root.join("app/assets/tailwind/application.css").read

    assert_not_includes css, "./vendor/"
    assert_not_includes css, "./theme/tokens.css"
  end

  test "importmap packages come from the engine pins" do
    imports = JSON.parse(Rails.application.importmap.to_json(resolver: ActionController::Base.helpers))["imports"]

    assert imports.key?("@floating-ui/dom")
    assert imports.key?("controllers/shadcn/dialog_controller")
    assert imports.key?("shadcn/primitives/portal")
  end

  test "the engine vendored floating-ui is served by the asset pipeline" do
    assert_not_nil Rails.application.assets.load_path.find("@floating-ui--dom.js")
  end

  test "the engine javascript directory is on the asset paths exactly once" do
    gem_js = Phlex::Shadcn::Engine.root.join("app/javascript").to_s
    paths = Rails.application.config.assets.paths.map(&:to_s)

    assert_equal 1, paths.count(gem_js)
  end

  test "the theme directory is the app's app/assets/tailwind/theme" do
    assert_equal Rails.root.join("app/assets/tailwind/theme").to_s, Phlex::Shadcn::Theme.dir.to_s
  end

  test "the app theme is valid and ships the zinc and slate presets" do
    result = Phlex::Shadcn::Theme.check

    assert_empty result[:errors]
    assert_includes Phlex::Shadcn::Theme.presets, "zinc"
    assert_includes Phlex::Shadcn::Theme.presets, "slate"
  end

  test "theme tasks come from the gem only" do
    Rails.application.load_tasks unless Rake::Task.task_defined?("theme:check")

    %w[list use import check].each do |name|
      assert Rake::Task.task_defined?("theme:#{name}"), "theme:#{name}"
      assert Rake::Task.task_defined?("phlex_shadcn:theme:#{name}"), "phlex_shadcn:theme:#{name}"
    end
    assert_equal 1, Rake::Task["theme:check"].actions.size
  end

  test "host Ruby does not reach into the gem's internals or repo paths" do
    internals = /Phlex::Shadcn::(Engine|Loader|Generators)|gems\/phlex-shadcn\/(app|lib|vendor|config)/
    offenders = Dir[Rails.root.join("{app,lib,config}/**/*.rb")].select { |file| File.read(file).match?(internals) }
    offenders += Dir[Rails.root.join("app/**/*.rb")].select { |file| File.read(file).include?("gems/phlex-shadcn/") }

    assert_empty offenders.uniq
  end
end
