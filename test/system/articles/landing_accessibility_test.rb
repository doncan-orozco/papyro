require "application_system_test_case"

module Articles
  class LandingAccessibilityTest < ApplicationSystemTestCase
    setup do
      @article = Article.create!(
        user: users(:admin),
        title: "Accessible Landing Story",
        slug: "accessible-landing-story",
        excerpt: "A concise summary for accessibility checks.",
        body: "Landing story body content"
      )

      @article.article_translations.find_by!(locale: "en").update!(status: :published, published_at: Time.current)
      @article.update!(published_at: Time.current)
    end

    test "landing cards include semantic metadata and concise accessible link labels" do
      visit root_path(locale: :en)

      assert_selector "a[aria-label*='Accessible Landing Story']"
      assert_selector "a[aria-label*='by']"
      assert_selector "a[aria-label*='min read']"

      assert_selector "a[aria-label*='Accessible Landing Story'] time[datetime]"
    end

    test "landing cards provide keyboard-focus parity classes for title and media" do
      visit root_path(locale: :en)

      selectors = page.evaluate_script(<<~JS)
        (() => {
          const card = Array.from(document.querySelectorAll("a[aria-label]")).find((node) =>
            node.getAttribute("aria-label").includes("Accessible Landing Story")
          );

          if (!card) return null;

          const title = card.querySelector("h3");
          const media = card.querySelector("[class*='group-focus-visible:scale-105']");

          return {
            titleClass: title ? title.className : "",
            mediaClass: media ? media.className : ""
          };
        })()
      JS

      assert selectors, "Expected to find the accessibility test card"
      assert_includes selectors["titleClass"], "group-focus-visible:underline"
      assert_includes selectors["mediaClass"], "group-focus-visible:scale-105"
    end
  end
end
