require "test_helper"

class ActionText::Markdown::UploadsControllerTest < ActionDispatch::IntegrationTest
  # The show action is public (allow_unauthenticated_access only: :show).
  test "show returns 404 when attachment slug is not found" do
    get "/u/nonexistent-slug", as: :html

    assert_response :not_found
  end
end
