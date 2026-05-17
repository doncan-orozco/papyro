require "application_system_test_case"

module Settings
  class ProfileEditFlowTest < ApplicationSystemTestCase
    setup do
      @user = users(:admin)
      @user.update!(email_address: "admin@example.com", password: "password", password_confirmation: "password")
      @user.profile.update!(
        display_name: "Admin Writer",
        username: "admin",
        bio: "Writes about building software.",
        location: nil,
        website_url: nil,
        x_handle: nil,
        linkedin_handle: nil
      )
      sign_in_as(@user)
    end

    test "user visits and views profile settings page" do
      visit edit_settings_profile_path

      assert_text I18n.t("users.settings.profile.title")
      assert_text I18n.t("users.settings.profile.description")
      assert_selector "form"
    end

    test "user updates display name successfully" do
      visit edit_settings_profile_path

      new_display_name = "Jane Developer"
      fill_in I18n.t("users.settings.profile.display_name_label"), with: new_display_name

      assert_field I18n.t("users.settings.profile.display_name_label"), with: new_display_name
    end

    test "user updates email address successfully" do
      visit edit_settings_profile_path

      new_email = "newemail@example.com"
      fill_in I18n.t("users.settings.profile.email_label"), with: new_email

      submit_profile_form

      assert_text I18n.t("users.operations.update_profile.success")

      @user.reload

      assert_equal new_email, @user.email_address
    end

    test "user edits multiple profile fields at once" do
      visit edit_settings_profile_path

      fill_in I18n.t("users.settings.profile.display_name_label"), with: "New Name"
      fill_in I18n.t("users.settings.profile.bio_label"), with: "Software developer and writer"
      fill_in I18n.t("users.settings.profile.location_label"), with: "San Francisco, CA"
      fill_in I18n.t("users.settings.profile.website_url_label"), with: "https://example.com"
      fill_in I18n.t("users.settings.profile.x_handle_label"), with: "janedeveloper"
      fill_in I18n.t("users.settings.profile.linkedin_handle_label"), with: "jane-developer"

      assert_field I18n.t("users.settings.profile.display_name_label"), with: "New Name"
      assert_field I18n.t("users.settings.profile.bio_label"), with: "Software developer and writer"
      assert_field I18n.t("users.settings.profile.location_label"), with: "San Francisco, CA"
      assert_field I18n.t("users.settings.profile.website_url_label"), with: "https://example.com"
      assert_field I18n.t("users.settings.profile.x_handle_label"), with: "janedeveloper"
      assert_field I18n.t("users.settings.profile.linkedin_handle_label"), with: "jane-developer"
    end

    test "user uploads portrait photo" do
      visit edit_settings_profile_path

      attach_file I18n.t("users.settings.profile.portrait_label"), Rails.root.join("public/icon.png")

      # Wait for preview to load
      assert_selector "[data-settings--profiles--portrait-preview-target='canvas'] img"

      submit_profile_form

      @user.reload

      assert_predicate @user.profile.portrait, :attached?
    end

    test "portrait persists when saving profile without uploading new photo" do
      @user.profile.portrait.attach(io: File.open(Rails.root.join("public/icon.png")), filename: "original.png", content_type: "image/png")

      visit edit_settings_profile_path

      fill_in I18n.t("users.settings.profile.display_name_label"), with: "Updated Name"

      submit_profile_form

      assert_text I18n.t("users.operations.update_profile.success")

      @user.reload

      assert_predicate @user.profile.portrait, :attached?
      assert_equal "Updated Name", @user.profile.display_name
    end

    test "user sees validation errors on invalid email" do
      other_user = users(:one)
      visit edit_settings_profile_path

      fill_in I18n.t("users.settings.profile.email_label"), with: other_user.email_address

      submit_profile_form

      # Page stays on profile edit with error
      assert_current_path %r{/settings/profile(?:/edit)?}
      assert_text "Email address has already been taken"
    end

    test "user can cancel and return to profile" do
      visit edit_settings_profile_path

      click_link I18n.t("users.settings.profile.cancel")

      # Cancel link goes to author profile page
      assert_current_path %r{/@[^/]+}
    end

    private

    def submit_profile_form
      page.execute_script(%(document.querySelector("form[action='#{settings_profile_path}']").submit()))
    end
  end
end
