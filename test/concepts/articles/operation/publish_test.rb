require "test_helper"

class Articles::Operation::PublishTest < ActiveSupport::TestCase
  test "publishes draft article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article",
      excerpt: "Short summary",
      body: "<p>Test content</p>",
      user: user
    )

    result = Articles::Operation::Publish.new.call(model: article)

    assert_predicate result, :success?
    assert_predicate result.value![:model].reload, :published?
    assert_not_nil result.value![:model].published_at

    # Verify original locale translation is also published
    original_translation = article.article_translations.find_by(locale: article.original_locale)

    # Verify new translation status enum is set
    assert_predicate original_translation.reload, :status_published?
    assert_equal "published", original_translation.status
    assert_not_nil original_translation.published_at
  end

  test "publishes draft article for non-english original locale" do
    user = users(:admin)
    article = nil

    I18n.with_locale(:es) do
      article = Article.create!(
        title: "Articulo original ES",
        slug: "articulo-original-es-#{SecureRandom.hex(4)}",
        excerpt: "Resumen ES",
        body: "<p>Contenido ES</p>",
        user: user
      )
    end
    article.update_column(:original_locale, "es")

    result = I18n.with_locale(:es) { Articles::Operation::Publish.new.call(model: article) }

    assert_predicate result, :success?
    assert_equal "es", article.reload.original_locale
    assert_predicate article, :published?

    original_translation = article.article_translations.find_by(locale: "es")

    assert_predicate original_translation.reload, :status_published?
  end

  test "fails atomically when original locale translation is missing" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "atomic-failure-publish-#{SecureRandom.hex(4)}",
      excerpt: "Short summary",
      body: "<p>Test content</p>",
      user: user
    )

    article.update_column(:original_locale, "es")

    result = Articles::Operation::Publish.new.call(model: article)

    assert_predicate result, :failure?
    assert_predicate article.reload, :draft?
    assert_nil article.published_at
  end

  test "fails to publish already published article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article",
      body: "<p>Test content</p>",
      published_at: Time.current,
      user: user
    )

    result = Articles::Operation::Publish.new.call(model: article)

    assert_predicate result, :failure?
    assert_predicate result.failure[:errors][:base], :any?
  end

  test "fails to publish incomplete article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article",
      user: user
    )

    result = Articles::Operation::Publish.new.call(model: article)

    assert_predicate result, :failure?
    assert_predicate result.failure[:errors][:base], :any?
  end

  test "fails to publish article without excerpt" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article-without-excerpt",
      body: "<p>Test content</p>",
      user: user
    )

    result = Articles::Operation::Publish.new.call(model: article)

    assert_predicate result, :failure?
    assert_predicate result.failure[:errors][:base], :any?
  end

  test "requires model parameter" do
    assert_raises(ArgumentError) do
      Articles::Operation::Publish.new.call
    end
  end

  test "note: authorization is enforced at controller level before passing model" do
    # This test documents the new calling pattern:
    # 1. Controller finds article with scoping: Current.user.articles.find_by!(id: params[:id])
    # 2. Controller passes pre-authorized model to operation
    # 3. Operation performs publish/unpublish without re-querying

    user = users(:admin)
    other_user = users(:one)
    article = Article.create!(
      title: "Other User Article",
      slug: "other-user-publish",
      excerpt: "Short summary",
      body: "<p>Test content</p>",
      user: other_user
    )

    # Operation expects pre-authorized model from controller
    # Controller's scoped query (Current.user.articles.find_by!) prevents unauthorized access
    result = Articles::Operation::Publish.new.call(model: article)

    assert_predicate result, :success?
    # Security is enforced by controller's scoped find, not by operation
  end
end
