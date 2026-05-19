require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path

    assert_response :success
  end

  test "new renders google oauth sign-in button" do
    get new_session_path

    assert_response :success
    assert_includes response.body, "action=\"/auth/google_oauth2\""
    assert_includes response.body, "data-turbo=\"false\""
    assert_includes response.body, I18n.t("views.sessions.new.sign_in_with_google")
  end

  test "new includes sign-up link" do
    get new_session_path

    assert_response :success
    assert_includes response.body, I18n.t("views.sessions.new.sign_up")
    assert_includes response.body, sign_up_path
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path(locale: I18n.default_locale)
    assert cookies[:session_id]
  end

  test "create sets session cookie domain for subdomain sharing" do
    host! "lvh.me"
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path(locale: I18n.default_locale)
    assert cookies[:session_id]

    set_cookie_headers = Array(response.headers["Set-Cookie"])

    assert(
      set_cookie_headers.any? { |header| header.downcase.include?("domain=lvh.me") },
      "Expected Set-Cookie to include domain=lvh.me, got: #{set_cookie_headers.inspect}"
    )
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "create with invalid email renders errors" do
    post session_path, params: { email_address: "invalid-email", password: "password" }

    assert_response :unprocessable_entity
    assert_match /must be a valid email address/, response.body
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_predicate cookies[:session_id], :blank?, "Expected session cookie to be blank but was #{cookies[:session_id].inspect}"
  end
end
