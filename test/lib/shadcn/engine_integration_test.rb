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
end
