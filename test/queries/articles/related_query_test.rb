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
        status: :draft,
        excerpt: "Reference excerpt",
        body: "Body",
        user: author
      )
      publish_article!(reference, published_at: 1.hour.ago)
      related = Article.create!(
        title: "Related",
        slug: "related-query-#{SecureRandom.hex(4)}",
        status: :draft,
        excerpt: "Related excerpt",
        body: "Body",
        user: author
      )
      publish_article!(related)
      other_author = Article.create!(
        title: "Other Author",
        slug: "other-author-related-#{SecureRandom.hex(4)}",
        status: :draft,
        excerpt: "Other author excerpt",
        body: "Body",
        user: other_user
      )
      publish_article!(other_author)

      result = RelatedQuery.call(user: author, article_id: reference.id)

      assert_includes result, related
      assert_not_includes result, reference
      assert_not_includes result, other_author
    end

    test "returns none when user filter is missing" do
      result = RelatedQuery.call({})

      assert_equal 0, result.count
    end
  end
end
