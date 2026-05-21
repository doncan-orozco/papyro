require "test_helper"

class Users::Operation::UpdateProfileTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "updates username when params include a new value" do
    expected_email_address = @user.email_address

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
    assert_equal "different_username", @user.profile.username
    assert_equal expected_email_address, @user.email_address
  end

  test "updates portrait and username" do
    result = Users::Operation::UpdateProfile.new.call(
      user: @user,
      params: {
        profile_attributes: {
          display_name: @user.profile.display_name,
          username: "another_name",
          portrait: {
            io: StringIO.new("portrait image"),
            filename: "portrait.png",
            content_type: "image/png"
          }
        }
      }
    )

    assert_predicate result, :success?
    assert_equal "another_name", @user.reload.profile.username
    assert_predicate @user.profile.portrait, :attached?
  end
end
