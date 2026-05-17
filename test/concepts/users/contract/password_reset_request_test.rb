require "test_helper"

class Users::Contract::PasswordResetRequestTest < ActiveSupport::TestCase
  test "succeeds with valid email" do
    result = Users::Contract::PasswordResetRequest.new.call(email_address: "two@example.com")

    assert_predicate result, :success?
  end

  test "fails for invalid email format" do
    result = Users::Contract::PasswordResetRequest.new.call(email_address: "bad-email")

    assert_predicate result, :failure?
    assert_predicate result.errors.to_h[:email_address], :any?
  end

  test "fails when email is missing" do
    result = Users::Contract::PasswordResetRequest.new.call({})

    assert_predicate result, :failure?
    assert_predicate result.errors.to_h[:email_address], :any?
  end
end
