require "application_system_test_case"

module Auth
  class SessionAccessibilityTest < ApplicationSystemTestCase
    test "sign in page uses stronger secondary text and keyboard-visible affordances" do
      visit new_session_path(locale: :en)

      assert_selector "h3", text: I18n.t("views.sessions.new.heading")
      assert_selector "a", text: I18n.t("views.sessions.new.back_to_home")

      classes = page.evaluate_script(<<~JS)
        (() => {
          const backLink = Array.from(document.querySelectorAll("a")).find((node) =>
            node.textContent.trim() === #{"← #{I18n.t("views.sessions.new.back_to_home")}".to_json}
          );
          const divider = Array.from(document.querySelectorAll("span")).find((node) =>
            node.textContent.trim() === #{I18n.t("views.registrations.new.continue_with_email_divider").to_json}
          );

          return {
            backLinkClass: backLink ? backLink.className : "",
            dividerClass: divider ? divider.className : ""
          };
        })()
      JS

      assert_includes classes["backLinkClass"], "text-foreground/80"
      assert_includes classes["backLinkClass"], "focus-visible:underline"
      assert_includes classes["dividerClass"], "text-foreground/80"
    end
  end
end
