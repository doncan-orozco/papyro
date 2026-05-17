require "test_helper"

class Users::Operation::LoginTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "authenticates user with valid credentials" do
    result = Users::Operation::Login.new.call(params: {
      email_address: @user.email_address,
      password: "password"
    })

    assert_predicate result, :success?
    assert_equal @user, result.value![:model]
  end

  test "normalizes the email address before authentication" do
    result = Users::Operation::Login.new.call(params: {
      email_address: "  #{@user.email_address.upcase}  ",
      password: "password"
    })

    assert_predicate result, :success?
    assert_equal @user, result.value![:model]
  end

  test "fails with contract errors for invalid email" do
    result = Users::Operation::Login.new.call(params: {
      email_address: "invalid-email",
      password: "password"
    })

    assert_predicate result, :failure?
    assert_includes result.failure[:errors][:email_address], "must be a valid email address"
    assert_equal "invalid-email", result.failure[:model].email_address
  end

  test "fails with invalid credentials code" do
    result = Users::Operation::Login.new.call(params: {
      email_address: @user.email_address,
      password: "wrong-password"
    })

    assert_predicate result, :failure?
    assert_equal :invalid_credentials, result.failure[:code]
    assert_equal I18n.t("sessions.create.invalid_credentials"), result.failure[:message]
  end
end
