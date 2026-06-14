require "test_helper"
require "securerandom"

module Articles
  class SearchTest < ActiveSupport::TestCase
    test "returns articles matching title with partial match" do
      user = users(:admin)
      article = Article.create!(title: "Learning Ruby on Rails", slug: "learning-ruby-#{SecureRandom.hex(4)}", excerpt: "Test", body: "Body", user: user)
      publish_article!(article)

      result = Query::Search.call({ query: "Ruby" })

      assert_includes result, article
    end

    test "multi-word query uses AND logic" do
      user = users(:admin)
      article = Article.create!(title: "Learning Ruby on Rails deeply", slug: "lrrd-#{SecureRandom.hex(4)}", excerpt: "Test", body: "Body", user: user)
      publish_article!(article)
      non_match = Article.create!(title: "Just Ruby stuff", slug: "jrs-#{SecureRandom.hex(4)}", excerpt: "Test", body: "Body", user: user)
      publish_article!(non_match)

      result = Query::Search.call({ query: "Ruby Rails" })

      assert_includes result, article
      assert_not_includes result, non_match
    end

    test "is case-insensitive" do
      user = users(:admin)
      article = Article.create!(title: "LEARNING RAILS", slug: "lr-#{SecureRandom.hex(4)}", excerpt: "Test", body: "Body", user: user)
      publish_article!(article)

      result = Query::Search.call({ query: "learning" })

      assert_includes result, article
    end

    test "excludes draft articles" do
      user = users(:admin)
      draft = Article.create!(title: "Draft Ruby article", slug: "dra-#{SecureRandom.hex(4)}", body: "Body", user: user)

      result = Query::Search.call({ query: "Ruby" })

      assert_not_includes result, draft
    end

    test "excludes archived articles" do
      user = users(:admin)
      archived = Article.create!(title: "Archived Ruby article", slug: "ara-#{SecureRandom.hex(4)}", excerpt: "Test", body: "Body", user: user)
      publish_article!(archived)
      archived.update!(archived_at: Time.current)

      result = Query::Search.call({ query: "Ruby" })

      assert_not_includes result, archived
    end

    test "orders by published_at descending" do
      user = users(:admin)
      now = Time.current
      older = Article.create!(title: "Older Ruby article", slug: "ora-#{SecureRandom.hex(4)}", excerpt: "Test", body: "Body", user: user)
      publish_article!(older, published_at: now - 2.days)
      newer = Article.create!(title: "Newer Ruby article", slug: "nra-#{SecureRandom.hex(4)}", excerpt: "Test", body: "Body", user: user)
      publish_article!(newer, published_at: now)

      result = Query::Search.call({ query: "Ruby" })

      assert_equal [ newer.id, older.id ], result.pluck(:id)
    end

    test "prevents SQL injection" do
      user = users(:admin)
      article = Article.create!(title: "Safe article", slug: "sa-#{SecureRandom.hex(4)}", excerpt: "Test", body: "Body", user: user)
      publish_article!(article)

      result = Query::Search.call({ query: "test' OR 1=1--" })

      assert_not_includes result, article
    end
  end
end
