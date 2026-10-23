require "test_helper"

class Components::Public::Navbar::MobileMenuTest < ActiveSupport::TestCase
  test "renders guest CTAs only when guest" do
    guest = render_menu(guest: true)
    member = render_menu(guest: false)

    assert_includes guest.css("a").map { |a| a["href"] }, "/en/session/new"
    assert guest.css("a").any? { |a| a["href"].to_s.start_with?("/en/sign_up") }
    assert_not_includes member.css("a").map { |a| a["href"] }, "/en/session/new"
    assert member.css("a").none? { |a| a["href"].to_s.start_with?("/en/sign_up") }
  end

  test "hosts chadcn--theme under the papyro-theme key" do
    [ true, false ].each do |guest|
      host = render_menu(guest:).at_css('[data-controller~="chadcn--theme"]')

      assert host
      assert_equal "papyro-theme", host["data-chadcn--theme-storage-key-value"]
      assert_equal 3, host.css("button").size
    end
  end

  test "renders ghost link buttons for each language" do
    links = render_menu(guest: false).css("a").select { |a| %w[/en /es].include?(a["href"]) }

    assert_equal %w[/en /es], links.map { |a| a["href"] }
    assert links.all? { |a| a["data-variant"] == "ghost" || a["class"].to_s.include?("justify-start") }
  end

  private

  def render_menu(guest:)
    html = ApplicationController.render(Components::Public::Navbar::MobileMenu.new(guest:))
    Nokogiri::HTML(html)
  end
end
