require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "featured is accessible without authentication" do
    get featured_articles_path

    assert_response :success
  end
end
