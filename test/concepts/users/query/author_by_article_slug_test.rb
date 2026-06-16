require "test_helper"

module Users
  class AuthorByArticleSlugTest < ActiveSupport::TestCase
    test "returns the article author for a translation slug" do
      article = articles(:published_article)
      slug = article.translations.find_by(locale: article.original_locale)&.slug

      result = Query::AuthorByArticleSlug.call({ slug: slug })

      assert_includes result, article.user
    end

    test "returns none for blank slug" do
      assert_empty Query::AuthorByArticleSlug.call({ slug: "" })
      assert_empty Query::AuthorByArticleSlug.call
    end
  end
end
