require "test_helper"
require "securerandom"

module Articles
  class RelatedTest < ActiveSupport::TestCase
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

      result = Query::Related.call({ user: author, article_id: reference.id })

      assert_includes result, related
      assert_not_includes result, reference
      assert_not_includes result, other_author
    end

    test "returns none when user filter is missing" do
      result = Query::Related.call({})

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

      result = Query::Related.call({
        exclude_user_id: excluded_author.id,
        article_id: reference.id,
        limit: 2
      })

      assert_includes result, included_article
      assert_not_includes result, excluded_article
      assert_not_includes result, reference
    end

    test "excludes articles unpublished in current locale" do
      author = users(:admin)

      reference = Article.create!(
        title: "Reference Localized",
        slug: "reference-localized-#{SecureRandom.hex(4)}",
        excerpt: "Reference excerpt",
        body: "Body",
        user: author
      )
      publish_article!(reference)
      set_translation_status!(reference, locale: "es", status: :published)

      published_in_es = Article.create!(
        title: "Published in ES",
        slug: "published-es-#{SecureRandom.hex(4)}",
        excerpt: "Published in ES excerpt",
        body: "Body",
        user: author
      )
      publish_article!(published_in_es)
      set_translation_status!(published_in_es, locale: "es", status: :published)

      unpublished_in_es = Article.create!(
        title: "Unpublished in ES",
        slug: "unpublished-es-#{SecureRandom.hex(4)}",
        excerpt: "Unpublished in ES excerpt",
        body: "Body",
        user: author
      )
      publish_article!(unpublished_in_es)
      set_translation_status!(unpublished_in_es, locale: "es", status: :draft)

      result = Query::Related.call({ user: author, article_id: reference.id, locale: "es" })

      assert_includes result, published_in_es
      assert_not_includes result, unpublished_in_es
      assert_not_includes result, reference
    end

    test "includes articles published in requested locale" do
      author = users(:admin)

      reference = Article.create!(
        title: "Reference Locale EN",
        slug: "reference-locale-en-#{SecureRandom.hex(4)}",
        excerpt: "Reference excerpt",
        body: "Body",
        user: author
      )
      publish_article!(reference)

      published_in_en = Article.create!(
        title: "Published in EN",
        slug: "published-en-#{SecureRandom.hex(4)}",
        excerpt: "Published in EN excerpt",
        body: "Body",
        user: author
      )
      publish_article!(published_in_en)

      result = Query::Related.call({ user: author, article_id: reference.id, locale: "en" })

      assert_includes result, published_in_en
      assert_not_includes result, reference
    end

    private

    def set_translation_status!(article, locale:, status:)
      translation = article.article_translations.find_or_initialize_by(locale: locale)
      translation.status = status
      translation.published_at = status.to_s == "published" ? (article.published_at || Time.current) : nil
      translation.save!
    end
  end
end
