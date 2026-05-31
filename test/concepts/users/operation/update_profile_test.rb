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

  test "persists bio per locale while keeping global fields shared" do
    english_result = Users::Operation::UpdateProfile.new.call(
      user: @user,
      locale: :en,
      params: {
        profile_attributes: {
          display_name: "Shared Name",
          username: "reader_one",
          bio: "English bio text"
        }
      }
    )

    assert_predicate english_result, :success?

    spanish_result = Users::Operation::UpdateProfile.new.call(
      user: @user,
      locale: :es,
      params: {
        profile_attributes: {
          display_name: "Shared Name",
          username: "reader_one",
          bio: "Texto de bio en espanol"
        }
      }
    )

    assert_predicate spanish_result, :success?

    @user.reload

    english_bio = Mobility.with_locale(:en) { @user.profile.bio }
    spanish_bio = Mobility.with_locale(:es) { @user.profile.bio }

    assert_equal "English bio text", english_bio
    assert_equal "Texto de bio en espanol", spanish_bio
    assert_equal "Shared Name", @user.profile.display_name
    assert_equal "reader_one", @user.profile.username
  end

end
