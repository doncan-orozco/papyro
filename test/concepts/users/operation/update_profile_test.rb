require "test_helper"

class Users::Operation::UpdateProfileTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "preserves existing username when params try to overwrite it" do
    expected_username = @user.profile.username

    result = Users::Operation::UpdateProfile.new.call(
      user: @user,
      params: {
        email_address: "updated@example.com",
        profile_attributes: {
          display_name: "Updated Name",
          username: "different_username"
        }
      }
    )

    assert_predicate result, :success?
    assert_equal "Updated Name", @user.reload.profile.display_name
    assert_equal expected_username, @user.profile.username
    assert_equal "updated@example.com", @user.email_address
  end
end
