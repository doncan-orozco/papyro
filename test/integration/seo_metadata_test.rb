require "test_helper"
require "securerandom"
require "base64"

class SeoMetadataTest < ActionDispatch::IntegrationTest
  def assert_default_social_metadata(locale: I18n.default_locale)
    assert_includes response.body, "<title>#{ERB::Util.html_escape(I18n.t('seo.default_title', locale: locale))}</title>"
    assert_includes response.body, "<meta name=\"description\" content=\"#{ERB::Util.html_escape(I18n.t('seo.default_description', locale: locale))}\">"
    assert_includes response.body, "<meta property=\"og:title\" content=\"#{ERB::Util.html_escape(I18n.t('seo.default_title', locale: locale))}\">"
    assert_includes response.body, "<meta property=\"og:description\" content=\"#{ERB::Util.html_escape(I18n.t('seo.default_description', locale: locale))}\">"
    assert_select "meta[property='og:image'][content='http://www.example.com/icon-512.png']", 1
    assert_select "meta[name='twitter:card'][content='summary_large_image']", 1
    assert_includes response.body, "<meta property=\"og:locale\" content=\"#{locale == :en ? 'en_US' : 'es_ES'}\">"
    assert_equal I18n.available_locales.size - 1, response.body.scan(/<meta property=\"og:locale:alternate\"/).size
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

  test "localized home pages keep metadata aligned with current locale" do
    get root_path(locale: :en)

    assert_response :success
    assert_select "meta[name='description'][content='Read curated long-form articles and ideas.']", 1
    assert_select "meta[property='og:locale'][content='en_US']", 1
    assert_select "meta[property='og:locale:alternate'][content='es_ES']", 1
    assert_select "meta[property='og:locale:alternate'][content='en_US']", 0
    assert_select "link[rel='canonical'][href='#{root_url(locale: :en)}']", 1

    get root_path(locale: :es)

    assert_response :success
    assert_select "meta[name='description'][content='Lee artículos e ideas seleccionadas en formato largo.']", 1
    assert_select "meta[property='og:locale'][content='es_ES']", 1
    assert_select "meta[property='og:locale:alternate'][content='en_US']", 1
    assert_select "meta[property='og:locale:alternate'][content='es_ES']", 0
    assert_select "link[rel='canonical'][href='#{root_url(locale: :es)}']", 1
  end

  test "localized root renders canonical and hreflang tags for the article index" do
    get root_path(locale: :en)

    assert_response :success
    assert_select "link[rel='canonical'][href='#{root_url(locale: :en)}']", 1
    assert_select "link[rel='alternate'][hreflang='en'][href='#{root_url(locale: :en)}']", 1
    assert_select "link[rel='alternate'][hreflang='es'][href='#{root_url(locale: :es)}']", 1
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
    assert_select "meta[name='robots'][content='noindex,follow']", 1
    assert_includes response.body, I18n.t("articles.show.translation_fallback_notice", locale: :es,
                                                                                       original_language: I18n.t("language.name", locale: :en))
    assert_select "title", text: /#{Regexp.escape(article.title)} \| Papyro/
    assert_select "meta[property='og:title'][content='#{article.title} | Papyro']", 1
    assert_select "meta[property='og:locale'][content='es_ES']", 1
  end

  test "renders JSON-LD structured data for articles" do
    article = articles(:published_article)

    get article_path(article, locale: :en)

    assert_response :success
    assert_includes response.body, "@context"
    assert_includes response.body, "https://schema.org"
    assert_includes response.body, article.title
  end

  test "article page uses cover image as og:image when available" do
    article = articles(:published_article)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=")),
      filename: "cover.png",
      content_type: "image/png"
    )
    ActiveStorage::Attachment.create!(
      name: "cover_image",
      record: article,
      blob: blob
    )

    get article_path(article, locale: :en)

    assert_response :success
    assert_select "meta[property='og:image']", 1
    assert_select "meta[name='twitter:card'][content='summary_large_image']", 1
    og_image = css_select("meta[property='og:image']").first["content"]

    assert_includes og_image, "/rails/active_storage/"
  end

  test "renders correct hreflang and canonical tags" do
    article = articles(:published_article)

    get article_path(article, locale: :es)

    assert_select "link[rel='canonical'][href='#{article_url(article, locale: :es)}']"
    assert_select "link[rel='alternate'][hreflang='en'][href='#{article_url(article, locale: :en)}']"
    assert_select "link[rel='alternate'][hreflang='es'][href='#{article_url(article, locale: :es)}']"
    assert_select "link[rel='alternate'][hreflang='x-default'][href='http://www.example.com/']"
  end

  test "article show metadata uses translated slugs and excerpt without duplicate json-ld" do
    user = users(:admin)
    article = Article.create!(
      title: "Tech Horizons",
      slug: "tech-horizons-#{SecureRandom.hex(4)}",
      excerpt: "English excerpt for SEO",
      body: "<p>English content</p>",
      user: user
    )
    publish_article!(article)

    I18n.with_locale(:es) do
      article.update!(
        title: "Horizontes Tecnologicos",
        slug: "horizontes-tecnologicos-#{SecureRandom.hex(4)}",
        excerpt: "Resumen en espanol para SEO",
        body: "<p>Contenido en espanol</p>"
      )
    end
    article.translations.find_by!(locale: "es").update!(status: :published, published_at: Time.current)

    en_slug = Mobility.with_locale(:en) { article.slug }
    es_slug = Mobility.with_locale(:es) { article.slug }
    en_url = article_url(en_slug, locale: :en)
    es_url = article_url(es_slug, locale: :es)

    get article_path(article, locale: :en)

    assert_response :success
    assert_select "meta[name='description'][content='English excerpt for SEO']", 1
    assert_select "link[rel='canonical'][href='#{en_url}']", 1
    assert_select "link[rel='alternate'][hreflang='es'][href='#{es_url}']", 1
    assert_equal 1, response.body.scan(/<script[^>]*type="application\/ld\+json"/).size
    assert_select "meta[name='robots'][content='noindex,follow']", 0

    get article_path(article, locale: :es)

    assert_response :success
    assert_select "meta[name='description'][content='Resumen en espanol para SEO']", 1
    assert_select "link[rel='canonical'][href='#{es_url}']", 1
    assert_select "link[rel='alternate'][hreflang='en'][href='#{en_url}']", 1
    assert_equal 1, response.body.scan(/<script[^>]*type="application\/ld\+json"/).size
    assert_select "meta[name='robots'][content='noindex,follow']", 0
  end

  test "article page uses locale-specific generated og image when no cover image" do
    article = articles(:published_article)

    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=")),
      filename: "og-en.png",
      content_type: "image/png"
    )
    ActiveStorage::Attachment.create!(
      name: "generated_og_images",
      record: article,
      blob: blob
    )

    get article_path(article, locale: :en)

    assert_response :success
    assert_select "meta[property='og:image']", 1
    og_image = css_select("meta[property='og:image']").first["content"]

    assert_includes og_image, "/rails/active_storage/"
    assert_includes og_image, "og-en.png"
  end

  test "article page uses default og:image when no cover or locale-specific og image exists" do
    article = Article.create!(
      title: "No Image Article",
      slug: "no-image-#{SecureRandom.hex(4)}",
      excerpt: "No images here",
      body: "<p>Just text</p>",
      user: users(:admin)
    )
    publish_article!(article)

    get article_path(article, locale: :en)

    assert_response :success
    assert_select "meta[property='og:image']", 1
    og_image = css_select("meta[property='og:image']").first["content"]

    assert_equal "http://www.example.com/icon-512.png", og_image
  end
end
