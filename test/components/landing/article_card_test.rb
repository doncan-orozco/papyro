require "test_helper"

class Components::Landing::ArticleCardTest < ActiveSupport::TestCase
  test "renders title and author for published article without cover image" do
    article = articles(:published_article)
    html = ApplicationController.render(
      inline: "<%= render Components::Landing::ArticleCard.new(article: article) %>",
      locals: { article: article }
    )

    assert_includes html, article.title
    assert_includes html, "Admin Writer"
  end

  test "displays PAPYRO pill badge in cover image fallback" do
    article = articles(:published_article)
    html = ApplicationController.render(
      inline: "<%= render Components::Landing::ArticleCard.new(article: article) %>",
      locals: { article: article }
    )

    assert_includes html, "PAPYRO"
    assert_includes html, "rounded-full border border-foreground/10"
  end

  test "displays fallback texture text when no cover image attached" do
    article = articles(:published_article)
    html = ApplicationController.render(
      inline: "<%= render Components::Landing::ArticleCard.new(article: article) %>",
      locals: { article: article }
    )

    assert_includes html, "PUBLISHED ARTICLE"
  end

  test "renders reading time" do
    article = articles(:published_article)
    html = ApplicationController.render(
      inline: "<%= render Components::Landing::ArticleCard.new(article: article) %>",
      locals: { article: article }
    )

    assert_match /min read/, html
  end
end
