require "test_helper"

class Components::Shared::ThemeToggleTest < ActiveSupport::TestCase
  test "renders a chadcn dropdown with light, dark and system choices" do
    html = render_toggle

    assert_match(/data-slot="dropdown-menu-trigger"/, html)
    assert_match(/aria-label="Toggle theme"/, html)
    %w[Light Dark System].each { |choice| assert_match(/#{choice}/, html) }
  end

  test "each choice drives the chadcn theme controller through the menu content" do
    html = render_toggle

    %w[setLight setDark setSystem].each { |action| assert_match(/click->chadcn--theme##{action}/, html) }
    assert_match(/data-slot="dropdown-menu-content"[^>]*data-controller="[^"]*chadcn--theme/, html)
  end

  test "only the portaled menu content hosts the theme controller, under the key the pre-paint script reads" do
    hosts = Nokogiri::HTML(render_toggle).css('[data-controller~="chadcn--theme"]')

    assert_equal [ "dropdown-menu-content" ], hosts.map { |host| host["data-slot"] }
    hosts.each { |host| assert_equal "papyro-theme", host["data-chadcn--theme-storage-key-value"] }

    wrapper = Nokogiri::HTML(render_toggle).at_css("body > div")

    assert_nil wrapper["data-slot"]
    assert_nil wrapper["data-controller"]
  end

  test "marks each choice with the theme-check hook motion.css keys off" do
    html = render_toggle

    %w[light dark system].each { |theme| assert_match(/theme-check-#{theme}/, html) }
  end

  test "renders no legacy UI" do
    assert_no_match(/ui--|Components::Ui/, render_toggle)
  end

  private

  def render_toggle
    ApplicationController.render(Components::Shared::ThemeToggle.new, layout: false)
  end
end
