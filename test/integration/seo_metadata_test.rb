require "test_helper"

class SeoMetadataTest < ActionDispatch::IntegrationTest
  def assert_default_social_metadata(locale: I18n.default_locale)
    assert_includes response.body, "<title>#{ERB::Util.html_escape(I18n.t('seo.default_title', locale: locale))}</title>"
    assert_includes response.body, "<meta name=\"description\" content=\"#{ERB::Util.html_escape(I18n.t('seo.default_description', locale: locale))}\">"
    assert_includes response.body, "<meta property=\"og:title\" content=\"#{ERB::Util.html_escape(I18n.t('seo.default_title', locale: locale))}\">"
    assert_includes response.body, "<meta property=\"og:description\" content=\"#{ERB::Util.html_escape(I18n.t('seo.default_description', locale: locale))}\">"
    assert_includes response.body, "<meta property=\"og:locale\" content=\"#{locale == :en ? 'en_US' : 'es_ES'}\">"
    assert_equal I18n.available_locales.size, response.body.scan(/<meta property=\"og:locale:alternate\"/).size
  end

  test "home renders canonical and hreflang tags" do
    get root_path

    assert_select "link[rel='canonical']", 1
    assert_select "link[rel='alternate'][hreflang='en']", 1
    assert_select "link[rel='alternate'][hreflang='es']", 1
    assert_select "link[rel='alternate'][hreflang='x-default']", 1
  end

  test "home renders seo meta tags" do
    get root_path

    assert_default_social_metadata(locale: :en)
  end

  test "articles index renders canonical and hreflang tags" do
    get articles_path(locale: :en)

    assert_response :success
    assert_select "link[rel='canonical'][href='#{articles_url(locale: :en)}']", 1
    assert_select "link[rel='alternate'][hreflang='en'][href='#{articles_url(locale: :en)}']", 1
    assert_select "link[rel='alternate'][hreflang='es'][href='#{articles_url(locale: :es)}']", 1
    assert_select "link[rel='alternate'][hreflang='x-default'][href='http://www.example.com/']", 1
    assert_default_social_metadata(locale: :en)
  end

  test "article page canonical and hreflang point to localized article URLs" do
    article = articles(:published_article)

    get article_path(article, locale: :es)

    assert_response :success
    assert_select "link[rel='canonical'][href='#{article_url(article, locale: :es)}']", 1
    assert_select "link[rel='alternate'][hreflang='en'][href='#{article_url(article, locale: :en)}']", 1
    assert_select "link[rel='alternate'][hreflang='es'][href='#{article_url(article, locale: :es)}']", 1
    assert_select "link[rel='alternate'][hreflang='x-default'][href='http://www.example.com/']", 1
    assert_default_social_metadata(locale: :es)
  end

  test "author show page renders seo meta tags" do
    user = users(:one)
    profile = author_profiles(:one)

    get "/@#{profile.username}"

    assert_response :success
    assert_includes response.body, profile.display_name
  end
end
