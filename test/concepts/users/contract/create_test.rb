require "test_helper"

class Users::Contract::CreateTest < ActiveSupport::TestCase
  test "succeeds with valid attributes" do
    result = Users::Contract::Create.new.call(
      email_address: "new-user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_predicate result, :success?
  end

  test "fails for invalid email" do
    result = Users::Contract::Create.new.call(
      email_address: "invalid",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_predicate result, :failure?
    assert result.errors.to_h.key?(:email_address)
  end

  test "fails for duplicate email" do
    users(:one)

    result = Users::Contract::Create.new.call(
      email_address: "one@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_predicate result, :failure?
    assert result.errors.to_h.key?(:email_address)
  end

  test "fails for mismatched passwords" do
    result = Users::Contract::Create.new.call(
      email_address: "new-user@example.com",
      password: "password123",
      password_confirmation: "different"
    )

    assert_predicate result, :failure?
    assert result.errors.to_h.key?(:password_confirmation)
  end
end
