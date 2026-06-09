# frozen_string_literal: true

module Articles
  class GenerateOgImageJob < ApplicationJob
    queue_as :default

    discard_on ActiveRecord::RecordNotFound

    def perform(article_id)
      article = Article.find(article_id)
      return unless article

      # Skip if the author manually uploaded a custom cover image.
      return if article.cover_image.attached?

      # Find all locales with published translations to generate localized OG images.
      locales = published_translation_locales(article)
      return if locales.empty?

      # Purge all existing generated images to prevent stale accumulation.
      article.generated_og_images.purge

      locales.each do |locale|
        generate_for_locale(article, locale)
      end

      Rails.logger.info(
        "[GenerateOgImageJob] Generated OG images for article ##{article.id} in #{locales.count} locale(s)"
      )
    end

    private

    def published_translation_locales(article)
      article.article_translations
        .where(status: ArticleTranslation.statuses[:published])
        .pluck(:locale)
        .map(&:to_sym)
    end

    def generate_for_locale(article, locale)
      I18n.with_locale(locale) do
        tempfile = nil

        begin
          tempfile = ::Articles::Service::OgImageGenerator.new(article).call

          article.generated_og_images.attach(
            io: tempfile,
            filename: "og-#{locale}.png",
            content_type: "image/png"
          )

          Rails.logger.info(
            "[GenerateOgImageJob] Generated #{locale} OG image for article ##{article.id}"
          )
        rescue Vips::Error => e
          Rails.logger.error(
            "[GenerateOgImageJob] Vips error for article ##{article.id} (#{locale}): #{e.message}"
          )
          raise
        ensure
          tempfile&.close!
        end
      end
    end
  end
end
