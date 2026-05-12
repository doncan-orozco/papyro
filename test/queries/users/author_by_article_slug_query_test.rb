require "test_helper"

module Users
  class AuthorByArticleSlugQueryTest < ActiveSupport::TestCase
    test "returns the article author for a translation slug" do
      article = articles(:published_article)
      slug = article.article_translations.find_by(locale: article.original_locale)&.slug

      result = AuthorByArticleSlugQuery.call(slug: slug)

      assert_includes result, article.user
    end

    test "returns none for blank slug" do
      assert_empty AuthorByArticleSlugQuery.call(slug: "")
      assert_empty AuthorByArticleSlugQuery.call
    end
  end
end
