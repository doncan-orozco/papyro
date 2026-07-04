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

  private

  def render_navbar(user: nil)
    Current.user = user || GuestUser.new
    ApplicationController.render(Components::Public::Navbar.new)
  ensure
    Current.reset
  end
end
