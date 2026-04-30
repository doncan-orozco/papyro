require "test_helper"

class Users::Operation::CreateTest < ActiveSupport::TestCase
  test "creates user with valid params" do
    params = {
      display_name: "Test Writer",
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    }

    result = Users::Operation::Create.new.call(params: params)

    assert_predicate result, :success?
    assert_instance_of User, result.value![:model]
    assert_equal "test@example.com", result.value![:model].email_address
    assert_equal "Test Writer", result.value![:model].profile.display_name
  end

  test "fails with invalid email" do
    params = {
      display_name: "Test Writer",
      email_address: "invalid-email",
      password: "password123",
      password_confirmation: "password123"
    }

    result = Users::Operation::Create.new.call(params: params)

    assert_predicate result, :failure?
    assert_includes result.failure[:errors][:email_address], "must be a valid email address"
  end

  test "fails with mismatched passwords" do
    params = {
      display_name: "Test Writer",
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "different"
    }

    result = Users::Operation::Create.new.call(params: params)

    assert_predicate result, :failure?
    assert_includes result.failure[:errors][:password_confirmation], "must match password"
  end

  test "fails with duplicate email" do
    # Create first user
    User.create!(
      email_address: "duplicate@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    # Try to create duplicate
    params = {
      display_name: "Test Writer",
      email_address: "duplicate@example.com",
      password: "password456",
      password_confirmation: "password456"
    }

    result = Users::Operation::Create.new.call(params: params)

    assert_predicate result, :failure?
    assert_includes result.failure[:errors][:email_address], "is already taken"
  end

  test "fails with missing required fields" do
    params = {
      display_name: "",
      email_address: "",
      password: "",
      password_confirmation: ""
    }

    result = Users::Operation::Create.new.call(params: params)

    assert_predicate result, :failure?
    assert result.failure[:errors].key?(:display_name)
    assert result.failure[:errors].key?(:email_address)
    assert result.failure[:errors].key?(:password)
  end
end
