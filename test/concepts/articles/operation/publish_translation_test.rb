require "test_helper"

class Articles::Operation::PublishTranslationTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @article = Article.create!(
      title: "Test Article",
      slug: "test-pub-trans-#{SecureRandom.hex(4)}",
      published_at: Time.current,
      excerpt: "Summary",
      body: "<p>Content</p>",
      user: @user
    )
    @original_translation = @article.article_translations.find_by(locale: @article.original_locale)
    @original_translation.update!(status: :published, published_at: Time.current)
  end

  test "publishes translation in specified locale" do
    spanish_translation = @article.article_translations.create!(
      locale: :es,
      title: "Artículo en Español",
      status: :draft
    )

    result = Articles::Operation::PublishTranslation.new.call(model: @article, locale: :es)

    assert_predicate result, :success?

    result_translation = result.value![:translation]

    assert_predicate result_translation, :published?
    assert_not_nil result_translation.published_at
  end

  test "fails if translation missing title" do
    spanish_translation = @article.article_translations.create!(
      locale: :es,
      title: "",
      status: :draft
    )

    result = Articles::Operation::PublishTranslation.new.call(model: @article, locale: :es)

    assert_predicate result, :failure?
  end
end
