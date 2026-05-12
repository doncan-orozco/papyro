require "test_helper"

class Articles::Operation::UnpublishTest < ActiveSupport::TestCase
  test "unpublishes published article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article-unpublish",
      status: :published,
      body: "<p>Test content</p>",
      published_at: Time.current,
      user: user
    )

    # Ensure translation is published
    translation = article.article_translations.find_by(locale: article.original_locale)
    translation.update!(status: :published, published_at: Time.current)

    result = Articles::Operation::Unpublish.new.call(model: article)

    assert_predicate result, :success?
    assert_predicate result.value![:model].reload, :status_draft?
    assert_nil result.value![:model].published_at

    # Verify translation is also unpublished
    translation.reload
    assert_predicate translation, :status_draft?
    assert_nil translation.published_at
  end

  test "fails atomically when original locale translation is missing" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "atomic-failure-unpublish-#{SecureRandom.hex(4)}",
      status: :published,
      body: "<p>Test content</p>",
      excerpt: "Short summary",
      published_at: Time.current,
      user: user
    )

    article.update_column(:original_locale, "es")

    result = Articles::Operation::Unpublish.new.call(model: article)

    assert_predicate result, :failure?
    assert_not_predicate article.reload, :status_published?
    assert_not_nil article.published_at
  end

  test "fails to unpublish draft article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article-draft",
      status: :draft,
      body: "<p>Test content</p>",
      user: user
    )

    result = Articles::Operation::Unpublish.new.call(model: article)

    assert_predicate result, :failure?
    assert_predicate result.failure[:errors][:base], :any?
  end

  test "requires model parameter" do
    assert_raises(ArgumentError) do
      Articles::Operation::Unpublish.new.call
    end
  end
end
