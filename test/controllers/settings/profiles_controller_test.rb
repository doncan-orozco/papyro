require "test_helper"

class Settings::ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
     @other_user = users(:two)
  end

  test "edit requires authentication" do
    get edit_settings_profile_path

    assert_redirected_to new_session_path
  end

  test "authenticated user can view profile settings" do
    sign_in_as(@user)

    get edit_settings_profile_path

    assert_response :success
    assert_includes response.body, I18n.t("users.settings.profile.title")
  end

  test "authenticated user can update profile" do
    sign_in_as(@user)

    patch settings_profile_path, params: {
      user: {
        profile_attributes: { display_name: "Updated Name" },
        email_address: "updated@example.com"
      }
    }

    assert_redirected_to edit_settings_profile_path
    assert_equal "Updated Name", @user.reload.profile.display_name
    assert_equal "updated@example.com", @user.reload.email_address
  end

  test "shows validation errors on invalid update" do
    sign_in_as(@user)

    patch settings_profile_path, params: {
      user: {
         email_address: @other_user.email_address
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, I18n.t("users.settings.profile.title")
  end
end
