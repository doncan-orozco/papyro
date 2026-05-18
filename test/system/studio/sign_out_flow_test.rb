require "application_system_test_case"

module Studio
  class SignOutFlowTest < ApplicationSystemTestCase
    setup do
      @user = users(:admin)
      sign_in_as(@user, with_studio_cookie: true)
    end

    test "sign out from studio dropdown clears session and redirects to public login" do
      visit studio_articles_url

      sign_out

      visit studio_articles_url

      assert_current_path(%r{\Ahttp://lvh\.me:\d+/en/session/new\z}, url: true)
    end

    private

    def studio_articles_url
      base_uri = URI.parse(Capybara.current_session.server.base_url)
      "http://studio.lvh.me:#{base_uri.port}/articles"
    end
  end
end
