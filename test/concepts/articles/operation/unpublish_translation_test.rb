require "test_helper"

class Articles::Operation::UnpublishTranslationTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @article = Article.create!(
      title: "Test Article",
      slug: "test-unpub-trans-#{SecureRandom.hex(4)}",
      published_at: Time.current,
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    )
    @original_translation = @article.translations.find_by(locale: @article.original_locale)
    @original_translation.update!(status: :published, published_at: Time.current)
  end

  test "unpublishes translation in specified locale" do
    spanish_translation = @article.translations.create!(
      locale: :es,
      title: "Artículo en Español",
      status: :draft
    )

    publish_result = Articles::Operation::PublishTranslation.new.call(
      model: @article, locale: :es
    )

    assert_predicate publish_result, :success?

    unp_result = Articles::Operation::UnpublishTranslation.new.call(
      model: @article, locale: :es
    )

    assert_predicate unp_result, :success?

    spanish_translation.reload

    assert_predicate spanish_translation, :draft?
    assert_nil spanish_translation.published_at
  end

  test "unpublishing one locale doesn't affect others" do
    spanish_translation = @article.translations.create!(
      locale: :es,
      title: "Artículo en Español",
      status: :draft
    )

    spanish_result = Articles::Operation::PublishTranslation.new.call(
      model: @article, locale: :es
    )

    assert_predicate spanish_result, :success?

    unp_result = Articles::Operation::UnpublishTranslation.new.call(
      model: @article, locale: :es
    )

    assert_predicate unp_result, :success?

    @original_translation.reload

    assert_predicate @original_translation, :published?

    spanish_translation.reload

    assert_predicate spanish_translation, :draft?
  end

  test "fails for original locale" do
    result = Articles::Operation::UnpublishTranslation.new.call(model: @article, locale: @article.original_locale)

    assert_predicate result, :failure?
    assert_equal :original_locale_not_applicable, result.failure[:code]
    assert_equal I18n.t("studio.articles.operations.publish_translation.english_not_applicable"), result.failure[:message]
  end
end
