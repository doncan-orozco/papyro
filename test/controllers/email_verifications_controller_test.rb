require "test_helper"

class EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  test "show verifies user and starts session for unauthenticated visitor" do
    user = User.create!(
      email_address: "verify-me@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_profile!(display_name: "Verify Me", username: "verifyme")

    token = user.generate_token_for(:email_verification)

    get email_verification_path(token)

    assert_redirected_to root_path(locale: I18n.locale)
    assert_predicate user.reload, :verified?
    assert cookies[:session_id]
  end

  test "show redirects for invalid token" do
    get email_verification_path("invalid-token")

    assert_redirected_to new_session_path
    assert_equal I18n.t("users.email_verification.invalid_or_expired"), flash[:alert]
  end
end
