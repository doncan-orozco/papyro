# frozen_string_literal: true

module Articles
  module Presenter
    class Default < SimpleDelegator
      def self.wrap(collection, locale: I18n.locale)
        collection.map { |article| new(article, locale: locale) }
      end

      attr_reader :locale

      def initialize(article, locale: I18n.locale)
        super(article)
        @locale = locale.to_s
      end

      def translation_fallback?
        locale.to_s != original_locale.to_s && !translation_published?(locale)
      end

      def author_name
        user&.author_display_name || I18n.t("articles.show.unknown_author")
      end

      def author_initial
        author_name.first.to_s.upcase
      end

      def author_username
        user&.profile&.username
      end

      def author_bio
        user&.profile&.bio
      end

      def reading_time_minutes
        if respond_to?(:content_analysis) && content_analysis
          content_analysis.estimated_reading_time_minutes
        else
          1
        end
      end

      def cover_image_attached?
        __getobj__.cover_image.attached?
      end

      def og_image_for_current_locale
        __getobj__.generated_og_images.find { |img|
          img.filename.to_s == "og-#{locale}.png"
        }
      end
      # Add missing ends for class and modules
    end
  end
end
