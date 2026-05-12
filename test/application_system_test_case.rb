require "test_helper"

# data-testid is the standard test attribute in this app.
# Capybara.test_id makes standard finders also match by data-testid.
# The custom :testid selector enables `find(:testid, "name")` and
# `assert_selector :testid, "name"` for explicit, readable lookups.
Capybara.test_id = "data-testid"
Capybara.add_selector(:testid) do
  css { |value| "[data-testid='#{value}']" }
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  setup do
    I18n.locale = I18n.default_locale
  end

  def sign_in_as(user)
    session = user.sessions.create!
    signed_session_cookie = signed_session_cookie_value(session.id)

    visit root_path
    page.driver.browser.manage.add_cookie(name: "session_id", value: signed_session_cookie, path: "/")
  end

  def sign_out
    page.driver.browser.manage.delete_cookie("session_id")
  end

  private

  def signed_session_cookie_value(session_id)
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = session_id
    end[:session_id]
  end
end
