require "test_helper"

class Components::Landing::ContactTest < ActiveSupport::TestCase
  test "renders a non-submitting email CTA" do
    cta = render_contact.at_css("button[data-slot='button']")

    assert_equal "button", cta["type"]
    assert_equal I18n.t("components.landing.contact.email"), cta.text.strip
  end

  test "renders the three social links as safe external links" do
    links = render_contact.css("a[target='_blank']")

    assert_equal %w[twitter github linkedin], links.map { |link| link.at_css("svg")["class"][/lucide-(\w+)/, 1] }
    links.each { |link| assert_equal "noopener noreferrer", link["rel"] }
  end

  private

  def render_contact
    Nokogiri::HTML5.fragment(ApplicationController.render(Components::Landing::Contact.new, layout: false))
  end
end
