require "test_helper"
require "securerandom"

module Articles
  class PublishedQueryTest < ActiveSupport::TestCase
    test "returns only published articles ordered by published_at desc" do
      user = users(:admin)
      now = Time.current

      newest = Article.create!(
        title: "Newest Published",
        slug: "newest-published-#{SecureRandom.hex(4)}",
        status: :draft,
        excerpt: "Newest excerpt",
        body: "Body",
        user: user
      )
      publish_article!(newest, published_at: now)
      older = Article.create!(
        title: "Older Published",
        slug: "older-published-#{SecureRandom.hex(4)}",
        status: :draft,
        excerpt: "Older excerpt",
        body: "Body",
        user: user
      )
      publish_article!(older, published_at: now - 1.day)
      draft = Article.create!(
        title: "Draft",
        slug: "draft-published-query-#{SecureRandom.hex(4)}",
        status: :draft,
        body: "Body",
        user: user
      )

      result = PublishedQuery.call

      assert_includes result, newest
      assert_includes result, older
      assert_not_includes result, draft
      assert_equal [ newest.id, older.id ], result.limit(2).pluck(:id)
    end
  end
end
