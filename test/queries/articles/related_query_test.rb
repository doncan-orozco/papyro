require "test_helper"
require "securerandom"

module Articles
  class RelatedQueryTest < ActiveSupport::TestCase
    test "returns published articles by same author excluding reference article" do
      author = users(:admin)
      other_user = users(:one)

      reference = Article.create!(
        title: "Reference",
        slug: "reference-related-#{SecureRandom.hex(4)}",
        excerpt: "Reference excerpt",
        body: "Body",
        user: author
      )
      publish_article!(reference, published_at: 1.hour.ago)
      related = Article.create!(
        title: "Related",
        slug: "related-query-#{SecureRandom.hex(4)}",
        excerpt: "Related excerpt",
        body: "Body",
        user: author
      )
      publish_article!(related)
      other_author = Article.create!(
        title: "Other Author",
        slug: "other-author-related-#{SecureRandom.hex(4)}",
        excerpt: "Other author excerpt",
        body: "Body",
        user: other_user
      )
      publish_article!(other_author)

      result = RelatedQuery.call({ user: author, article_id: reference.id })

      assert_includes result, related
      assert_not_includes result, reference
      assert_not_includes result, other_author
    end

    test "returns none when user filter is missing" do
      result = RelatedQuery.call({})

      assert_equal 0, result.count
    end

    test "returns published articles from other authors when exclude_user_id is provided" do
      excluded_author = users(:admin)
      included_author = users(:one)

      reference = Article.create!(
        title: "Reference",
        slug: "reference-platform-related-#{SecureRandom.hex(4)}",
        excerpt: "Reference excerpt",
        body: "Body",
        user: excluded_author
      )
      publish_article!(reference, published_at: 2.hours.ago)
      excluded_article = Article.create!(
        title: "Excluded Author Article",
        slug: "excluded-platform-related-#{SecureRandom.hex(4)}",
        excerpt: "Excluded excerpt",
        body: "Body",
        user: excluded_author
      )
      publish_article!(excluded_article, published_at: 1.hour.ago)
      included_article = Article.create!(
        title: "Included Author Article",
        slug: "included-platform-related-#{SecureRandom.hex(4)}",
        excerpt: "Included excerpt",
        body: "Body",
        user: included_author
      )
      publish_article!(included_article)

      result = RelatedQuery.call({
        exclude_user_id: excluded_author.id,
        article_id: reference.id,
        limit: 2
      })

      assert_includes result, included_article
      assert_not_includes result, excluded_article
      assert_not_includes result, reference
    end
  end
end
