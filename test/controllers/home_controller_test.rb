require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "index is accessible without authentication" do
    get root_path

    assert_response :success
  end

  test "unlocalized root path renders home" do
    get "/"

    assert_response :success
    assert_includes response.body, I18n.t("pages.home.index.hero.eyebrow", locale: I18n.default_locale)
  end

  test "unlocalized root remains x-default even after selecting another locale" do
    get "/es"
    assert_response :success
    assert_includes response.body, I18n.t("pages.home.index.hero.eyebrow", locale: :es)

    get "/"

    assert_response :success
    assert_includes response.body, I18n.t("pages.home.index.hero.eyebrow", locale: I18n.default_locale)
  end

  test "home includes localized hreflang cluster and x-default root" do
    get "/en"

    assert_response :success
    assert_includes response.body, 'rel="alternate" hreflang="en"'
    assert_includes response.body, 'rel="alternate" hreflang="es"'
    assert_match(%r{rel="alternate" hreflang="en" href="http://www\.example\.com/en/?"}, response.body)
    assert_match(%r{rel="alternate" hreflang="es" href="http://www\.example\.com/es/?"}, response.body)
    assert_match(%r{rel="alternate" hreflang="x-default" href="http://www\.example\.com/"}, response.body)
  end

  test "localized pages are self-canonical" do
    get "/en"

    assert_response :success
    assert_match(%r{<link rel="canonical" href="http://www\.example\.com/en/?"}, response.body)

    get "/es"

    assert_response :success
    assert_match(%r{<link rel="canonical" href="http://www\.example\.com/es/?"}, response.body)
  end
end
