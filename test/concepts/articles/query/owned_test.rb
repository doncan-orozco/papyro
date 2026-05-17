require "test_helper"
require "securerandom"

module Articles
  class OwnedTest < ActiveSupport::TestCase
    test "returns only user's articles ordered by updated_at desc" do
      user = users(:admin)
      other_user = users(:one)

      older = Article.create!(
        title: "Older Owned",
        slug: "older-owned-#{SecureRandom.hex(4)}",
        body: "Body",
        user: user,
        updated_at: 2.days.ago
      )
      newer = Article.create!(
        title: "Newer Owned",
        slug: "newer-owned-#{SecureRandom.hex(4)}",
        body: "Body",
        user: user,
        updated_at: 1.day.ago
      )
      other = Article.create!(
        title: "Other User",
        slug: "other-owned-#{SecureRandom.hex(4)}",
        body: "Body",
        user: other_user
      )

      result = Query::Owned.call({ user: user })

      assert_equal [ newer.id, older.id ], result.where(id: [ newer.id, older.id ]).pluck(:id)
      assert_not_includes result, other
    end

    test "returns none when user filter is missing" do
      result = Query::Owned.call({})

      assert_equal 0, result.count
    end

    test "filters by status when provided" do
      user = users(:admin)

      draft = Article.create!(
        title: "Owned Draft",
        slug: "owned-draft-#{SecureRandom.hex(4)}",
        body: "Body",
        user: user
      )
      published = Article.create!(
        title: "Owned Published",
        slug: "owned-published-#{SecureRandom.hex(4)}",
        excerpt: "Published excerpt",
        body: "Body",
        user: user
      )
      publish_article!(published)

      result = Query::Owned.call({ user: user, status: :published })

      assert_includes result, published
      assert_not_includes result, draft
    end
  end
end
