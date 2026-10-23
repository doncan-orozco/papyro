require "test_helper"

class Components::Shared::SocialLinkTest < ActiveSupport::TestCase
  test "renders an external link with the platform's accessible name" do
    {
      "twitter" => "Follow on Twitter",
      "github" => "View GitHub profile",
      "linkedin" => "Connect on LinkedIn"
    }.each do |platform, name|
      link = render_link(platform: platform, url: "https://example.com/#{platform}")

      assert_equal "https://example.com/#{platform}", link["href"]
      assert_equal "_blank", link["target"]
      assert_equal "noopener noreferrer", link["rel"]
      assert_equal name, link["aria-label"]
      assert_equal "lucide lucide-#{platform}", link.at_css("svg")["class"]
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

  private

  def render_link(**kwargs)
    html = ApplicationController.render(Components::Shared::SocialLink.new(**kwargs), layout: false)
    Nokogiri::HTML5.fragment(html).at_css("a")
  end
end
