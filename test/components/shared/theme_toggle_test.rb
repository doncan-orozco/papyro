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

  test "the choice persists under the key the layouts' pre-paint script reads" do
    html = render_toggle

    assert_operator html.scan('data-chadcn--theme-storage-key-value="papyro-theme"').size, :>=, 2
    assert_no_match(/storage-key-value="(?!papyro-theme)/, html)
  end

  test "the active choice shows its checkmark through the theme-check classes" do
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
