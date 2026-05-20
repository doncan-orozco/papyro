require "test_helper"
require "base64"
require "tempfile"

class Settings::ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
  end

  test "edit requires authentication" do
    get edit_settings_profile_path

    assert_redirected_to new_session_path
  end

  test "authenticated user can view profile settings" do
    sign_in_as(@user)

    get edit_settings_profile_path

    assert_response :success
    assert_includes response.body, I18n.t("users.settings.profile.title")
  end

  test "authenticated user can update profile" do
    sign_in_as(@user)

    patch settings_profile_path, params: {
      user: {
        profile_attributes: { display_name: "Updated Name", username: "updated_name" },
        email_address: "updated@example.com"
      }
    }

    assert_redirected_to edit_settings_profile_path
    assert_equal "Updated Name", @user.reload.profile.display_name
    assert_equal "updated_name", @user.reload.profile.username
    assert_equal "one@example.com", @user.reload.email_address
  end

  test "ignores email address changes on update" do
    sign_in_as(@user)

    patch settings_profile_path, params: {
      user: {
        email_address: @other_user.email_address,
        profile_attributes: {
          display_name: "Ignored Email Update",
          username: @user.profile.username
        }
      }
    }

    assert_redirected_to edit_settings_profile_path
    assert_equal "Ignored Email Update", @user.reload.profile.display_name
    assert_equal "one@example.com", @user.reload.email_address
  end

  test "authenticated user can upload portrait photo" do
    sign_in_as(@user)

    tempfile = Tempfile.new([ "portrait", ".png" ])
    tempfile.binmode
    tempfile.write(Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9sX6ixkAAAAASUVORK5CYII="))
    tempfile.rewind

    uploaded_file = Rack::Test::UploadedFile.new(tempfile.path, "image/png", original_filename: "portrait.png")

    patch settings_profile_path, params: {
      user: {
        profile_attributes: {
          display_name: @user.profile.display_name,
          username: @user.profile.username,
          portrait: uploaded_file
        }
      }
    }

    assert_redirected_to edit_settings_profile_path
    assert_predicate @user.reload.profile.portrait, :attached?
  ensure
    tempfile&.close
    tempfile&.unlink
  end

  test "saving profile without new portrait keeps existing portrait" do
    sign_in_as(@user)

    tempfile = Tempfile.new([ "portrait-existing", ".png" ])
    tempfile.binmode
    tempfile.write(Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9sX6ixkAAAAASUVORK5CYII="))
    tempfile.rewind

    uploaded_file = Rack::Test::UploadedFile.new(tempfile.path, "image/png", original_filename: "portrait-existing.png")

    patch settings_profile_path, params: {
      user: {
        profile_attributes: {
          display_name: @user.profile.display_name,
          username: @user.profile.username,
          portrait: uploaded_file
        }
      }
    }

    assert_redirected_to edit_settings_profile_path
    assert_predicate @user.reload.profile.portrait, :attached?

    patch settings_profile_path, params: {
      user: {
        profile_attributes: {
          display_name: "Kept Portrait Name",
          username: @user.profile.username
        }
      }
    }

    assert_redirected_to edit_settings_profile_path
    assert_equal "Kept Portrait Name", @user.reload.profile.display_name
    assert_predicate @user.profile.portrait, :attached?
  ensure
    tempfile&.close
    tempfile&.unlink
  end

  test "authenticated user can update username" do
    sign_in_as(@user)

    patch settings_profile_path, params: {
      user: {
        profile_attributes: {
          display_name: @user.profile.display_name,
          username: "new_username"
        }
      }
    }

    assert_redirected_to edit_settings_profile_path
    assert_equal "new_username", @user.reload.profile.username
  end
end
