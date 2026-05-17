require "test_helper"
require "securerandom"

module Articles
  class PublishedBySlugTest < ActiveSupport::TestCase
    test "filters by slug and locale" do
      user = users(:admin)

      article = Article.create!(
        title: "English Title",
        slug: "english-title-#{SecureRandom.hex(3)}",
        published_at: Time.current,
        body: "Body",
        user: user
      )

      I18n.with_locale(:es) do
        article.update!(title: "Titulo ES", slug: "titulo-es-#{SecureRandom.hex(3)}")
      end
      article.article_translations.find_by!(locale: "en").update!(status: :published, published_at: article.published_at)
      article.article_translations.find_by!(locale: "es").update!(status: :published, published_at: article.published_at)

      english_slug = article.article_translations.find_by!(locale: "en").slug
      spanish_slug = article.article_translations.find_by!(locale: "es").slug

      english_result = Query::PublishedBySlug.call({ slug: english_slug, locale: "en" })
      spanish_result = Query::PublishedBySlug.call({ slug: spanish_slug, locale: "es" })

      assert_includes english_result, article
      assert_includes spanish_result, article
    end

    test "returns none when slug is blank" do
      assert_empty Query::PublishedBySlug.call({ slug: "" })
      assert_empty Query::PublishedBySlug.call
    end
  end
end
