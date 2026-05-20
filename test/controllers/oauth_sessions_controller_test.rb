require "test_helper"

class OauthSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "oauth-callback-1",
      info: {
        email: "oauth-callback@example.com",
        name: "OAuth Callback"
      }
    )
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  test "create starts a session for oauth user and redirects" do
    post "/auth/google_oauth2/callback"

    assert_redirected_to root_path(locale: I18n.default_locale)
    assert cookies[:session_id]
    user = User.find_by(provider: "google_oauth2", uid: "oauth-callback-1")

    assert user
    assert_predicate user, :verified?
    assert_equal "oauthcallback", user.profile.username
  end

  test "create also accepts get callback from provider redirect" do
    get "/auth/google_oauth2/callback"

    assert_redirected_to root_path(locale: I18n.default_locale)
    assert cookies[:session_id]
    user = User.find_by(provider: "google_oauth2", uid: "oauth-callback-1")

    assert user
    assert_predicate user, :verified?
  end

  test "create redirects to sign in when oauth user creation fails" do
    original_method = User.method(:from_omniauth)
    User.define_singleton_method(:from_omniauth) { |_auth| raise ArgumentError, "invalid oauth" }

    begin
      post "/auth/google_oauth2/callback"
    ensure
      User.define_singleton_method(:from_omniauth, original_method)
    end

    assert_redirected_to new_session_path
    assert_equal I18n.t("sessions.create.invalid_credentials"), flash[:alert]
    assert_nil cookies[:session_id]
  end

  test "auth failure route redirects to sign in" do
    get "/auth/failure"

    assert_redirected_to new_session_path
    assert_equal I18n.t("sessions.create.invalid_credentials"), flash[:alert]
  end
end
