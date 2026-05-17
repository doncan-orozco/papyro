require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:one)
  end

  test "reset email is addressed to the user" do
    email = PasswordsMailer.reset(@user)

    assert_equal [ @user.email_address ], email.to
  end

  test "reset email has the correct subject" do
    email = PasswordsMailer.reset(@user)

    assert_equal I18n.t("passwords_mailer.reset.subject"), email.subject
  end

  test "reset email body contains a password reset link" do
    email = PasswordsMailer.reset(@user)

    # The email body should include an edit_password URL with a signed token.
    assert_match %r{/passwords/.+/edit}, email.body.encoded
  end

  test "reset email is delivered" do
    assert_emails 1 do
      PasswordsMailer.reset(@user).deliver_now
    end
  end
end
