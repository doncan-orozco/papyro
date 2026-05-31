require "application_system_test_case"

module Pages
  class AboutAccessibilityTest < ApplicationSystemTestCase
    test "about page exposes accessible social links and readable secondary content classes" do
      visit about_path(locale: :en)

      assert_selector "h1", text: I18n.t("pages.about.index.title")
      assert_selector "a[aria-label='#{I18n.t("pages.about.index.engineer_linkedin_label")}']"
      assert_selector "a[aria-label='#{I18n.t("pages.about.index.designer_linkedin_label")}']"

      classes = page.evaluate_script(<<~JS)
        (() => {
          const intro = Array.from(document.querySelectorAll("p")).find((node) =>
            node.textContent.trim() === #{I18n.t("pages.about.index.intro").to_json}
          );
          const engineerLink = Array.from(document.querySelectorAll("a[aria-label]")).find((node) =>
            node.getAttribute("aria-label") === #{I18n.t("pages.about.index.engineer_linkedin_label").to_json}
          );

          return {
            introClass: intro ? intro.className : "",
            engineerLinkClass: engineerLink ? engineerLink.className : ""
          };
        })()
      JS

      assert_includes classes["introClass"], "text-foreground/75"
      assert_includes classes["engineerLinkClass"], "focus-visible:underline"
    end
  end
end
