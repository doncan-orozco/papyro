require "application_system_test_case"

module Settings
  class SecurityEditFlowTest < ApplicationSystemTestCase
    setup do
      @user = users(:admin)
      @user.update!(password: "password", password_confirmation: "password")
      sign_in_with_retry(@user)
    end

    test "user visits and views security settings page" do
      visit edit_settings_security_path

      assert_text I18n.t("users.settings.security.title")
      assert_text I18n.t("users.settings.security.description")
      assert_selector "form"
    end

    test "user updates password with correct current password" do
      visit edit_settings_security_path

      fill_in I18n.t("users.settings.security.current_password_label"), with: "password"
      fill_in I18n.t("users.settings.security.password_label"), with: "new-secure-password-123"
      fill_in I18n.t("users.settings.security.password_confirmation_label"), with: "new-secure-password-123"

      submit_security_form

      assert_current_path %r{/settings/security(?:/edit)?}
      assert_selector "form"

      @user.reload

      assert @user.authenticate("new-secure-password-123")
    end

    test "user can update password and it persists" do
      visit edit_settings_security_path

      fill_in I18n.t("users.settings.security.current_password_label"), with: "password"
      fill_in I18n.t("users.settings.security.password_label"), with: "brand-new-password-456"
      fill_in I18n.t("users.settings.security.password_confirmation_label"), with: "brand-new-password-456"

      submit_security_form

      assert_current_path %r{/settings/security(?:/edit)?}
      assert_selector "form"

      # Verify password was actually updated in database
      @user.reload

      assert @user.authenticate("brand-new-password-456")
      assert_not @user.authenticate("password")
    end

    test "security settings sidebar uses non-color active state cues" do
      visit edit_settings_security_path

      classes = page.evaluate_script(<<~JS)
        (() => {
          const securityLink = Array.from(document.querySelectorAll("a")).find((node) =>
            node.textContent.trim() === #{I18n.t("users.settings.security.title").to_json}
          );

          return {
            securityClass: securityLink ? securityLink.className : ""
          };
        })()
      JS

      assert_includes classes["securityClass"], "ring-1"
      assert_includes classes["securityClass"], "font-semibold"
    end

    private

    def sign_in_with_retry(user)
      attempts = 0

      begin
        attempts += 1
        sign_in_as(user)
      rescue Ferrum::TimeoutError
        raise if attempts >= 2

        Capybara.reset_sessions!
        retry
      end
    end

    def submit_security_form
      form = find("form[action$='#{settings_security_path}']", visible: :all)
      page.execute_script("arguments[0].submit()", form)
    end
  end
end
