# frozen_string_literal: true

require "ostruct"

module Articles
  module Presenter
    class Show < Default
      def title
        Mobility.with_locale(content_locale_for_display) { __getobj__.title }
      end

      def excerpt
        Mobility.with_locale(content_locale_for_display) { __getobj__.excerpt }
      end

      def cover_image_caption
        Mobility.with_locale(content_locale_for_display) { __getobj__.cover_image_caption }
      end

      def content_html
        MarkdownRenderer.build.render(content_markdown).html_safe
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
          "inLanguage": content_locale_for_display
        }
      end

      def initialize(article, more_from_author: [], more_from_platform: [], author_total_count: 0, locale: I18n.locale)
        super(article, locale: locale)
        @more_from_author = Default.wrap(more_from_author, locale: locale)
        @more_from_platform = Default.wrap(more_from_platform, locale: locale)
        @author_total_count = author_total_count
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

      def author_total_count
        @author_total_count || 0
      end

      def show_view_all_button?
        @more_from_author.present? && author_total_count > 4
      end

      def localized_slug_for(target_locale)
        localized_slug = Mobility.with_locale(target_locale) { slug }
        return localized_slug if localized_slug.present?

        Mobility.with_locale(original_locale) { slug }
      end

      private

      def content_markdown
        return __getobj__.body.content.to_s if content_locale_for_display == original_locale.to_s

        translation = __getobj__.translations.find { |entry| entry.locale == content_locale_for_display }
        translation&.content.presence || __getobj__.body.content.to_s
      end

      def content_locale_for_display
        translation_fallback? ? original_locale.to_s : locale.to_s
      end

      def cover_image_url
        cover_image.attached? ? Rails.application.routes.url_helpers.rails_blob_path(cover_image, only_path: true) : nil
      end
    end
  end
end
