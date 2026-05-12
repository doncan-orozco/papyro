require "test_helper"

class ArticleArchiveVisibilityTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @article = Article.create!(
      title: "Test Article",
      slug: "test-archive-#{SecureRandom.hex(4)}",
      status: :published,
      published_at: Time.current,
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    )
    # Ensure translation is published
    @translation = @article.article_translations.find_by(locale: @article.original_locale)
    @translation.update!(status: :published, published_at: Time.current)
  end

  test "published article is visible" do
    assert_predicate @article, :published?
    assert_includes Articles::PublishedQuery.call, @article
  end

  test "archived article is not visible even if published" do
    @article.update!(archived_at: Time.current)

    assert_not_predicate @article, :published?
    assert_not_includes Articles::PublishedQuery.call, @article
  end

  test "deleted article is not visible even if published" do
    @article.update!(deleted_at: Time.current)

    assert_not_predicate @article, :published?
    assert_not_includes Articles::PublishedQuery.call, @article
  end

  test "archived? predicate works" do
    assert_not_predicate @article, :archived?

    @article.update!(archived_at: Time.current)
    assert_predicate @article, :archived?

    @article.update!(archived_at: nil)
    assert_not_predicate @article, :archived?
  end

  test "active scope filters archived articles" do
    assert_includes Article.active, @article

    @article.update!(archived_at: Time.current)
    assert_not_includes Article.active, @article
  end

  test "archived scope filters non-archived articles" do
    assert_not_includes Article.archived, @article

    @article.update!(archived_at: Time.current)
    assert_includes Article.archived, @article
  end
end
