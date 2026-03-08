require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    @published_article = Article.create!(
      title: "Published Article",
      slug: "published-article-ctrl-#{Time.current.to_i}",
      status: :published,
      published_at: Time.current,
      body: "<p>Published content</p>",
      user: @user
    )
    @draft_article = Article.create!(
      title: "Draft Article",
      slug: "draft-article-ctrl-#{Time.current.to_i}",
      status: :draft,
      body: "<p>Draft content</p>",
      user: @user
    )
  end

  test "featured is accessible without authentication" do
    get featured_articles_path

    assert_response :success
  end

  test "show renders published article" do
    get article_path(@published_article.slug)

    assert_response :success
  end

  test "show redirects for draft article" do
    get article_path(@draft_article.slug)

    assert_response :not_found
  end

  test "show redirects for non-existent article" do
    get article_path("non-existent-slug")

    assert_response :not_found
  end

  test "show does not require authentication" do
    get article_path(@published_article.slug)

    assert_response :success
  end
end
