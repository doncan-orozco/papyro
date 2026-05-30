require "test_helper"
require "securerandom"

class ActionText::Markdown::UploadsControllerTest < ActionDispatch::IntegrationTest
  test "uploads preflight returns CORS headers for allowed studio origin" do
    origin = "https://studio.qa.papyro.net"

    options action_text_markdown_uploads_path, headers: {
      "Origin" => origin,
      "Access-Control-Request-Method" => "POST"
    }

    assert_response :success
    assert_equal origin, response.headers["Access-Control-Allow-Origin"]
    assert_equal "true", response.headers["Access-Control-Allow-Credentials"]
    assert_includes response.headers["Access-Control-Allow-Methods"], "POST"
  end

  test "uploads preflight does not allow unknown origin" do
    options action_text_markdown_uploads_path, headers: {
      "Origin" => "https://evil.example",
      "Access-Control-Request-Method" => "POST"
    }

    assert_response :success
    assert_nil response.headers["Access-Control-Allow-Origin"]
  end

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

  test "create returns public-host file URL when request comes from studio subdomain" do
    host! "studio.lvh.me"

    user = users(:admin)
    sign_in_as(user)
    article = Article.create!(
      title: "Upload Article",
      slug: "studio-upload-article-#{SecureRandom.hex(4)}",
      body: "Body",
      user: user
    )

    origin = "http://studio.lvh.me:3030"

    post action_text_markdown_uploads_path,
      headers: { "Origin" => origin },
      params: {
      record_gid: article.to_sgid.to_s,
      attribute_name: "body",
      file: Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png")
      }

    assert_response :created
    assert_equal origin, response.headers["Access-Control-Allow-Origin"]
    assert_match(%r{\Ahttp://lvh\.me(:\d+)?/u/}, response.parsed_body["fileUrl"])
  end

  test "show redirects for existing attachment slug without format" do
    user = users(:admin)
    sign_in_as(user)
    article = Article.create!(
      title: "Upload Article",
      slug: "show-upload-article-#{SecureRandom.hex(4)}",
      body: "Body",
      user: user
    )

    post action_text_markdown_uploads_path, params: {
      record_gid: article.to_sgid.to_s,
      attribute_name: "body",
      file: Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png")
    }

    assert_response :created

    file_url = response.parsed_body.fetch("fileUrl")
    slug = URI.parse(file_url).path.delete_prefix("/u/")

    sign_out
    get "/u/#{slug}", as: :html

    assert_response :redirect
    assert_includes response.headers["Location"], "/rails/active_storage/"
  end

  # The show action is public (allow_unauthenticated_access only: :show).
  test "show returns 404 when attachment slug is not found" do
    get "/u/nonexistent-slug", as: :html

    assert_response :not_found
  end
end
