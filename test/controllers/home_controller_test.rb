require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "index is accessible without authentication" do
    get root_path
    assert_response :success
  end
end
