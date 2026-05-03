require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)  # Uses fixture from test/fixtures/users.yml
  end

  test "belongs to user" do
    article = Article.new(title: "Test", slug: "test")

    assert_not article.valid?

    article.user = @user
    article.save!

    assert_equal @user, article.user
  end

  test "has rich text content" do
    article = @user.articles.create!(
      title: "Rich Content",
      slug: "rich-content",
      status: :draft
    )

    article.update!(body: "<p>Hello <strong>world</strong></p>")

    assert_includes article.body.to_html, "Hello <strong>world</strong>"
  end

  test "enum status methods" do
    article = @user.articles.create!(
      title: "Status Test",
      slug: "status-test",
      status: :draft
    )

    assert_predicate article, :status_draft?
    assert_not article.status_published?

    article.published_at = Time.current
    article.status_published!

    assert_predicate article, :status_published?
  end

  test "published? method requires both status and published_at" do
    draft = @user.articles.create!(title: "Draft", slug: "draft", status: :draft)
    published_no_date = Article.new(
      title: "Published No Date",
      slug: "published-no-date",
      status: :published
    )
    published = @user.articles.create!(
      title: "Published",
      slug: "published",
      status: :published,
      published_at: Time.current
    )

    assert_not draft.published?
    assert_not published_no_date.published?
    assert_predicate published, :published?
    assert_not published_no_date.valid?
    assert_includes published_no_date.errors[:published_at], "Published date is required when status is 'published'"
  end

  test "slug is used in URL" do
    article = @user.articles.create!(
      title: "URL Test",
      slug: "my-article-slug",
      status: :draft
    )

    assert_equal "my-article-slug", article.to_param
  end

  test "normalizes title and slug" do
    article = @user.articles.create!(
      title: "  Untrimmed Title  ",
      slug: "  UPPERCASE-SLUG  ",
      status: :draft
    )

    assert_equal "Untrimmed Title", article.title
    assert_equal "uppercase-slug", article.slug
  end

  test "content metrics are calculated from plain text" do
    article = @user.articles.create!(
      title: "Metric Test",
      slug: "metric-test",
      status: :published,
      published_at: Time.current,
      body: "<p>Hello <strong>world</strong> from <em>Papyro</em></p>"
    )

    assert_equal "Hello world from Papyro", article.plain_text_body
    assert_equal 4, article.content_word_count
    assert_equal 1, article.estimated_reading_time_minutes
  end

  test "estimated reading time is zero when content is blank" do
    article = @user.articles.create!(
      title: "Empty Metric Test",
      slug: "empty-metric-test",
      status: :draft,
      body: ""
    )

    assert_equal 0, article.content_word_count
    assert_equal 0, article.estimated_reading_time_minutes
  end
end
