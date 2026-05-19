require "test_helper"

class EmailVerificationsMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:one)
  end

  test "verify email is addressed to the user" do
    email = EmailVerificationsMailer.verify(@user)

    assert_equal [ @user.email_address ], email.to
  end

  test "verify email has the correct subject" do
    email = EmailVerificationsMailer.verify(@user)

    assert_equal I18n.t("email_verifications_mailer.verify.subject"), email.subject
  end

  test "verify email body contains verification link" do
    email = EmailVerificationsMailer.verify(@user)

    assert_match %r{/verify_email/}, email.body.encoded
  end

  test "verify email is delivered" do
    assert_emails 1 do
      EmailVerificationsMailer.verify(@user).deliver_now
    end
  end
end
