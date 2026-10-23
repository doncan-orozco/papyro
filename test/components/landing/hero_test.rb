require "test_helper"

class Components::Landing::HeroTest < ActiveSupport::TestCase
  test "renders the headline and a non-submitting chadcn CTA" do
    doc = Nokogiri::HTML5.fragment(ApplicationController.render(Components::Landing::Hero.new, layout: false))

    assert_equal I18n.t("components.landing.hero.title"), doc.at_css("h1").text.strip

    cta = doc.at_css("button[data-slot='button']")

    assert_equal "button", cta["type"]
    assert_equal "secondary", cta["data-variant"]
    assert_equal I18n.t("components.landing.hero.cta"), cta.text.strip
  end
end
