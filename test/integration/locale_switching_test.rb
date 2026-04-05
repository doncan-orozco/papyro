require "test_helper"

class LocaleSwitchingTest < ActionDispatch::IntegrationTest
  test "uses explicit locale param and propagates it through the public navbar" do
    get root_path(locale: :es)

    assert_response :success
    assert_select "html[lang='es']"
    assert_select "a[href='#{new_session_path}']", text: "Iniciar sesion"
  end

  test "persists selected locale in session across requests" do
    get root_path(locale: :es)

    get root_path

    assert_response :success
    assert_select "html[lang='es']"
    assert_select "a[href='#{new_session_path}']", text: "Iniciar sesion"
  end

  test "falls back to browser locale when no locale is stored" do
    get root_path, headers: { "HTTP_ACCEPT_LANGUAGE" => "es-MX,es;q=0.9,en;q=0.8" }

    assert_response :success
    assert_select "html[lang='es']"
  end

  test "ignores unsupported locale params" do
    get root_path(locale: :fr)

    assert_response :success
    assert_select "html[lang='en']"
    assert_select "a[href='#{new_session_path}']", text: "Sign in"
  end

  test "renders the admin navbar in the selected locale" do
    sign_in_as(users(:admin))

    get admin_root_path(locale: :es)

    assert_response :success
    assert_select "html[lang='es']"
    assert_select "a[href='#{admin_logout_path}']", text: "Cerrar sesion"
  end
end
