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
    @translation = @article.translations.find_by(locale: @article.original_locale)
  end

  test "translation starts in draft status" do
    assert_predicate @translation, :draft?
    assert_equal "draft", @translation.status
  end

  test "translation status transitions to published" do
    @translation.update!(status: :published, published_at: Time.current)
    @translation.reload

    assert_predicate @translation, :published?
    assert_equal "published", @translation.status
    assert_not_nil @translation.published_at
  end

  test "translation status transitions to in_review" do
    @translation.update!(status: :in_review)
    @translation.reload

    assert_predicate @translation, :in_review?
    assert_equal "in_review", @translation.status
  end

  test "status filtering by where clause works correctly" do
    draft1 = @translation
    draft2 = Article.create!(
      title: "Another Article",
      slug: "another-#{SecureRandom.hex(4)}",
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    ).translations.first

    published = Article.create!(
      title: "Published Article",
      slug: "published-#{SecureRandom.hex(4)}",
      published_at: Time.current,
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    ).translations.first
    published.update!(status: :published, published_at: Time.current)

    in_review = Article.create!(
      title: "In Review Article",
      slug: "review-#{SecureRandom.hex(4)}",
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    ).translations.first
    in_review.update!(status: :in_review)

    assert_includes Article::Translation.where(status: :published), published
    assert_not_includes Article::Translation.where(status: :published), draft1
    assert_not_includes Article::Translation.where(status: :published), in_review

    assert_includes Article::Translation.where(status: :draft), draft1
    assert_includes Article::Translation.where(status: :draft), draft2
    assert_not_includes Article::Translation.where(status: :draft), published

    assert_includes Article::Translation.where(status: :in_review), in_review
    assert_not_includes Article::Translation.where(status: :in_review), published
  end

  test "published status where clause works" do
    published = @article.translations.first
    published.update!(status: :published, published_at: Time.current)

    assert_includes Article::Translation.where(status: :published), published
  end
end
