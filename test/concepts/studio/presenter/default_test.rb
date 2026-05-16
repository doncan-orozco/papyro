require "test_helper"

class Studio::Presenter::DefaultTest < ActiveSupport::TestCase
  setup do
    @article = articles(:draft_article)
    @article.article_translations.find_or_create_by!(locale: "es") do |translation|
      translation.title = "Titulo del borrador"
      translation.slug = "draft-article-es-#{SecureRandom.hex(3)}"
      translation.status = :draft
    end
  end

  test "wrap builds presenter collection with ui locale context" do
    presenters = Studio::Presenter::Default.wrap([ @article ], ui_locale: :es)

    assert_equal 1, presenters.length
    assert_equal "es", presenters.first.ui_locale
  end

  test "preferred content locale uses ui locale when translation exists" do
    presenter = Studio::Presenter::Default.new(@article, ui_locale: :es)

    assert_equal "es", presenter.preferred_content_locale
  end

  test "preferred content locale falls back to original locale" do
    presenter = Studio::Presenter::Default.new(@article, ui_locale: :fr)

    assert_equal @article.original_locale, presenter.preferred_content_locale
  end

  test "content locale param returns empty hash for baseline locale" do
    presenter = Studio::Presenter::Default.new(@article, ui_locale: :en)

    assert_equal({}, presenter.content_locale_param(:en))
  end

  test "content locale param includes non-baseline locale" do
    presenter = Studio::Presenter::Default.new(@article, ui_locale: :es)

    assert_equal({ content_locale: "es" }, presenter.content_locale_param(:es))
  end

  test "display title prefers translated title in ui locale" do
    presenter = Studio::Presenter::Default.new(@article, ui_locale: :es)

    assert_equal "Titulo del borrador", presenter.display_title
  end

  test "display title falls back to original locale translation" do
    presenter = Studio::Presenter::Default.new(@article, ui_locale: :fr)

    assert_equal "Draft Article", presenter.display_title
  end

  test "status and publication labels reflect article state" do
    draft = Studio::Presenter::Default.new(@article)
    published = Studio::Presenter::Default.new(articles(:published_article))

    assert_equal :secondary, draft.status_variant
    assert_equal I18n.t("studio.articles.index.not_published"), draft.published_at_label

    assert_equal :default, published.status_variant
    assert_equal I18n.l(articles(:published_article).published_at, format: :short), published.published_at_label
  end

  test "sorted translations keeps original locale first" do
    presenter = Studio::Presenter::Default.new(@article)

    sorted_locales = presenter.sorted_translations.map { |translation| translation.locale.to_s }

    assert_equal @article.original_locale, sorted_locales.first
  end

  test "locale published checks original locale against article state" do
    article = articles(:published_article)
    presenter = Studio::Presenter::Default.new(article)
    original_translation = article.article_translations.find_by!(locale: article.original_locale)

    assert presenter.locale_published?(original_translation)
  end

  test "locale published checks non-original locales against translation state" do
    article = articles(:published_article)
    translation = article.article_translations.find_or_create_by!(locale: "es") do |item|
      item.title = "Publicada ES"
      item.slug = "published-article-es-#{SecureRandom.hex(3)}"
      item.status = :draft
    end

    presenter = Studio::Presenter::Default.new(article)

    assert_not presenter.locale_published?(translation)

    translation.update!(status: :published, published_at: Time.current)

    assert presenter.locale_published?(translation)
  end

  test "public view path uses article original locale" do
    article = nil

    I18n.with_locale(:es) do
      article = Article.create!(
        title: "Articulo original",
        slug: "articulo-original-#{SecureRandom.hex(3)}",
        body: "<p>Contenido</p>",
        excerpt: "Resumen",
        original_locale: "es",
        user: users(:admin)
      )
    end

    presenter = Studio::Presenter::Default.new(article, ui_locale: :en)

    expected_path = Rails.application.routes.url_helpers.article_path(article, locale: :es)

    assert_equal expected_path, presenter.public_view_path
  end
end
