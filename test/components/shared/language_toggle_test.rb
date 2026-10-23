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

    assert_match(%r{href="/en"}, html)
    assert_match(%r{href="/es"}, html)
  end

  test "renders a chadcn dropdown whose locale items are links marking the active locale" do
    html = ApplicationController.render(inline: "<%= render Components::Shared::LanguageToggle.new %>")

    assert_match(/data-slot="dropdown-menu-trigger"/, html)
    assert_match(%r{<a[^>]*data-slot="dropdown-menu-item"[^>]*href="/en"|<a[^>]*href="/en"[^>]*data-slot="dropdown-menu-item"}, html)
    assert_match(/aria-current="true"/, html)
    assert_no_match(/ui--|Components::Ui/, html)
  end
end
