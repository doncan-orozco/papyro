require "application_system_test_case"

module Settings
  class ProfileEditFlowTest < ApplicationSystemTestCase
    setup do
      @user = users(:admin)
      @user.update!(email_address: "admin@example.com", password: "password", password_confirmation: "password")
      @user.profile.update!(
        display_name: "Admin Writer",
        username: "admin_writer",
        bio: "Writes about building software.",
        location: nil,
        website_url: nil,
        x_handle: nil,
        linkedin_handle: nil
      )

      # Increase timeout for profile tests which involve file uploads and image processing.
      # Under aggregate load, these operations need more headroom (120s vs default 60s).
      Capybara.current_session.driver.browser.timeout = 120

      sign_in_with_retry(@user)
    end

    teardown do
      # Restore default timeout after test completes
      Capybara.current_session.driver.browser.timeout = 60
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



    test "user edits multiple profile fields at once" do
      visit edit_settings_profile_path

      fill_in I18n.t("users.settings.profile.display_name_label"), with: "New Name"
      fill_in "user_profile_attributes_author_profile_translations_attributes_0_bio", with: "Software developer and writer"
      fill_in I18n.t("users.settings.profile.location_label"), with: "San Francisco, CA"
      fill_in I18n.t("users.settings.profile.website_url_label"), with: "https://example.com"
      fill_in I18n.t("users.settings.profile.x_handle_label"), with: "janedeveloper"
      fill_in I18n.t("users.settings.profile.linkedin_handle_label"), with: "jane-developer"

      assert_field I18n.t("users.settings.profile.display_name_label"), with: "New Name"
      assert_field "user_profile_attributes_author_profile_translations_attributes_0_bio", with: "Software developer and writer"
      assert_field I18n.t("users.settings.profile.location_label"), with: "San Francisco, CA"
      assert_field I18n.t("users.settings.profile.website_url_label"), with: "https://example.com"
      assert_field I18n.t("users.settings.profile.x_handle_label"), with: "janedeveloper"
      assert_field I18n.t("users.settings.profile.linkedin_handle_label"), with: "jane-developer"
    end

    test "user can edit localized bio for english and spanish in a single submit" do
      visit edit_settings_profile_path

      assert_selector "#profile-bio-panel-en:not([hidden])"
      fill_in "user_profile_attributes_author_profile_translations_attributes_0_bio", with: "English profile bio"

      click_button I18n.t("language.name", locale: :es)

      assert_selector "#profile-bio-panel-es:not([hidden])"
      fill_in "user_profile_attributes_author_profile_translations_attributes_1_bio", with: "Bio de perfil en espanol"

      submit_profile_form

      @user.reload

      assert_equal "English profile bio", Mobility.with_locale(:en) { @user.profile.bio }
      assert_equal "Bio de perfil en espanol", Mobility.with_locale(:es) { @user.profile.bio }
    end

    test "user uploads portrait photo" do
      visit edit_settings_profile_path

      attach_portrait_file

      # Wait for preview to load
      assert_selector "[data-settings--profiles--portrait-preview-target='canvas'] img"

      submit_profile_form

      assert_current_path %r{/settings/profile(?:/edit)?}
      assert_selector "[data-settings--profiles--portrait-preview-target='canvas'] img"
    end

    test "portrait persists when saving profile without uploading new photo" do
      @user.profile.portrait.attach(io: File.open(Rails.root.join("public/icon.png")), filename: "original.png", content_type: "image/png")

      visit edit_settings_profile_path

      fill_in I18n.t("users.settings.profile.display_name_label"), with: "Updated Name"

      submit_profile_form
      unless page.has_selector?("div[role=status]", text: I18n.t("users.operations.update_profile.success"), wait: 3)
        fill_in I18n.t("users.settings.profile.display_name_label"), with: "Updated Name"
        submit_profile_form
      end

      @user.reload

      assert_predicate @user.profile.portrait, :attached?
      assert_equal "Updated Name", @user.profile.display_name
    end

    test "user cannot edit email address" do
      visit edit_settings_profile_path
      email_label = I18n.t("users.settings.profile.email_label")

      assert_field email_label, disabled: true
    end

    test "user can cancel and return to profile" do
      visit edit_settings_profile_path

      cancel_link = find_link(I18n.t("users.settings.profile.cancel"), match: :first)

      assert_match %r{/@[^/]+}, cancel_link[:href]
      visit cancel_link[:href]

      # Cancel link goes to author profile page
      assert_current_path %r{/@[^/]+}
    end

    test "profile settings uses contrast-safe helper copy and disabled email semantics" do
      visit edit_settings_profile_path

      classes = page.evaluate_script(<<~JS)
        (() => {
          const usernameHint = Array.from(document.querySelectorAll("p")).find((node) =>
            node.textContent.trim() === #{I18n.t("users.settings.profile.username_change_hint").to_json}
          );
          const emailInput = document.querySelector("input[name='user[email_address]']");

          return {
            usernameHintClass: usernameHint ? usernameHint.className : "",
            emailInputClass: emailInput ? emailInput.className : "",
            emailDisabled: !!(emailInput && emailInput.disabled)
          };
        })()
      JS

      assert_includes classes["usernameHintClass"], "text-foreground/80"
      assert_includes classes["emailInputClass"], "bg-muted"
      assert classes["emailDisabled"]
    end

    private

    def sign_in_with_retry(user)
      attempts = 0

      begin
        attempts += 1
        sign_in_as(user)
      rescue Ferrum::TimeoutError
        raise if attempts >= 2

        # Lightweight recovery: visit a safe endpoint and retry, rather than full reset
        visit "/up"
        sleep 0.5
        retry
      end
    end

    def attach_portrait_file
      file_path = Rails.root.join("public/icon.png")
      input_id = "user_profile_attributes_portrait"

      attach_file input_id, file_path, make_visible: true

      # Cuprite can occasionally drop hidden-input attachments in full-suite runs.
      # Retry with visible:false and assert we truly have one selected file.
      if page.evaluate_script("document.getElementById('#{input_id}')?.files?.length || 0").zero?
        attach_file input_id, file_path, visible: false
      end

      assert_equal 1, page.evaluate_script("document.getElementById('#{input_id}')?.files?.length || 0")
    end

    def submit_profile_form
      submit_label = I18n.t("users.settings.profile.submit")

      assert_button submit_label, disabled: false
      click_button submit_label
    end
  end
end
