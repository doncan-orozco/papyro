require "test_helper"

class Users::Contract::UpdateTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @other_user = users(:two)
  end

  test "succeeds when params are empty" do
    result = Users::Contract::Update.new(user_id: @user.id).call({})

    assert_predicate result, :success?
  end

  test "fails for invalid email" do
    result = Users::Contract::Update.new(user_id: @user.id).call(email_address: "not-an-email")

    assert_predicate result, :failure?
    assert result.errors.to_h.key?(:email_address)
  end

  test "fails for duplicate email on another user" do
    result = Users::Contract::Update.new(user_id: @user.id).call(email_address: @other_user.email_address)

    assert_predicate result, :failure?
    assert result.errors.to_h.key?(:email_address)
  end

  test "fails for mismatched password confirmation" do
    result = Users::Contract::Update.new(user_id: @user.id).call(
      password: "password123",
      password_confirmation: "different"
    )

    assert_predicate result, :failure?
    assert result.errors.to_h.key?(:password_confirmation)
  end
end
