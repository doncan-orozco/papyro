require "test_helper"

module Admin
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    setup { @user = users(:one) }

    test "new renders admin login page" do
      get admin_login_path

      assert_response :success
    end

    test "create with valid credentials redirects to admin root" do
      post admin_session_path, params: { email_address: @user.email_address, password: "password" }

      assert_redirected_to admin_root_path
      assert cookies[:session_id]
    end

    test "create with invalid credentials re-renders login with error" do
      post admin_session_path, params: { email_address: @user.email_address, password: "wrong" }

      assert_response :unauthorized
      assert cookies[:session_id].blank?
    end

    test "destroy logs out and redirects to admin login" do
      sign_in_as(@user)

      delete admin_session_path

      assert_redirected_to admin_login_path
      assert cookies[:session_id].blank?, "Expected session cookie to be blank but was #{cookies[:session_id].inspect}"
    end
  end
end
