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
        status: :published,
        published_at: 1.hour.ago,
        body: "Body",
        user: author
      )
      related = Article.create!(
        title: "Related",
        slug: "related-query-#{SecureRandom.hex(4)}",
        status: :published,
        published_at: Time.current,
        body: "Body",
        user: author
      )
      other_author = Article.create!(
        title: "Other Author",
        slug: "other-author-related-#{SecureRandom.hex(4)}",
        status: :published,
        published_at: Time.current,
        body: "Body",
        user: other_user
      )

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
