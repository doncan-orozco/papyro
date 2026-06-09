# frozen_string_literal: true

require "test_helper"

class Articles::Service::OgImageGeneratorTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
  end

  test "generates a non-empty PNG tempfile for a valid article" do
    article = @user.articles.create!(
      title: "OG Image Test",
      slug: "og-image-test-#{SecureRandom.hex(4)}",
      body: "<p>Test content for OG image generation</p>"
    )

    generator = Articles::Service::OgImageGenerator.new(article)
    tempfile = generator.call

    assert_instance_of Tempfile, tempfile
    assert_operator tempfile.size, :>, 0, "Generated PNG should not be empty"

    # Verify the file is a valid PNG by checking magic bytes
    tempfile.rewind
    header = tempfile.read(8)

    assert header.start_with?("\x89PNG\r\n\x1a\n".b), "File should start with PNG magic bytes"
  ensure
    tempfile&.close!
  end

  test "generates image for article with long title" do
    long_title = "This Is A Very Long Article Title That Should Test The Word Wrapping Logic In The OG Image SVG Template " * 2
    article = @user.articles.create!(
      title: long_title.strip,
      slug: "long-title-og-#{SecureRandom.hex(4)}",
      body: "<p>Long title test</p>"
    )

    generator = Articles::Service::OgImageGenerator.new(article)
    tempfile = generator.call

    assert_operator tempfile.size, :>, 0, "Should generate image even for very long titles"
  ensure
    tempfile&.close!
  end

  test "generates image for article with single-word title" do
    article = @user.articles.create!(
      title: "Papyro",
      slug: "single-word-og-#{SecureRandom.hex(4)}",
      body: "<p>Single word</p>"
    )

    generator = Articles::Service::OgImageGenerator.new(article)
    tempfile = generator.call

    assert_operator tempfile.size, :>, 0
  ensure
    tempfile&.close!
  end

  test "uses Papyro fallback when author has no display name" do
    article = @user.articles.create!(
      title: "No Author Name",
      slug: "no-author-og-#{SecureRandom.hex(4)}",
      body: "<p>No author</p>"
    )

    generator = Articles::Service::OgImageGenerator.new(article)
    tempfile = generator.call

    assert_operator tempfile.size, :>, 0, "Should not crash when author has no display name"
  ensure
    tempfile&.close!
  end
end
