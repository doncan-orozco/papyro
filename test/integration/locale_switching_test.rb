require "test_helper"

class LocaleSwitchingTest < ActionDispatch::IntegrationTest
  test "uses explicit locale param and propagates it through the public navbar" do
    get root_path(locale: :es)

    assert_response :success
    assert_select "html[lang='es']"
    assert_select "a[href='#{new_session_path}']", text: "Iniciar sesion"
  end

  test "persists selected locale in session across requests" do
    get root_path(locale: :es)

    get root_path

    assert_response :success
    assert_select "html[lang='es']"
    assert_select "a[href='#{new_session_path}']", text: "Iniciar sesion"
  end

  test "localized path takes precedence over browser locale" do
    get root_path, headers: { "HTTP_ACCEPT_LANGUAGE" => "es-MX,es;q=0.9,en;q=0.8" }

    assert_response :success
    assert_select "html[lang='en']"
  end

  test "returns not found for unsupported locale path" do
    get "/fr"

    assert_response :not_found
  end

  test "renders authenticated article management in the selected locale" do
    sign_in_as(users(:admin))

    # Studio routes are NOT localized — URL stays /studio/articles regardless of locale.
    # The UI language changes, but the path does not.
    get studio_articles_path

    assert_response :success
    assert_select "html[lang='en']"
  end

  test "language toggle keeps same public article route when switching locale" do
    article = articles(:published_article)

    get article_path(article, locale: :es)

    assert_response :success
    assert_includes response.body, "href=\"#{article_path(article, locale: :en)}\""
  end

  test "language toggle keeps same studio route and switches locale via query param" do
    sign_in_as(users(:admin))

    get studio_articles_path(locale: :es)

    assert_response :success
    assert_select "html[lang='es']"
    assert_includes response.body, "href=\"#{studio_articles_path(locale: :en)}\""
    assert_includes response.body, "href=\"#{studio_articles_path(locale: :es)}\""
  end

  test "redirects root to localized path based on browser locale" do
    get "/", headers: { "HTTP_ACCEPT_LANGUAGE" => "es-MX,es;q=0.9,en;q=0.8" }

    assert_redirected_to root_path(locale: :es)
  end

  test "redirects root to localized path based on cookie" do
    cookies[:papyro_locale] = :en

    get "/"

    assert_redirected_to root_path(locale: :en)
  end

  test "persists locale in cookie after switching" do
    get root_path(locale: :es)

    assert_equal "es", cookies[:papyro_locale]
  end
end
