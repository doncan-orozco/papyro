require "test_helper"

class Users::Contract::LoginTest < ActiveSupport::TestCase
  test "succeeds with valid params" do
    result = Users::Contract::Login.new.call(email_address: "one@example.com", password: "password")

    assert_predicate result, :success?
  end

  test "fails for invalid email format" do
    result = Users::Contract::Login.new.call(email_address: "invalid", password: "password")

    assert_predicate result, :failure?
    assert_predicate result.errors.to_h[:email_address], :any?
  end

  test "fails when password is missing" do
    result = Users::Contract::Login.new.call(email_address: "one@example.com")

    assert_predicate result, :failure?
    assert_predicate result.errors.to_h[:password], :any?
  end
end
