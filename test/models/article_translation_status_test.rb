require "test_helper"

class ArticleTranslationStatusTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @article = Article.create!(
      title: "Test Article",
      slug: "test-translation-status-#{SecureRandom.hex(4)}",
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    )
    @translation = @article.article_translations.find_by(locale: @article.original_locale)
  end

  test "translation starts in draft status" do
    assert_predicate @translation, :status_draft?
    assert_equal "draft", @translation.status
  end

  test "translation status transitions to published" do
    @translation.update!(status: :published, published_at: Time.current)
    @translation.reload

    assert_predicate @translation, :status_published?
    assert_equal "published", @translation.status
    assert_not_nil @translation.published_at
  end

  test "translation status transitions to in_review" do
    @translation.update!(status: :in_review)
    @translation.reload

    assert_predicate @translation, :status_in_review?
    assert_equal "in_review", @translation.status
  end

  test "scopes work correctly" do
    draft1 = @translation
    draft2 = Article.create!(
      title: "Another Article",
      slug: "another-#{SecureRandom.hex(4)}",
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    ).article_translations.first

    published = Article.create!(
      title: "Published Article",
      slug: "published-#{SecureRandom.hex(4)}",
      published_at: Time.current,
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    ).article_translations.first
    published.update!(status: :published, published_at: Time.current)

    in_review = Article.create!(
      title: "In Review Article",
      slug: "review-#{SecureRandom.hex(4)}",
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    ).article_translations.first
    in_review.update!(status: :in_review)

    assert_includes ArticleTranslation.published, published
    assert_not_includes ArticleTranslation.published, draft1
    assert_not_includes ArticleTranslation.published, in_review

    assert_includes ArticleTranslation.drafted, draft1
    assert_includes ArticleTranslation.drafted, draft2
    assert_not_includes ArticleTranslation.drafted, published

    assert_includes ArticleTranslation.in_review, in_review
    assert_not_includes ArticleTranslation.in_review, published
  end

  test "published_translations legacy scope works" do
    published = @article.article_translations.first
    published.update!(status: :published, published_at: Time.current)

    # Legacy scope should still work
    assert_includes ArticleTranslation.published_translations, published
  end
end
