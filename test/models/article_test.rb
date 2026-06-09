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
    )

    article.update!(body: "<p>Hello <strong>world</strong></p>")

    assert_includes article.body.to_html, "Hello <strong>world</strong>"
  end

  test "status predicates reflect explicit publish operation" do
    article = @user.articles.create!(
      title: "Status Test",
      slug: "status-test",
      excerpt: "Short summary",
      body: "<p>Body content</p>"
    )

    assert_predicate article, :draft?
    assert_not article.published?

    result = Articles::Operation::Publish.new.call(model: article)

    assert_predicate result, :success?
    assert_predicate article.reload, :published?
  end

  test "published? remains false until article is actually published" do
    draft = @user.articles.create!(title: "Draft", slug: "draft")
    published_no_date = Article.new(title: "Published No Date", slug: "published-no-date")
    published = @user.articles.create!(
      title: "Published",
      slug: "published",
      excerpt: "Short summary",
      body: "<p>Published content</p>",
      published_at: Time.current,
      user: @user
    )
    Articles::Operation::Publish.new.call(model: published)

    assert_not draft.published?
    assert_not published_no_date.published?
    assert_predicate published, :published?
    assert_predicate published_no_date, :draft?
  end

  test "slug is used in URL" do
    article = @user.articles.create!(
      title: "URL Test",
      slug: "my-article-slug",
    )

    assert_equal "my-article-slug", article.to_param
  end

  test "normalizes title and slug" do
    article = @user.articles.create!(
      title: "  Untrimmed Title  ",
      slug: "  UPPERCASE-SLUG  ",
    )

    assert_equal "Untrimmed Title", article.title
    assert_equal "uppercase-slug", article.slug
  end

  test "content metrics are calculated from plain text" do
    article = @user.articles.create!(
      title: "Metric Test",
      slug: "metric-test",
      published_at: Time.current,
      body: "<p>Hello <strong>world</strong> from <em>Papyro</em></p>"
    )

    content_analysis = Articles::Service::ContentAnalysis.new(article)

    assert_equal "Hello world from Papyro", content_analysis.plain_text_body
    assert_equal 4, content_analysis.content_word_count
    assert_equal 1, content_analysis.estimated_reading_time_minutes
  end

  test "estimated reading time is zero when content is blank" do
    article = @user.articles.create!(
      title: "Empty Metric Test",
      slug: "empty-metric-test",
      body: ""
    )

    content_analysis = Articles::Service::ContentAnalysis.new(article)

    assert_equal 0, content_analysis.content_word_count
    assert_equal 0, content_analysis.estimated_reading_time_minutes
  end

  test "cover image rejects unsupported content type" do
    article = @user.articles.build(
      title: "Invalid Cover Type",
      slug: "invalid-cover-type",
      body: "Body"
    )

    article.cover_image.attach(
      io: StringIO.new("not an image"),
      filename: "cover.txt",
      content_type: "text/plain"
    )

    assert_not article.valid?
    assert_includes article.errors[:cover_image], I18n.t("articles.errors.invalid_cover_image_content_type")
  end

  test "cover image rejects files larger than allowed size" do
    article = @user.articles.build(
      title: "Huge Cover",
      slug: "huge-cover",
      body: "Body"
    )

    article.cover_image.attach(
      io: StringIO.new("a" * (Articles::Service::CoverImageValidation::MAX_COVER_IMAGE_SIZE + 1)),
      filename: "cover.png",
      content_type: "image/png"
    )

    assert_not article.valid?
    assert_includes article.errors[:cover_image], I18n.t("articles.errors.invalid_cover_image_size", max_size_mb: Articles::Service::CoverImageValidation::MAX_COVER_IMAGE_SIZE / 1.megabyte)
  end

  test "cover image rejects unanalyzable image payloads" do
    article = @user.articles.build(
      title: "Broken Cover",
      slug: "broken-cover",
      body: "Body"
    )

    article.cover_image.attach(
      io: StringIO.new("fake png contents"),
      filename: "cover.png",
      content_type: "image/png"
    )

    assert_not article.valid?
    assert_includes article.errors[:cover_image], I18n.t("articles.errors.invalid_cover_image_dimensions")
  end

  test "cover image rejects images smaller than the minimum dimensions" do
    article = @user.articles.build(
      title: "Tiny Cover",
      slug: "tiny-cover",
      body: "Body"
    )

    image = MiniMagick::Image.read(File.binread(Rails.root.join("public/icon.png")))
    image.resize("200x200")
    file = Tempfile.new([ "tiny-cover", ".png" ])
    image.write(file.path)

    article.cover_image.attach(
      io: File.open(file.path),
      filename: "tiny-cover.png",
      content_type: "image/png"
    )

    assert_not article.valid?
    assert_includes article.errors[:cover_image], I18n.t(
      "articles.errors.cover_image_too_small",
      min_width: Articles::Service::CoverImageValidation::MIN_COVER_IMAGE_WIDTH,
      min_height: Articles::Service::CoverImageValidation::MIN_COVER_IMAGE_HEIGHT
    )
  ensure
    file&.close!
  end

  test "has generated_og_images attachment" do
    article = @user.articles.create!(
      title: "Generated OG",
      slug: "generated-og-#{SecureRandom.hex(4)}",
      body: "<p>OG attachment test</p>"
    )

    assert_respond_to article, :generated_og_images
    assert_not article.generated_og_images.attached?
  end
end
