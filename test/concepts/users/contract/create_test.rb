require "test_helper"

class Users::Contract::CreateTest < ActiveSupport::TestCase
  test "succeeds with valid attributes" do
    result = Users::Contract::Create.new.call(
      email_address: "new-user@example.com",
      password: "password123",
      password_confirmation: "password123",
      profile_attributes: { display_name: "Test Writer", username: "test_writer" }
    )

    assert_predicate result, :success?
  end

  test "fails without profile_attributes" do
    result = Users::Contract::Create.new.call(
      email_address: "new-user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_predicate result, :failure?
    assert result.errors.to_h.key?(:profile_attributes)
  end

  test "fails for mismatched passwords" do
    result = Users::Contract::Create.new.call(
      email_address: "new-user@example.com",
      password: "password123",
      password_confirmation: "different",
      profile_attributes: { display_name: "Test Writer", username: "test_writer" }
    )

    assert_predicate result, :failure?
    assert result.errors.to_h.key?(:password_confirmation)
  end

  test "fails when email_address is missing" do
    result = Users::Contract::Create.new.call(
      email_address: "",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_predicate result, :failure?
    assert result.errors.to_h.key?(:email_address)
  end

  test "fails when username is missing" do
    result = Users::Contract::Create.new.call(
      email_address: "new-user@example.com",
      password: "password123",
      password_confirmation: "password123",
      profile_attributes: { display_name: "Test Writer" }
    )

    assert_predicate result, :failure?
    assert result.errors.to_h.fetch(:profile_attributes).key?(:username)
  end
end
