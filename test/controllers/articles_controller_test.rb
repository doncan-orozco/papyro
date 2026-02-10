require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    @published_article = Article.create!(
      title: "Published Article",
      slug: "published-article-ctrl-#{Time.current.to_i}",
      status: :published,
      published_at: Time.current,
      content: "<p>Published content</p>",
      user: @user
    )
    @draft_article = Article.create!(
      title: "Draft Article",
      slug: "draft-article-ctrl-#{Time.current.to_i}",
      status: :draft,
      content: "<p>Draft content</p>",
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

    assert_redirected_to root_path
    assert_equal "Article not found", flash[:alert]
  end

  test "show redirects for non-existent article" do
    get article_path("non-existent-slug")

    assert_redirected_to root_path
    assert_equal "Article not found", flash[:alert]
  end

  test "show does not require authentication" do
    get article_path(@published_article.slug)

    assert_response :success
  end
end
