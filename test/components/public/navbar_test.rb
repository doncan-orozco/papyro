require "test_helper"

class Components::Public::NavbarTest < ActiveSupport::TestCase
  test "renders logo with link to root" do
    html = render_navbar

    assert_match(/PAPYRO/, html)
    assert_match(%r{href="/en"}, html)
    assert_match(/role="img"/, html)
  end

  test "renders mobile search trigger" do
    html = render_navbar

    assert_match(/md:hidden flex-1/, html)
    assert_match(/search/, html)
    assert_match(/rounded-full/, html)
  end

  test "renders desktop search form" do
    html = render_navbar

    assert_match(/hidden md:block flex-1 max-w-2xl/, html)
  end

  test "renders sign in and sign up links when logged out" do
    html = render_navbar

    assert_match(/Sign in/, html)
    assert_match(/Get started/, html)
    assert_match(%r{href="/en/session/new"}, html)
    assert_match(%r{href="/en/sign_up}, html)
  end

  test "renders mobile menu sheet trigger when logged out" do
    html = render_navbar

    assert_match(/menu/, html)
    assert_match(/md:hidden/, html)
  end

  test "does not render write button when logged out" do
    html = render_navbar

    assert_no_match(/Write/, html)
  end

  test "renders logged-in state with write button and dropdown" do
    user = users(:admin)

    html = render_navbar(user:)

    assert_match(/Write/, html)
    assert_match(/My profile/i, html)
    assert_match(/Studio/, html)
    assert_match(/Sign out/, html)
  end

  test "renders language and theme toggles when logged in" do
    user = users(:admin)

    html = render_navbar(user:)

    assert_match(/Change language|Language/, html)
    assert_match(/Toggle theme/, html)
  end

  test "renders mobile settings sheet when logged in" do
    user = users(:admin)

    html = render_navbar(user:)

    assert_match(/Settings/, html)
    assert_match(/Light/, html)
    assert_match(/Dark/, html)
    assert_match(/System/, html)
    assert_match(/English/, html)
    assert_match(/Spanish/, html)
  end

  test "the mobile menu and the mobile search are chadcn sheets without local look overrides" do
    [ nil, users(:admin) ].each do |user|
      header = render_navbar(user:)[%r{<header.*</header>}m]
      labels = Nokogiri::HTML(header).css('[data-slot="sheet-trigger"]').map { |trigger| trigger["aria-label"] }

      assert_equal [ I18n.t("components.public.navbar.mobile.search_label"), I18n.t("components.public.navbar.mobile.menu_label") ], labels
      assert_no_match(/data-slot="dialog-trigger"/, header)
      assert_no_match(/data-\[state=[^\]]+\]:!/, header)
    end
  end

  test "the mobile theme buttons drive chadcn--theme under the papyro-theme key" do
    [ nil, users(:admin) ].each do |user|
      html = render_navbar(user:)

      %w[setLight setDark setSystem].each { |action| assert_match(/click->chadcn--theme##{action}/, html) }
      assert_match(/data-chadcn--theme-storage-key-value="papyro-theme"/, html)
    end
  end

  test "the account menu is a chadcn dropdown with link items" do
    html = render_navbar(user: users(:admin))

    assert_match(/data-slot="dropdown-menu-trigger"[^>]*aria-label="Settings"|aria-label="Settings"[^>]*data-slot="dropdown-menu-trigger"/, html)
    assert_match(/<a[^>]*data-slot="dropdown-menu-item"/, html)
    assert_match(/data-variant="destructive"/, html)
  end

  test "renders no legacy UI when logged out or in" do
    [ nil, users(:admin) ].each do |user|
      header = render_navbar(user:)[%r{<header.*</header>}m]

      assert_no_match(/ui--|ui__|Components::Ui/, header)
    end
  end

  private

  def render_navbar(user: nil)
    Current.user = user || GuestUser.new
    ApplicationController.render(Components::Public::Navbar.new)
  ensure
    Current.reset
  end
end
