require "test_helper"

class Users::Operation::UpdatePasswordTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "updates password with valid params and current password" do
    params = {
      current_password: "password",
      password: "new-password-123",
      password_confirmation: "new-password-123"
    }

    result = Users::Operation::UpdatePassword.new.call(params: params, user: @user)

    assert_predicate result, :success?
    assert_equal @user, result.value![:model]
    assert @user.reload.authenticate("new-password-123")
  end

  test "fails when current password is invalid" do
    params = {
      current_password: "wrong-password",
      password: "new-password-123",
      password_confirmation: "new-password-123"
    }

    result = Users::Operation::UpdatePassword.new.call(params: params, user: @user)

    assert_predicate result, :failure?
    assert_includes result.failure[:errors][:current_password], I18n.t("users.operations.update_password.current_password_invalid")
    assert_equal @user, result.failure[:model]
    assert @user.reload.authenticate("password")
  end

  test "fails when password confirmation does not match" do
    params = {
      current_password: "password",
      password: "new-password-123",
      password_confirmation: "different"
    }

    result = Users::Operation::UpdatePassword.new.call(params: params, user: @user)

    assert_predicate result, :failure?
    assert_includes result.failure[:errors][:password_confirmation], I18n.t("errors.messages.password_mismatch")
    assert_equal @user, result.failure[:model]
  end
end
