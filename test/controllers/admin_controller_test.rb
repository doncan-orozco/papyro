require "test_helper"

# AdminController is an abstract base controller protecting the
# MissionControl::Jobs dashboard mounted at /jobs.
class AdminControllerTest < ActionDispatch::IntegrationTest
  test "admin user can access the jobs dashboard" do
    sign_in_as(users(:admin))

    get "/jobs"

    assert_response :success
  end

  test "non-admin authenticated user is redirected to login" do
    sign_in_as(users(:one))

    get "/jobs"

    assert_match %r{session/new}, response.location
  end

  test "unauthenticated user is redirected to login" do
    get "/jobs"

    assert_match %r{session/new}, response.location
  end
end
