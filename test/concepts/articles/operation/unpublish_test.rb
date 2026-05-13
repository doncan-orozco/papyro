require "test_helper"

class Articles::Operation::UnpublishTest < ActiveSupport::TestCase
  test "unpublishes published article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article-unpublish",
      body: "<p>Test content</p>",
      published_at: Time.current,
      user: user
    )

    publish_article!(article)

    # Ensure translation is published
    translation = article.article_translations.find_by(locale: article.original_locale)
    translation.update!(status: :published, published_at: Time.current)

    result = Articles::Operation::Unpublish.new.call(model: article)

    assert_predicate result, :success?
    assert_predicate result.value![:model].reload, :draft?
    assert_nil result.value![:model].published_at

    # Verify translation is also unpublished
    translation.reload

    assert_predicate translation, :draft?
    assert_nil translation.published_at
  end

  test "fails atomically when original locale translation is missing" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "atomic-failure-unpublish-#{SecureRandom.hex(4)}",
      body: "<p>Test content</p>",
      excerpt: "Short summary",
      published_at: Time.current,
      user: user
    )

    publish_article!(article)

    article.update_column(:original_locale, "es")

    result = Articles::Operation::Unpublish.new.call(model: article)

    assert_predicate result, :failure?
    assert_not_nil result.failure[:model].published_at
    assert_not_predicate article.reload, :published?
    assert_not_nil article.published_at
  end

  test "fails to unpublish draft article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article-draft",
      body: "<p>Test content</p>",
      user: user
    )

    result = Articles::Operation::Unpublish.new.call(model: article)

    assert_predicate result, :failure?
    assert_predicate result.failure[:errors][:base], :any?
  end

  test "fails to unpublish trashed article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "trashed-article-unpublish-#{SecureRandom.hex(4)}",
      excerpt: "Short summary",
      body: "<p>Test content</p>",
      published_at: Time.current,
      user: user,
      deleted_at: Time.current
    )

    result = Articles::Operation::Unpublish.new.call(model: article)

    assert_predicate result, :failure?
    assert_equal :trashed, result.failure[:code]
    assert_equal I18n.t("studio.articles.operations.update.trashed"), result.failure[:message]
  end

  test "requires model parameter" do
    assert_raises(ArgumentError) do
      Articles::Operation::Unpublish.new.call
    end
  end
end
