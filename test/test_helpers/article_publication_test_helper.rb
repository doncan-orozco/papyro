module ArticlePublicationTestHelper
  DEFAULT_EXCERPT = "Test excerpt".freeze
  DEFAULT_BODY = "<p>Test content</p>".freeze

  def publish_article!(article, published_at: Time.current)
    update_attributes = {
      archived_at: nil,
      published_at: published_at
    }
    update_attributes[:excerpt] = DEFAULT_EXCERPT if article.excerpt.blank?
    update_attributes[:body] = DEFAULT_BODY if article.body.blank?

    article.update!(update_attributes)

    result = Articles::Operation::Publish.new.call(model: article)
    if result.success?
      result_article = result.value![:model]

      if result_article.published_at != published_at
        result_article.update_column(:published_at, published_at)
        result_article.translations.find_by!(locale: result_article.original_locale)
          .update_column(:published_at, published_at)
      end

      return result_article
    end

    raise "Failed to publish test article: #{result.failure[:errors].inspect}"
  end

  def unpublish_article!(article)
    result = Articles::Operation::Unpublish.new.call(model: article)
    return result.value![:model] if result.success?

    raise "Failed to unpublish test article: #{result.failure[:errors].inspect}"
  end
end
