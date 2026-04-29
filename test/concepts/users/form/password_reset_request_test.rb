require "test_helper"

class Users::Form::PasswordResetRequestTest < ActiveSupport::TestCase
  test "validates and normalizes email" do
    form = Users::Form::PasswordResetRequest.new

    assert form.validate(email_address: "  TWO@EXAMPLE.COM ")
    assert_equal "two@example.com", form.email_address
  end

  test "adds error for invalid email format" do
    form = Users::Form::PasswordResetRequest.new

    refute form.validate(email_address: "bad-email")
    assert_predicate form.errors[:email_address], :any?
  end
end
