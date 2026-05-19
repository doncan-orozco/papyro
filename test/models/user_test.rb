require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")

    assert_equal("downcased@example.com", user.email_address)
  end

  test "from_omniauth creates a user and profile" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "uid-123",
      info: {
        email: "OAuth.User+test@example.com",
        name: "OAuth User"
      }
    )

    user = User.from_omniauth(auth)

    assert_predicate user, :persisted?
    assert_equal "google_oauth2", user.provider
    assert_equal "uid-123", user.uid
    assert_equal "oauth.user+test@example.com", user.email_address
    assert_equal "OAuth User", user.profile.display_name
    assert_equal "oauthusertest", user.profile.username
  end

  test "from_omniauth reuses an existing provider uid user" do
    existing = User.create!(
      email_address: "oauth-existing@example.com",
      password: "password123",
      provider: "google_oauth2",
      uid: "uid-existing"
    )
    existing.create_profile!(display_name: "Existing User", username: "existing_user")

    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "uid-existing",
      info: {
        email: "different@example.com",
        name: "Different"
      }
    )

    user = User.from_omniauth(auth)

    assert_equal existing.id, user.id
    assert_equal "oauth-existing@example.com", user.email_address
    assert_equal "existing_user", user.profile.username
  end

  test "from_omniauth appends a suffix for username collisions" do
    User.create!(email_address: "existing+1@example.com", password: "password123").create_profile!(
      display_name: "Taken",
      username: "collision"
    )

    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "uid-collision",
      info: {
        email: "collision@example.com",
        name: "Collision"
      }
    )

    user = User.from_omniauth(auth)

    assert_equal "collision1", user.profile.username
  end

  test "from_omniauth pads short usernames to minimum length" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "uid-short",
      info: {
        email: "a@example.com",
        name: "Short"
      }
    )

    user = User.from_omniauth(auth)

    assert_equal "a00", user.profile.username
  end
end
