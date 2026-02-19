require "test_helper"

class DesignSystemControllerTest < ActionDispatch::IntegrationTest
  test "index is accessible without authentication" do
    get design_system_path

    assert_response :success
  end
end
