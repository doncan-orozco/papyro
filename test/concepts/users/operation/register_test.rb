require "test_helper"

class Users::Operation::RegisterTest < ActiveSupport::TestCase
  test "creates user and profile with valid params" do
    result = Users::Operation::Register.new.call(params: {
      email_address: "new_writer@example.com",
      password: "password123"
    })

    assert_predicate result, :success?
    user = result.value![:model]

    assert_equal "new_writer@example.com", user.email_address
    assert_equal "new_writer", user.profile.username
    assert_equal "New Writer", user.profile.display_name
  end

  test "normalizes email before persistence" do
    result = Users::Operation::Register.new.call(params: {
      email_address: "  Mixed.Case@Example.com ",
      password: "password123"
    })

    assert_predicate result, :success?
    assert_equal "mixed.case@example.com", result.value![:model].email_address
  end

  test "appends numeric suffix when username already exists" do
    existing = User.create!(
      email_address: "existing_collision@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    existing.create_profile!(display_name: "Existing Collision", username: "john")

    result = Users::Operation::Register.new.call(params: {
      email_address: "john@example.com",
      password: "password123"
    })

    assert_predicate result, :success?
    assert_equal "john1", result.value![:model].profile.username
  end

  test "fails with invalid email format" do
    result = Users::Operation::Register.new.call(params: {
      email_address: "invalid-email",
      password: "password123"
    })

    assert_predicate result, :failure?
    assert_includes result.failure[:errors][:email_address], "must be a valid email address"
    assert_equal "invalid-email", result.failure[:model].email_address
  end

  test "rolls back user when profile creation fails" do
    original_generator = User.method(:next_available_profile_username)
    User.define_singleton_method(:next_available_profile_username) { |_base_username| "ad" }

    begin
      result = Users::Operation::Register.new.call(params: {
        email_address: "rollback_case@example.com",
        password: "password123"
      })

      assert_predicate result, :failure?
      assert_nil User.find_by(email_address: "rollback_case@example.com")
    ensure
      User.define_singleton_method(:next_available_profile_username, original_generator)
    end
  end
end
