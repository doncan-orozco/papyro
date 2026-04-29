require "test_helper"

class Users::Form::LoginTest < ActiveSupport::TestCase
  test "validates and normalizes email" do
    form = Users::Form::Login.new

    assert form.validate(email_address: "  ONE@EXAMPLE.COM ", password: "password")
    assert_equal "one@example.com", form.email_address
  end

  test "adds error when email format is invalid" do
    form = Users::Form::Login.new

    refute form.validate(email_address: "invalid", password: "password")
    assert_predicate form.errors[:email_address], :any?
  end
end
