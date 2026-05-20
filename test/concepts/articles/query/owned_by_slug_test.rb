require "test_helper"
require "securerandom"

module Articles
  class OwnedBySlugTest < ActiveSupport::TestCase
    test "returns owner article by localized slug" do
      owner = users(:admin)
      article = Article.create!(
        title: "Owner EN",
        slug: "owner-en-#{SecureRandom.hex(3)}",
        body: "Body",
        user: owner
      )

      I18n.with_locale(:es) do
        article.update!(title: "Owner ES", slug: "owner-es-#{SecureRandom.hex(3)}")
      end

      spanish_slug = article.article_translations.find_by!(locale: "es").slug

      result = Query::OwnedBySlug.call({ slug: spanish_slug, locale: "es", user: owner })

      assert_includes result, article
    end

    test "does not return articles from a different owner" do
      owner = users(:admin)
      other_user = users(:one)
      article = Article.create!(
        title: "Private Draft",
        slug: "private-draft-#{SecureRandom.hex(3)}",
        body: "Body",
        user: owner
      )

      result = Query::OwnedBySlug.call({ slug: article.slug, user: other_user })

      assert_empty result
    end

    test "returns none when slug is blank" do
      owner = users(:admin)

      assert_empty Query::OwnedBySlug.call({ slug: "", user: owner })
      assert_empty Query::OwnedBySlug.call({ user: owner })
    end
  end
end
