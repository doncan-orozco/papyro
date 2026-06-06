require "test_helper"

class AuthorProfileTest < ActiveSupport::TestCase
  test "username is unique case insensitively" do
    profile = AuthorProfile.new(
      user: users(:admin),
      display_name: "Duplicate Username",
      username: "READER_ONE"
    )

    assert_not profile.valid?
    assert_includes profile.errors[:username], "has already been taken"
  end

  test "destroying pinned article nullifies author profile reference" do
    article = Article.create!(
      title: "Pinned Article",
      slug: "pinned-article",
      body: "Body",
      user: users(:admin)
    )

    profile = author_profiles(:admin)
    profile.update!(pinned_article: article)

    article.destroy!

    assert_nil profile.reload.pinned_article_id
  end

  test "friendly id history keeps previous username findable" do
    user = User.create!(email_address: "history-check@example.com", password: "password123")
    profile = user.create_profile!(display_name: "History Check", username: "historycheck")
    previous_username = profile.username

    profile.update!(username: "historychecknew")

    assert_equal profile.id, AuthorProfile.friendly.find(previous_username).id
    assert_equal profile.id, AuthorProfile.friendly.find("historychecknew").id
  end

  test "github approach: historical slug is freed for new user" do
    # User A: create and change username
    user_a = User.create!(email_address: "github_a@example.com", password: "password123")
    profile_a = user_a.create_profile!(display_name: "GitHub A", username: "alpha")
    profile_a.update!(username: "beta")

    # Confirm historical slug exists for 'alpha' and points to profile_a
    slug = FriendlyId::Slug.find_by(slug: "alpha", sluggable_type: "AuthorProfile")

    assert slug, "Historical slug for 'alpha' should exist after username change"
    assert_equal profile_a.id, slug.sluggable_id

    # User B: create and claim 'alpha'
    user_b = User.create!(email_address: "github_b@example.com", password: "password123")
    profile_b = user_b.create_profile!(display_name: "GitHub B", username: "alpha")

    assert_predicate profile_b, :valid?, "User B should be able to claim 'alpha' after User A changed it"
    assert_equal "alpha", profile_b.username

    # The slug for 'alpha' should now point to profile_b, not profile_a
    new_slug = FriendlyId::Slug.find_by(slug: "alpha", sluggable_type: "AuthorProfile")

    assert new_slug, "Slug for 'alpha' should exist after User B claims it"
    assert_equal profile_b.id, new_slug.sluggable_id
    # There should be no slug for 'alpha' pointing to profile_a
    refute_predicate FriendlyId::Slug.where(slug: "alpha", sluggable_id: profile_a.id, sluggable_type: "AuthorProfile"), :exists?, "Old historical slug for User A should be gone"
  end

  test "bio is stored per locale" do
    profile = author_profiles(:one)

    Mobility.with_locale(:en) { profile.update!(bio: "Reader biography in English") }
    Mobility.with_locale(:es) { profile.update!(bio: "Biografia del lector en espanol") }

    assert_equal "Reader biography in English", Mobility.with_locale(:en) { profile.reload.bio }
    assert_equal "Biografia del lector en espanol", Mobility.with_locale(:es) { profile.reload.bio }
  end
end
