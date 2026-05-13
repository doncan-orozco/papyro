require "test_helper"

class Users::Operation::PasswordResetRequestTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @user = users(:one)
  end

  test "enqueues reset instructions for an existing user" do
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ] do
      result = Users::Operation::PasswordResetRequest.new.call(params: {
        email_address: @user.email_address
      })

      assert_predicate result, :success?
      assert_equal @user.email_address, result.value![:email_address]
    end
  end

  test "normalizes the email address before lookup" do
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ] do
      result = Users::Operation::PasswordResetRequest.new.call(params: {
        email_address: "  #{@user.email_address.upcase}  "
      })

      assert_predicate result, :success?
      assert_equal @user.email_address, result.value![:email_address]
    end
  end

  test "succeeds without enqueueing mail for an unknown user" do
    assert_enqueued_emails 0 do
      result = Users::Operation::PasswordResetRequest.new.call(params: {
        email_address: "missing-user@example.com"
      })

      assert_predicate result, :success?
      assert_equal "missing-user@example.com", result.value![:email_address]
    end
  end

  test "fails with contract errors for invalid email" do
    result = Users::Operation::PasswordResetRequest.new.call(params: {
      email_address: "invalid-email"
    })

    assert_predicate result, :failure?
    assert_includes result.failure[:errors][:email_address], "must be a valid email address"
    assert_equal "invalid-email", result.failure[:model].email_address
  end
end
