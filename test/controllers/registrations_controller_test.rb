require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get sign_up_path

    assert_response :success
  end

  test "new renders google oauth sign-up button" do
    get sign_up_path

    assert_response :success
    assert_includes response.body, "action=\"/auth/google_oauth2\""
    assert_includes response.body, "data-turbo=\"false\""
    assert_includes response.body, I18n.t("views.registrations.new.sign_up_with_google")
  end

  test "create with valid credentials" do
    assert_enqueued_emails 1 do
      post sign_up_path, params: {
        user: {
          email_address: "fresh_writer@example.com",
          password: "password123"
        }
      }
    end

    mail_job = enqueued_jobs.find { |job| job[:job] == ActionMailer::MailDeliveryJob }

    assert mail_job
    assert_equal "EmailVerificationsMailer", mail_job[:args][0]
    assert_equal "verify", mail_job[:args][1]

    user = User.find_by(email_address: "fresh_writer@example.com")

    assert_redirected_to root_path(locale: I18n.default_locale)
    assert cookies[:session_id]
    assert user
    assert_not user.verified?
    assert_equal "fresh_writer", user.profile.username
    assert_equal "Fresh Writer", user.profile.display_name
  end

  test "create with invalid email renders errors" do
    post sign_up_path, params: {
      user: {
        email_address: "invalid-email",
        password: "password123"
      }
    }

    assert_response :unprocessable_entity
    assert_match /must be a valid email address/, response.body
    assert_nil User.find_by(email_address: "invalid-email")
  end

  test "create with duplicate email renders errors" do
    User.create!(
      email_address: "duplicate_signup@example.com",
      password: "password123",
      password_confirmation: "password123"
    ).tap { |u| u.create_profile!(display_name: "Existing Writer", username: "existing_writer") }

    post sign_up_path, params: {
      user: {
        email_address: "duplicate_signup@example.com",
        password: "password999"
      }
    }

    assert_response :unprocessable_entity
    assert_match(/has already been taken/, response.body)
  end

  test "newly registered user stays authenticated on studio subdomain" do
    host! "lvh.me"

    post sign_up_path, params: {
      user: {
        email_address: "cross_subdomain_signup@example.com",
        password: "password123"
      }
    }

    assert_redirected_to root_path(locale: I18n.default_locale)
    assert cookies[:session_id]

    host! "studio.lvh.me"
    get "/articles"

    assert_response :success
  end
end
