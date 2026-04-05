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
    assert_includes @response.body, "href=\"#{article_path(@published_article)}\""
    assert_includes @response.body, "href=\"#{articles_path}\""
  end

  test "index is accessible without authentication" do
    get articles_path

    assert_response :success
    assert_includes @response.body, "Find your next deep read"
    assert_includes @response.body, "Search across essays, notes, and topics"
  end

  test "index lists only published articles" do
    hidden_article = Article.create!(
      title: "Hidden Published Article",
      slug: "hidden-published-article-ctrl-#{Time.current.to_i}",
      status: :published,
      published_at: 10.minutes.ago,
      body: "<p>Hidden published content</p>",
      user: @user
    )

    5.times do |index|
      Article.create!(
        title: "Extra Published Article #{index}",
        slug: "extra-published-article-#{index}-#{Time.current.to_i}",
        status: :published,
        published_at: (index + 1).hours.from_now,
        body: "<p>Extra published content #{index}</p>",
        user: @user
      )
    end

    get articles_path

    assert_includes @response.body, @published_article.title
    assert_not_includes @response.body, @draft_article.title
    assert_not_includes @response.body, hidden_article.title
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

  test "show renders previous and next article links" do
    _older_article = Article.create!(
      title: "Older Published Article",
      slug: "older-published-article-ctrl-#{Time.current.to_i}",
      status: :published,
      published_at: 2.days.ago,
      body: "<p>Older published content</p>",
      user: @user
    )

    newer_article = Article.create!(
      title: "Newer Published Article",
      slug: "newer-published-article-ctrl-#{Time.current.to_i}",
      status: :published,
      published_at: 2.days.from_now,
      body: "<p>Newer published content</p>",
      user: @user
    )

    get article_path(@published_article.slug)

    assert_response :success
    assert_match(%r{<a[^>]+href="/articles/[^"]+"[^>]*>\s*<span[^>]*>Previous Article</span>}m, @response.body)
    assert_includes @response.body, "href=\"#{article_path(newer_article)}\""
  end
end
