# Preview all emails at http://localhost:3000/rails/mailers/passwords_mailer
class PasswordsMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/passwords_mailer/reset
  def reset
    user = User.first || User.new(email_address: "preview@example.com")
    PasswordsMailer.reset(user)
  end
end
