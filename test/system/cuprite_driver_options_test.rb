require "application_system_test_case"

# Guards #278: the driver the tests actually use must carry our Ferrum options, not Ferrum's defaults.
class CupriteDriverOptionsTest < ApplicationSystemTestCase
  test "the cuprite driver uses the configured process and command timeouts" do
    options = page.driver.browser.options

    assert_equal 60, options.process_timeout
    assert_equal 60, options.timeout
    assert options.js_errors
  end
end
