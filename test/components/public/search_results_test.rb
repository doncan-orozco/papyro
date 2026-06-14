require "test_helper"
require "securerandom"

class Components::Public::SearchResultsTest < ActiveSupport::TestCase
  test "renders authors section when authors present" do
    user = users(:admin)
    html = ApplicationController.render(
      Components::Public::SearchResults.new(
        query: "Admin",
        articles: Article.none,
        authors: [ user ]
      )
    )

    assert_includes html, I18n.t("search.results.authors")
    assert_includes html, "Admin Writer"
    assert_includes html, "@admin_writer"
  end

  test "renders empty state when no results" do
    html = ApplicationController.render(
      Components::Public::SearchResults.new(
        query: "nonexistent",
        articles: Article.none,
        authors: User.none
      )
    )

    assert_includes html, "No results found for"
    assert_includes html, "nonexistent"
    assert_includes html, I18n.t("search.results.empty_description")
  end

  test "renders empty turbo-frame when query is blank" do
    html = ApplicationController.render(
      Components::Public::SearchResults.new(
        query: "",
        articles: Article.none,
        authors: User.none
      )
    )

    assert_includes html, 'turbo-frame id="search_results"'
    assert_not_includes html, I18n.t("search.results.empty_title", query: "")
  end

  test "renders both sections when both present" do
    user = users(:admin)
    article = Article.create!(title: "Test Article", slug: "ta-#{SecureRandom.hex(4)}", excerpt: "T", body: "B", user: user)
    publish_article!(article)

    html = ApplicationController.render(
      Components::Public::SearchResults.new(
        query: "Test",
        articles: Article.where(id: article.id),
        authors: [ user ]
      )
    )

    assert_includes html, I18n.t("search.results.authors")
    assert_includes html, I18n.t("search.results.articles")
  end
end
