require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
  end

  test "show is accessible without authentication" do
    get user_path(@user)

    assert_response :success
    assert_includes @response.body, @user.email_address
  end

  test "edit requires authentication" do
    get edit_user_path(@user)

    assert_redirected_to new_session_path
  end

  test "edit requires ownership" do
    sign_in_as(@other_user)

    get edit_user_path(@user)

    assert_redirected_to root_path
  end

  test "owner can edit profile" do
    sign_in_as(@user)

    get edit_user_path(@user)

    assert_response :success
    assert_includes response.body, I18n.t("users.edit.title")
  end

  test "owner can update profile" do
    sign_in_as(@user)

    patch user_path(@user), params: {
      user: {
        email_address: "updated@example.com",
        password: "",
        password_confirmation: ""
      }
    }

    assert_redirected_to user_path(@user)
    assert_equal "updated@example.com", @user.reload.email_address
  end

  test "owner sees validation errors when update is invalid" do
    sign_in_as(@user)

    original_password_digest = @user.password_digest

    patch user_path(@user), params: {
      user: {
        email_address: @user.email_address,
        password: "new-password",
        password_confirmation: "different-password"
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, I18n.t("users.edit.title")
    assert_equal original_password_digest, @user.reload.password_digest
  end
end
