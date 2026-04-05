require "test_helper"

class Components::Shared::LanguageToggleTest < ActiveSupport::TestCase
  test "renders locale labels" do
    html = ApplicationController.render(inline: "<%= render Components::Shared::LanguageToggle.new %>")

    assert_match(/Change language/, html)
    assert_match(/English/, html)
    assert_match(/Spanish/, html)
  end

  test "renders locale links" do
    html = ApplicationController.render(inline: "<%= render Components::Shared::LanguageToggle.new %>")

    assert_match(/locale=en/, html)
    assert_match(/locale=es/, html)
  end
end
