require "test_helper"

class Components::Public::Navbar::MobileMenuTest < ActiveSupport::TestCase
  test "renders guest CTAs only when guest" do
    guest = render_menu(signed_out: true)
    member = render_menu(signed_out: false)

    assert_includes guest.css("a").map { |a| a["href"] }, "/en/session/new"
    assert guest.css("a").any? { |a| a["href"].to_s.start_with?("/en/sign_up") }
    assert_not_includes member.css("a").map { |a| a["href"] }, "/en/session/new"
    assert member.css("a").none? { |a| a["href"].to_s.start_with?("/en/sign_up") }
  end

  test "hosts chadcn--theme under the papyro-theme key" do
    [ true, false ].each do |signed_out|
      host = render_menu(signed_out:).at_css('[data-controller~="chadcn--theme"]')

      assert host
      assert_equal "papyro-theme", host["data-chadcn--theme-storage-key-value"]
      assert_equal %w[setLight setDark setSystem].map { |a| "click->chadcn--theme##{a}" }, host.css("button").map { |b| b["data-action"] }
    end
  end

  test "renders ghost link buttons for each language" do
    links = render_menu(signed_out: false).css("a").select { |a| %w[/en /es].include?(a["href"]) }

    assert_equal %w[/en /es], links.map { |a| a["href"] }
    assert_equal %w[ghost ghost], links.map { |a| a["data-variant"] }
  end

  private

  def render_menu(signed_out:)
    html = ApplicationController.render(Components::Public::Navbar::MobileMenu.new(signed_out:))
    Nokogiri::HTML(html)
  end
end
