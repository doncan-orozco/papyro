require "test_helper"

class ArticleArchiveVisibilityTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @article = Article.create!(
      title: "Test Article",
      slug: "test-archive-#{SecureRandom.hex(4)}",
      published_at: Time.current,
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    )
    # Ensure translation is published
    @translation = @article.translations.find_by(locale: @article.original_locale)
    @translation.update!(status: :published, published_at: Time.current)
  end

  test "published article is visible" do
    assert_predicate @article, :published?
    assert_includes Articles::Query::Published.call, @article
  end

  test "archived article is not visible even if published" do
    @article.update!(archived_at: Time.current)

    assert_not_predicate @article, :published?
    assert_not_includes Articles::Query::Published.call, @article
  end

  test "deleted article is not visible even if published" do
    @article.update!(deleted_at: Time.current)

    assert_not_predicate @article, :published?
    assert_not_includes Articles::Query::Published.call, @article
  end

  test "archived? predicate works" do
    assert_not_predicate @article, :archived?

    @article.update!(archived_at: Time.current)

    assert_predicate @article, :archived?

    @article.update!(archived_at: nil)

    assert_not_predicate @article, :archived?
  end

  test "unarchived predicate relation excludes archived articles" do
    assert_includes Article.where(archived_at: nil), @article

    @article.update!(archived_at: Time.current)

    assert_not_includes Article.where(archived_at: nil), @article
  end

  test "archived predicate relation includes only archived articles" do
    assert_not_includes Article.where.not(archived_at: nil), @article

    @article.update!(archived_at: Time.current)

    assert_includes Article.where.not(archived_at: nil), @article
  end
end
