require "test_helper"

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
end
