require "test_helper"

class Users::Operation::UpdateTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "updates user with valid params" do
    params = {
      password: "newpassword",
      password_confirmation: "newpassword"
    }

    result = Users::Operation::Update.call(params: params, user: @user)

    assert_predicate result, :success?
    assert_equal @user, result[:model]
    assert @user.authenticate("newpassword")
  end

  test "fails with mismatched passwords" do
    params = {
      password: "newpassword",
      password_confirmation: "different"
    }

    result = Users::Operation::Update.call(params: params, user: @user)

    assert_predicate result, :failure?
    assert_includes result[:errors][:password_confirmation], "must match password"
  end

  test "updates email with valid format" do
    params = {
      email_address: "newemail@example.com"
    }

    result = Users::Operation::Update.call(params: params, user: @user)

    assert_predicate result, :success?
    assert_equal "newemail@example.com", @user.reload.email_address
  end

  test "fails with invalid email format" do
    params = {
      email_address: "invalid-email"
    }

    result = Users::Operation::Update.call(params: params, user: @user)

    assert_predicate result, :failure?
    assert_includes result[:errors][:email_address], "must be a valid email address"
  end

  test "fails with duplicate email" do
    other_user = users(:two)

    params = {
      email_address: other_user.email_address
    }

    result = Users::Operation::Update.call(params: params, user: @user)

    assert_predicate result, :failure?
    assert_includes result[:errors][:email_address], "is already taken"
  end

  test "allows updating email to same email (case insensitive)" do
    params = {
      email_address: @user.email_address.upcase
    }

    result = Users::Operation::Update.call(params: params, user: @user)

    assert_predicate result, :success?
  end
end
