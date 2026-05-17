require "test_helper"
require "securerandom"

class ActionText::Markdown::UploadsControllerTest < ActionDispatch::IntegrationTest
  test "create uploads file for authorized markdown attribute" do
    user = users(:admin)
    sign_in_as(user)
    article = Article.create!(
      title: "Upload Article",
      slug: "upload-article-#{SecureRandom.hex(4)}",
      body: "Body",
      user: user
    )

    post action_text_markdown_uploads_path, params: {
      record_gid: article.to_sgid.to_s,
      attribute_name: "body",
      file: Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png")
    }

    assert_response :created
    assert_equal "File uploaded successfully", response.parsed_body["message"]
    assert_equal "icon.png", response.parsed_body["fileName"]
    assert_predicate article.reload.body.uploads, :attached?
  end

  test "create returns unprocessable entity for invalid markdown attribute" do
    user = users(:admin)
    sign_in_as(user)
    article = Article.create!(
      title: "Upload Article",
      slug: "invalid-upload-article-#{SecureRandom.hex(4)}",
      body: "Body",
      user: user
    )

    post action_text_markdown_uploads_path, params: {
      record_gid: article.to_sgid.to_s,
      attribute_name: "excerpt",
      file: Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png")
    }

    assert_response :unprocessable_entity
    assert_equal I18n.t("errors.messages.invalid_markdown_attribute"), response.parsed_body["message"]
  end

  # The show action is public (allow_unauthenticated_access only: :show).
  test "show returns 404 when attachment slug is not found" do
    get "/u/nonexistent-slug", as: :html

    assert_response :not_found
  end
end
