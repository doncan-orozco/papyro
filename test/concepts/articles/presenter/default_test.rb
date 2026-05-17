require "test_helper"

class Articles::DefaultPresenterTest < ActiveSupport::TestCase
  test "delegates wrapped article attributes" do
    article = build_article(title: "Delegated Title", slug: "delegated-title", excerpt: "Delegated excerpt", body: "Hello world")
    presenter = Articles::Presenter::Default.new(article)

    assert_presenter_delegates(presenter, :title, :excerpt)
  end

  test "translation_fallback? compares against original_locale" do
    article = build_article(title: "Hola", slug: "hola", excerpt: "Resumen", body: "Contenido", locale: :es)
    presenter = Articles::Presenter::Default.new(article, locale: :fr)

    assert_predicate presenter, :translation_fallback?
  end

  test "translation_fallback? is false in original locale" do
    article = build_article(title: "Hola", slug: "hola-orig", excerpt: "Resumen", body: "Contenido", locale: :es)
    article.update_column(:original_locale, "es")
    presenter = Articles::Presenter::Default.new(article, locale: :es)

    assert_not presenter.translation_fallback?
  end

  test "wrap builds presenters for collections" do
    articles = [ articles(:draft_article), articles(:published_article) ]
    presenters = assert_wraps_collection(Articles::Presenter::Default, articles, locale: :es)

    assert presenters.all?(&:translation_fallback?)
  end

  private

  def build_article(title:, slug:, excerpt:, body:, locale: :en)
    article = nil

    I18n.with_locale(locale) do
      article = Article.create!(
        title: title,
        slug: "#{slug}-#{SecureRandom.hex(4)}",
        excerpt: excerpt,
        body: body,
        user: users(:admin)
      )
    end

    article
  end
end
