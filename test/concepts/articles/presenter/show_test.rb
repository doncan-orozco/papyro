require "test_helper"

class Articles::ShowPresenterTest < ActiveSupport::TestCase
  setup do
    @previous_public_host = Rails.configuration.x.public_host
    Rails.configuration.x.public_host = "http://lvh.me:3030"
  end

  teardown do
    Rails.configuration.x.public_host = @previous_public_host
  end

  test "wraps continuation articles with base presenter" do
    primary = build_article(title: "Primary", slug: "primary", excerpt: "Excerpt", body: "Body")
    related = build_article(title: "Sibling", slug: "sibling", excerpt: "Excerpt", body: "Body")

    presenter = Articles::Presenter::Show.new(primary, more_from_author: [ related ], locale: :fr)

    assert_equal 1, presenter.continuation_articles.length
    assert_kind_of Articles::Presenter::Default, presenter.continuation_articles.first
    assert_predicate presenter.continuation_articles.first, :translation_fallback?
    assert_equal I18n.t("articles.show.more_from_author", author: primary.user.author_display_name), presenter.continuation_heading
  end

  test "reads content analysis from the wrapped article" do
    article = build_article(title: "Readable", slug: "readable", excerpt: "Excerpt", body: "One two three four")
    presenter = Articles::Presenter::Show.new(article)

    assert_equal 1, presenter.reading_time_minutes
    assert_includes presenter.content_html, "One two three four"
  end

  test "normalizes legacy upload urls in content html" do
    article = build_article(
      title: "Image Article",
      slug: "image-article",
      excerpt: "Excerpt",
      body: "![sample](http://lvh.me/u/token123)"
    )
    presenter = Articles::Presenter::Show.new(article)

    assert_includes presenter.content_html, "http://lvh.me:3030/u/token123"
  end

  private

  def build_article(title:, slug:, excerpt:, body:)
    Article.create!(title: title, slug: "#{slug}-#{SecureRandom.hex(4)}", excerpt: excerpt, body: body, user: users(:admin))
  end
end
