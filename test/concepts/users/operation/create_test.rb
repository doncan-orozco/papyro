require "test_helper"

class Users::Operation::CreateTest < ActiveSupport::TestCase
  test "creates user with valid params" do
    params = {
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    }
    
    result = Users::Operation::Create.call(params: params)
    
    assert result.success?
    assert_instance_of User, result[:model]
    assert_equal "test@example.com", result[:model].email_address
  end
  
  test "fails with invalid email" do
    params = {
      email_address: "invalid-email",
      password: "password123",
      password_confirmation: "password123"
    }
    
    result = Users::Operation::Create.call(params: params)
    
    assert result.failure?
    assert_includes result[:errors][:email_address], "must be a valid email address"
  end
  
  test "fails with mismatched passwords" do
    params = {
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "different"
    }
    
    result = Users::Operation::Create.call(params: params)
    
    assert result.failure?
    assert_includes result[:errors][:password_confirmation], "must match password"
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
      email_address: "duplicate@example.com",
      password: "password456",
      password_confirmation: "password456"
    }
    
    result = Users::Operation::Create.call(params: params)
    
    assert result.failure?
    assert_includes result[:errors][:email_address], "is already taken"
  end
  
  test "fails with missing required fields" do
    params = {
      email_address: "",
      password: "",
      password_confirmation: ""
    }
    
    result = Users::Operation::Create.call(params: params)
    
    assert result.failure?
    assert result[:errors].key?(:email_address)
    assert result[:errors].key?(:password)
  end
end
