require "application_system_test_case"

module Settings
  class SecurityEditFlowTest < ApplicationSystemTestCase
    setup do
      @user = users(:admin)
      sign_in_as(@user)
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

      click_button I18n.t("users.settings.security.submit")

      assert_text I18n.t("users.operations.update_password.success")
      assert_current_path edit_settings_security_path

      @user.reload

      assert @user.authenticate("new-secure-password-123")
    end

    test "user sees error when entering incorrect current password" do
      visit edit_settings_security_path

      fill_in I18n.t("users.settings.security.current_password_label"), with: "wrong-password"
      fill_in I18n.t("users.settings.security.password_label"), with: "new-secure-password-123"
      fill_in I18n.t("users.settings.security.password_confirmation_label"), with: "new-secure-password-123"

      click_button I18n.t("users.settings.security.submit")

      # Page stays on security edit with error
      assert_current_path edit_settings_security_path
      assert_text "Current password is incorrect"

      @user.reload

      assert @user.authenticate("password")
    end

    test "user sees error when password and confirmation don't match" do
      visit edit_settings_security_path

      fill_in I18n.t("users.settings.security.current_password_label"), with: "password"
      fill_in I18n.t("users.settings.security.password_label"), with: "new-secure-password-123"
      fill_in I18n.t("users.settings.security.password_confirmation_label"), with: "different-password"

      click_button I18n.t("users.settings.security.submit")

      # Page stays on security edit with error
      assert_current_path edit_settings_security_path
      assert_text "Password confirmation must match password"

      @user.reload

      assert @user.authenticate("password")
    end

    test "user can update password and it persists" do
      visit edit_settings_security_path

      fill_in I18n.t("users.settings.security.current_password_label"), with: "password"
      fill_in I18n.t("users.settings.security.password_label"), with: "brand-new-password-456"
      fill_in I18n.t("users.settings.security.password_confirmation_label"), with: "brand-new-password-456"

      click_button I18n.t("users.settings.security.submit")

      assert_text I18n.t("users.operations.update_password.success")
      assert_current_path edit_settings_security_path

      # Verify password was actually updated in database
      @user.reload

      assert @user.authenticate("brand-new-password-456")
      assert_not @user.authenticate("password")
    end
  end
end
