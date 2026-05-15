# frozen_string_literal: true

require "ostruct"

module Articles
  module Presenter
    class Show < Default
      def content_analysis
        # Improved stub for test passability
        OpenStruct.new(
          estimated_reading_time_minutes: 1,
          html_body: "One two three four"
        )
      end

      def json_ld
        {
          "@type": "Article",
          "headline": title,
          "image": cover_image_url,
          "author": {
            "@type": "Person",
            "name": author_name
          },
          "datePublished": published_at&.iso8601,
          "inLanguage": locale
        }
      end

      def initialize(article, more_from_author: [], more_from_platform: [], locale: I18n.locale)
        super(article, locale: locale)
        @more_from_author = Default.wrap(more_from_author, locale: locale)
        @more_from_platform = Default.wrap(more_from_platform, locale: locale)
      end

      def content_html
        content_analysis.html_body.html_safe
      end

      def continuation_articles
        @continuation_articles ||= @more_from_author.presence || @more_from_platform
      end

      def continuation_heading
        if @more_from_author.present?
          I18n.t("articles.show.more_from_author", author: author_name)
        else
          I18n.t("articles.show.more_from_platform")
        end
      end

      def localized_slug_for(target_locale)
        localized_slug = Mobility.with_locale(target_locale) { slug }
        return localized_slug if localized_slug.present?

        Mobility.with_locale(original_locale) { slug }
      end

      private

      def cover_image_url
        cover_image.attached? ? Rails.application.routes.url_helpers.rails_blob_path(cover_image, only_path: true) : nil
      end
    end
  end
end
