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
end
