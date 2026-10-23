require "test_helper"

class Components::Shared::SocialLinkTest < ActiveSupport::TestCase
  test "renders an external link with the platform's accessible name" do
    {
      "twitter" => "Follow on Twitter",
      "github" => "View GitHub profile",
      "linkedin" => "Connect on LinkedIn"
    }.each do |platform, name|
      link = render_link(platform: platform, url: "https://example.com/#{platform}")

      assert_equal "https://example.com/#{platform}", link["href"], "href for #{platform}"
      assert_equal "_blank", link["target"], "platform #{platform}"
      assert_equal "noopener noreferrer", link["rel"], "platform #{platform}"
      assert_equal name, link["aria-label"], "platform #{platform}"
      assert_equal [ "lucide", "lucide-#{platform}" ], link.at_css("svg")["class"].split.first(2)
    end
  end

  test "falls back to a generic accessible name and no icon for other platforms" do
    link = render_link(platform: "mastodon", url: "https://example.com")

    assert_equal "Visit Mastodon", link["aria-label"]
    assert_nil link.at_css("svg")
  end

  test "uses chadcn button classes and merges caller attributes" do
    link = render_link(platform: "github", url: "https://github.com", class: "size-12", data: { testid: "gh" })

    assert_equal "button", link["data-slot"]
    assert_includes link["class"].split, "rounded-full"
    assert_includes link["class"].split, "size-12"
    assert_equal "gh", link["data-testid"]
  end

  test "caller aria attributes keep the accessible name" do
    link = render_link(platform: "github", url: "https://github.com", aria: { describedby: "bio" })

    assert_equal "View GitHub profile", link["aria-label"]
    assert_equal "bio", link["aria-describedby"]
  end

  test "caller attributes cannot drop the external-link safety attributes" do
    link = render_link(platform: "github", url: "https://github.com/papyro", rel: "", href: "https://evil.example")

    assert_equal "https://github.com/papyro", link["href"]
    assert_equal "noopener noreferrer", link["rel"]
  end

  test "accessible names are translated in Spanish" do
    %w[twitter github linkedin].each do |platform|
      link = I18n.with_locale(:es) { render_link(platform: platform, url: "https://example.com") }

      assert_equal I18n.t("components.ui.social_link.aria.#{platform}", locale: :es), link["aria-label"], platform
    end
  end

  private

  def render_link(**kwargs)
    html = ApplicationController.render(Components::Shared::SocialLink.new(**kwargs), layout: false)
    Nokogiri::HTML5.fragment(html).at_css("a")
  end
end
