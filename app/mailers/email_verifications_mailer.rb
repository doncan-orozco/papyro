class EmailVerificationsMailer < ApplicationMailer
  def verify(user)
    @user = user
    @token = user.generate_token_for(:email_verification)

    mail subject: t("email_verifications_mailer.verify.subject"), to: user.email_address
  end
end
