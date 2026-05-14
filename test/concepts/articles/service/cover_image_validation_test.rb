require "test_helper"

class Articles::Service::CoverImageValidationTest < ActiveSupport::TestCase
  test "adds error for unsupported content type" do
    article = users(:admin).articles.build(
      title: "Invalid type",
      slug: "invalid-type-#{SecureRandom.hex(4)}",
      body: "Body"
    )

    article.cover_image.attach(
      io: StringIO.new("not an image"),
      filename: "cover.txt",
      content_type: "text/plain"
    )

    Articles::Service::CoverImageValidation.new(article).validate

    assert_includes article.errors[:cover_image], I18n.t("articles.errors.invalid_cover_image_content_type")
  end

  test "adds error for oversized cover image" do
    article = users(:admin).articles.build(
      title: "Huge",
      slug: "huge-cover-#{SecureRandom.hex(4)}",
      body: "Body"
    )

    article.cover_image.attach(
      io: StringIO.new("a" * (Articles::Service::CoverImageValidation::MAX_COVER_IMAGE_SIZE + 1)),
      filename: "cover.png",
      content_type: "image/png"
    )

    Articles::Service::CoverImageValidation.new(article).validate

    assert_includes article.errors[:cover_image], I18n.t(
      "articles.errors.invalid_cover_image_size",
      max_size_mb: Articles::Service::CoverImageValidation::MAX_COVER_IMAGE_SIZE / 1.megabyte
    )
  end

  test "adds error for unanalyzable dimensions" do
    article = users(:admin).articles.build(
      title: "Broken",
      slug: "broken-cover-#{SecureRandom.hex(4)}",
      body: "Body"
    )

    article.cover_image.attach(
      io: StringIO.new("fake png contents"),
      filename: "cover.png",
      content_type: "image/png"
    )

    Articles::Service::CoverImageValidation.new(article).validate

    assert_includes article.errors[:cover_image], I18n.t("articles.errors.invalid_cover_image_dimensions")
  end

  test "adds error when dimensions are smaller than minimum" do
    article = users(:admin).articles.build(
      title: "Tiny",
      slug: "tiny-cover-#{SecureRandom.hex(4)}",
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

    Articles::Service::CoverImageValidation.new(article).validate

    assert_includes article.errors[:cover_image], I18n.t(
      "articles.errors.cover_image_too_small",
      min_width: Articles::Service::CoverImageValidation::MIN_COVER_IMAGE_WIDTH,
      min_height: Articles::Service::CoverImageValidation::MIN_COVER_IMAGE_HEIGHT
    )
  ensure
    file.close!
  end

  test "keeps errors empty for valid cover image" do
    article = users(:admin).articles.build(
      title: "Valid cover",
      slug: "valid-cover-#{SecureRandom.hex(4)}",
      body: "Body"
    )

    article.cover_image.attach(
      io: File.open(Rails.root.join("public/icon.png")),
      filename: "icon.png",
      content_type: "image/png"
    )

    Articles::Service::CoverImageValidation.new(article).validate

    assert_empty article.errors[:cover_image]
  end
end
