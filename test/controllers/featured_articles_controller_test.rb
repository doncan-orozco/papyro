require "test_helper"

class FeaturedArticlesControllerTest < ActionDispatch::IntegrationTest
  test "show is accessible without authentication" do
    get featured_articles_path

    assert_response :success
  end
end
