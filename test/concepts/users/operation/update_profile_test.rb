require "test_helper"

class Users::Operation::UpdateProfileTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "updates username when params include a new value" do
    expected_email_address = @user.email_address

    result = Users::Operation::UpdateProfile.new.call(
      user: @user,
      params: {
        email_address: "updated@example.com",
        profile_attributes: {
          display_name: "Updated Name",
          username: "different_username"
        }
      }
    )

    assert_predicate result, :success?
    assert_equal "Updated Name", @user.reload.profile.display_name
    assert_equal "different_username", @user.profile.username
    assert_equal expected_email_address, @user.email_address
  end

  test "updates portrait and username" do
    result = Users::Operation::UpdateProfile.new.call(
      user: @user,
      params: {
        profile_attributes: {
          display_name: @user.profile.display_name,
          username: "another_name",
          portrait: {
            io: StringIO.new("portrait image"),
            filename: "portrait.png",
            content_type: "image/png"
          }
        }
      }
    )

    assert_predicate result, :success?
    assert_equal "another_name", @user.reload.profile.username
    assert_predicate @user.profile.portrait, :attached?
  end

  test "persists bio for all locales in a single call" do
    en_id = @user.profile.translations.find_by(locale: "en")&.id

    result = Users::Operation::UpdateProfile.new.call(
      user: @user,
      params: {
        profile_attributes: {
          display_name: "Shared Name",
          username: "reader_one",
          translations_attributes: {
            "0" => { id: en_id, locale: "en", bio: "English bio text" },
            "1" => { locale: "es", bio: "Texto de bio en espanol" }
          }
        }
      }
    )

    assert_predicate result, :success?

    @user.reload

    assert_equal "English bio text", Mobility.with_locale(:en) { @user.profile.bio }
    assert_equal "Texto de bio en espanol", Mobility.with_locale(:es) { @user.profile.bio }
    assert_equal "Shared Name", @user.profile.display_name
    assert_equal "reader_one", @user.profile.username
  end
end
