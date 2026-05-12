require "test_helper"

class ArticleLocaleVisibilityTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
  end

  test "published article with published original translation is visible" do
    article = Article.create!(
      title: "Test Article",
      slug: "test-visibility-#{SecureRandom.hex(4)}",
      status: :published,
      published_at: Time.current,
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    )

    # Ensure original translation is published
    original_translation = article.article_translations.find_by(locale: article.original_locale)
    original_translation.update!(status: :published, published_at: Time.current)

    assert_predicate article, :published?
    assert_includes Articles::PublishedQuery.call, article
  end

  test "original locale determines publication status" do
    article = Article.create!(
      title: "Test Article",
      slug: "test-original-locale-#{SecureRandom.hex(4)}",
      status: :published,
      published_at: Time.current,
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    )

    # Get original locale translation and verify it exists
    original_translation = article.article_translations.find_by(locale: article.original_locale)

    assert_not_nil original_translation

    # Update it to published
    original_translation.update!(status: :published, published_at: Time.current)

    # Now article should be published
    assert_predicate article, :published?
  end

  test "status=published marks original translation as published" do
    article = Article.create!(
      title: "Test Article",
      slug: "test-backward-compat-#{SecureRandom.hex(4)}",
      status: :published,
      published_at: Time.current,
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    )

    # Original translation should now be published via status sync.
    original_translation = article.article_translations.find_by(locale: article.original_locale)

    assert_predicate original_translation, :status_published?

    assert_predicate article, :published?
  end
end
