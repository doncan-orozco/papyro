require "test_helper"
require "uri"
require "capybara/cuprite"

# data-testid is the standard test attribute in this app.
# Capybara.test_id makes standard finders also match by data-testid.
# The custom :testid selector enables `find(:testid, "name")` and
# `assert_selector :testid, "name"` for explicit, readable lookups.
Capybara.test_id = "data-testid"
Capybara.add_selector(:testid) do
  css { |value| "[data-testid='#{value}']" }
end

Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(
    app,
    browser_options: {},
    headless: %w[0 false].exclude?(ENV["HEADLESS"]),
    window_size: [ 1400, 1400 ],
    js_errors: true,
    timeout: 60,
    process_timeout: 60
  )
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite

  setup do
    I18n.locale = I18n.default_locale
  end

  def sign_in_as(user, with_studio_cookie: false)
    session = user.sessions.create!
    @signed_in_session = session
    signed_session_cookie = signed_session_cookie_value(session.id)

    # Keep auth working on the default Capybara host.
    page_uri = URI.parse(Capybara.current_session.server.base_url)
    set_session_cookie_with_retry(domain: page_uri.host, value: signed_session_cookie)

    return unless with_studio_cookie

    # Set a shared parent-domain cookie for cross-subdomain studio flows.
    page.driver.browser.cookies.set(
      name: "session_id",
      value: signed_session_cookie,
      domain: "lvh.me",
      path: "/"
    )

    set_studio_session_cookie(signed_session_cookie)
  end

  def sign_out
    @signed_in_session&.destroy
    @signed_in_session = nil
    Current.session = nil
    Current.user = nil

    current_url = page.current_url
    page.driver.browser.cookies.remove(name: "session_id", url: current_url)

    base_uri = URI.parse(Capybara.current_session.server.base_url)
    page.driver.browser.cookies.remove(name: "session_id", url: "http://lvh.me:#{base_uri.port}")
    page.driver.browser.cookies.remove(name: "session_id", url: "http://studio.lvh.me:#{base_uri.port}")
  rescue Ferrum::BrowserError
    # Ignore missing cookie/domain combinations.
  end

  private

  def signed_session_cookie_value(session_id)
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = session_id
    end[:session_id]
  end

  def set_session_cookie_with_retry(domain:, value:)
    page.driver.browser.cookies.set(
      name: "session_id",
      value: value,
      domain: domain,
      path: "/"
    )
  rescue Ferrum::TimeoutError
    visit "/up"
    page.driver.browser.cookies.set(
      name: "session_id",
      value: value,
      domain: domain,
      path: "/"
    )
  end

  def set_studio_session_cookie(cookie_value)
    base_uri = URI.parse(Capybara.current_session.server.base_url)
    studio_base_url = "http://studio.lvh.me:#{base_uri.port}"

    # Use /up so we remain on studio.lvh.me without hitting auth redirects.
    visit "#{studio_base_url}/up"
    page.driver.browser.cookies.set(
      name: "session_id",
      value: cookie_value,
      domain: ".lvh.me",
      path: "/"
    )
  end
end
