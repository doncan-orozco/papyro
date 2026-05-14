require "test_helper"

class ArticleLocaleVisibilityTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
  end

  test "published article with published original translation is visible" do
    article = Article.create!(
      title: "Test Article",
      slug: "test-visibility-#{SecureRandom.hex(4)}",
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    )
    publish_article!(article)

    assert_predicate article, :published?
    assert_includes Articles::Query::Published.call, article
  end

  test "original locale determines publication status" do
    article = Article.create!(
      title: "Test Article",
      slug: "test-original-locale-#{SecureRandom.hex(4)}",
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    )
    publish_article!(article)

    assert_predicate article, :published?
  end

  test "publish operation marks original translation as published" do
    article = Article.create!(
      title: "Test Article",
      slug: "test-backward-compat-#{SecureRandom.hex(4)}",
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    )

    publish_article!(article)

    original_translation = article.article_translations.find_by(locale: article.original_locale)

    assert_predicate original_translation, :published?
    assert_predicate article, :published?
  end
end
