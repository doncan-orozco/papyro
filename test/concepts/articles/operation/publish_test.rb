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
    assert_predicate original_translation.reload, :published?
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

    assert_predicate original_translation.reload, :published?
  end

  test "publishes draft article with settings params" do
    user = users(:admin)
    article = Article.create!(
      title: "Draft Article",
      slug: "draft-article-#{SecureRandom.hex(4)}",
      excerpt: "Original excerpt",
      body: "<p>Draft content</p>",
      user: user
    )

    result = Articles::Operation::Publish.new.call(
      model: article,
      settings_params: {
        slug: "updated-before-publish",
        excerpt: "Updated excerpt before publish"
      },
      locale: :en
    )

    assert_predicate result, :success?
    assert_predicate article.reload, :published?
    assert_equal "updated-before-publish", article.slug
    assert_equal "Updated excerpt before publish", article.excerpt
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

  test "rolls back settings when publish state transition fails" do
    user = users(:admin)
    article = Article.create!(
      title: "Draft Article",
      slug: "draft-rollback-#{SecureRandom.hex(4)}",
      excerpt: "Original excerpt",
      body: "<p>Draft content</p>",
      user: user
    )

    article.update_column(:original_locale, "es")

    result = Articles::Operation::Publish.new.call(
      model: article,
      settings_params: {
        slug: "updated-before-failed-publish",
        excerpt: "Updated excerpt before failed publish"
      },
      locale: :en
    )

    assert_predicate result, :failure?

    article.reload

    assert_predicate article, :draft?
    assert_nil article.published_at
    assert_equal "draft-rollback-#{article.slug.split("draft-rollback-").last}", article.slug
    assert_equal "Original excerpt", article.excerpt
  end

  test "fails to publish already published article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article-#{SecureRandom.hex(4)}",
      excerpt: "Short summary",
      body: "<p>Test content</p>",
      user: user
    )
    publish_article!(article)

    result = Articles::Operation::Publish.new.call(model: article)

    assert_predicate result, :failure?
    assert_equal :already_published, result.failure[:code]
    assert_predicate result.failure[:errors][:base], :any?
  end

  test "updates settings for already published article without changing publish timestamp" do
    user = users(:admin)
    article = Article.create!(
      title: "Published Article",
      slug: "published-article-#{SecureRandom.hex(4)}",
      excerpt: "Original excerpt",
      body: "<p>Published content</p>",
      user: user
    )
    published_at = 2.days.ago.change(usec: 0)
    publish_article!(article, published_at: published_at)

    result = Articles::Operation::Publish.new.call(
      model: article,
      settings_params: {
        excerpt: "Updated published excerpt",
        cover_image_caption: "Updated credit"
      },
      locale: :en
    )

    assert_predicate result, :failure?
    assert_equal :already_published, result.failure[:code]

    article.reload

    assert_predicate article, :published?
    assert_equal published_at, article.published_at.change(usec: 0)
    assert_equal "Updated published excerpt", article.excerpt
    assert_equal "Updated credit", article.cover_image_caption
  end

  test "fails to publish trashed article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "trashed-article-#{SecureRandom.hex(4)}",
      excerpt: "Short summary",
      body: "<p>Test content</p>",
      user: user,
      deleted_at: Time.current
    )

    result = Articles::Operation::Publish.new.call(model: article)

    assert_predicate result, :failure?
    assert_equal :trashed, result.failure[:code]
    assert_equal I18n.t("studio.articles.operations.update.trashed"), result.failure[:message]
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

  test "fails atomically when settings params are invalid" do
    user = users(:admin)
    article = Article.create!(
      title: "Draft Article",
      slug: "draft-atomic-#{SecureRandom.hex(4)}",
      excerpt: "Original excerpt",
      body: "<p>Draft content</p>",
      user: user
    )

    result = Articles::Operation::Publish.new.call(
      model: article,
      settings_params: {
        slug: "Invalid Slug"
      },
      locale: :en
    )

    assert_predicate result, :failure?

    article.reload

    assert_predicate article, :draft?
    assert_nil article.published_at
    assert_equal "draft-atomic-#{article.slug.split("draft-atomic-").last}", article.slug
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
