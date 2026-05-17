require "test_helper"

class Settings::SecurityControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "edit requires authentication" do
    get edit_settings_security_path

    assert_redirected_to new_session_path
  end

  test "authenticated user can view security settings" do
    sign_in_as(@user)

    get edit_settings_security_path

    assert_response :success
    assert_includes response.body, I18n.t("users.settings.security.title")
  end

  test "authenticated user can update password" do
    sign_in_as(@user)

    patch settings_security_path, params: {
      user: {
        current_password: "password",
        password: "new-password-123",
        password_confirmation: "new-password-123"
      }
    }

    assert_redirected_to edit_settings_security_path
    assert @user.reload.authenticate("new-password-123")
  end

  test "rejects incorrect current password" do
    sign_in_as(@user)

    original_digest = @user.password_digest

    patch settings_security_path, params: {
      user: {
        current_password: "wrong-password",
        password: "new-password-123",
        password_confirmation: "new-password-123"
      }
    }

    assert_response :unprocessable_entity
    assert_equal original_digest, @user.reload.password_digest
  end

  test "rejects mismatched password confirmation" do
    sign_in_as(@user)

    original_digest = @user.password_digest

    patch settings_security_path, params: {
      user: {
        current_password: "password",
        password: "new-password-123",
        password_confirmation: "different-password"
      }
    }

    assert_response :unprocessable_entity
    assert_equal original_digest, @user.reload.password_digest
  end
end
