require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path

    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to studio_articles_path(locale: I18n.locale)
    assert cookies[:session_id]
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
