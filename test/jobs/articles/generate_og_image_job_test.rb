# frozen_string_literal: true

require "test_helper"

module Articles
  class GenerateOgImageJobTest < ActiveJob::TestCase
    setup do
      @user = users(:admin)
    end

    test "attaches generated_og_images to a published article" do
      article = @user.articles.create!(
        title: "Job Test Article",
        slug: "job-test-article-#{SecureRandom.hex(4)}",
        excerpt: "Job test excerpt",
        body: "<p>Job test body content</p>"
      )

      publish_article!(article)

      perform_enqueued_jobs do
        Articles::GenerateOgImageJob.perform_later(article.id)
      end

      article.reload

      assert_predicate article.generated_og_images, :attached?, "Should attach generated OG images"

      og_image = article.generated_og_images.first

      assert_equal "image/png", og_image.blob.content_type
      assert_operator og_image.blob.byte_size, :>, 0, "Attached image should not be empty"
      assert_equal "og-en.png", og_image.blob.filename.to_s,
        "Should generate image with locale-specific filename"
    end

    test "skips generation when cover_image is already attached" do
      article = @user.articles.create!(
        title: "Already Has Cover",
        slug: "has-cover-og-#{SecureRandom.hex(4)}",
        excerpt: "Has cover",
        body: "<p>Already has a cover image</p>"
      )

      publish_article!(article)

      article.cover_image.attach(
        io: File.open(Rails.root.join("public/icon.png")),
        filename: "icon.png",
        content_type: "image/png"
      )

      perform_enqueued_jobs do
        Articles::GenerateOgImageJob.perform_later(article.id)
      end

      article.reload

      assert_not article.generated_og_images.attached?,
        "Should NOT generate OG image when cover_image is already attached"
    end

    test "does not raise when article is not found" do
      assert_nothing_raised do
        Articles::GenerateOgImageJob.perform_now(-1)
      end
    end

    test "does not enqueue job for draft articles" do
      assert_no_enqueued_jobs(only: Articles::GenerateOgImageJob) do
        @user.articles.create!(
          title: "Draft No OG",
          slug: "draft-no-og-#{SecureRandom.hex(4)}",
          body: "<p>Draft content</p>"
        )
      end
    end

    test "does not enqueue job when updating body of published article" do
      article = @user.articles.create!(
        title: "Body Only Update",
        slug: "body-update-og-#{SecureRandom.hex(4)}",
        excerpt: "Body update excerpt",
        body: "<p>Original body</p>"
      )

      publish_article!(article)

      assert_no_enqueued_jobs(only: Articles::GenerateOgImageJob) do
        article.update!(body: "<p>Updated body only, title unchanged</p>")
      end
    end

    test "does not enqueue job when cover_image is attached on published article" do
      article = @user.articles.create!(
        title: "Cover Blocks OG",
        slug: "cover-blocks-og-#{SecureRandom.hex(4)}",
        excerpt: "Cover blocks excerpt",
        body: "<p>Cover blocks body</p>"
      )

      publish_article!(article)

      article.cover_image.attach(
        io: File.open(Rails.root.join("public/icon.png")),
        filename: "icon.png",
        content_type: "image/png"
      )

      assert_no_enqueued_jobs(only: Articles::GenerateOgImageJob) do
        article.update!(title: "New Title But Has Cover")
      end
    end
  end
end
