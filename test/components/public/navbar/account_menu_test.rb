require "test_helper"

class Components::Public::Navbar::AccountMenuTest < ActiveSupport::TestCase
  test "renders the four link items with a destructive sign out" do
    doc = render_menu(users(:admin))
    items = doc.css('a[data-slot="dropdown-menu-item"]')

    assert_equal 4, items.size
    assert_equal [ "_top" ], items.map { |item| item["data-turbo-frame"] }.uniq
    destructive = items.select { |item| item["data-variant"] == "destructive" }

    assert_equal 1, destructive.size
    assert_equal "delete", destructive.first["data-turbo-method"]
    assert_equal I18n.t("components.public.navbar.dropdown.sign_out"), destructive.first.text.strip
    assert_includes items.map { |item| item["href"] }, "https://studio.example.test/articles"
  end

  test "renders the avatar initial in the labelled trigger" do
    user = users(:admin)
    doc = render_menu(user)
    trigger = doc.at_css('[data-slot="dropdown-menu-trigger"]')
    expected = (user.profile&.display_name.presence || user.email_address).first.upcase

    assert_equal I18n.t("components.public.navbar.dropdown.settings"), trigger["aria-label"]
    assert_equal expected, trigger.text.strip
  end

  private

  def render_menu(user)
    html = ApplicationController.render(
      Components::Public::Navbar::AccountMenu.new(user:, studio_href: "https://studio.example.test/articles")
    )
    Nokogiri::HTML(html)
  end
end
