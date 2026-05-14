# frozen_string_literal: true

module Studio
  module Presenter
    class Default < Core::Presenter::Base
      def self.wrap(collection, ui_locale: I18n.locale)
        collection.map { |item| new(item, ui_locale: ui_locale) }
      end

      attr_reader :ui_locale

      def initialize(article, ui_locale: I18n.locale)
        super(article)
        @ui_locale = ui_locale.to_s
      end

      def preferred_content_locale
        return ui_locale if has_translation_for_locale?(ui_locale)
        original_locale.to_s
      end

      def content_locale_param(locale = preferred_content_locale)
        locale_str = locale.to_s
        baseline = original_locale.to_s
        return {} if locale_str.blank? || locale_str == baseline

        { content_locale: locale_str }
      end

      def display_title
        title_in_ui_locale = translation_title_for(preferred_content_locale)
        return title_in_ui_locale if title_in_ui_locale.present?

        title_in_original = translation_title_for(original_locale)
        return title_in_original if title_in_original.present?

        mobility_title = Mobility.with_locale(original_locale) { title(fallback: false).to_s.strip }
        return mobility_title if mobility_title.present?

        I18n.t("studio.articles.editor.untitled")
      end

      def untitled_title?(title)
        untitled_titles.include?(title.to_s)
      end

      def status_variant
        return :destructive if trashed?

        case status
        when "draft" then :secondary
        when "published" then :default
        when "archived" then :outline
        else :secondary
        end
      end

      def status_label
        if trashed?
          I18n.t("studio.articles.index.statuses.trashed")
        else
          I18n.t("studio.articles.index.statuses.#{status}")
        end
      end

      def published_at_label
        if trashed?
          I18n.t("studio.articles.index.deleted_at", time: I18n.l(deleted_at, format: :short))
        elsif published_at
          I18n.l(published_at, format: :short)
        else
          I18n.t("studio.articles.index.not_published")
        end
      end

      def sorted_translations
        baseline = original_locale.to_s
        article_translations.sort_by do |translation|
          [ translation.locale.to_s == baseline ? 0 : 1, translation.locale.to_s ]
        end
      end

      def locale_published?(translation)
        if translation.locale.to_s == original_locale.to_s
          published?
        else
          translation.published?
        end
      end

      private

      def translation_for(locale)
        article_translations.find { |item| item.locale.to_s == locale.to_s }
      end

      def has_translation_for_locale?(locale)
        translation_for(locale).present?
      end

      def translation_title_for(locale)
        translation_for(locale)&.title.to_s.strip
      end

      def untitled_titles
        @untitled_titles ||= I18n.available_locales.filter_map do |locale|
          I18n.t("studio.articles.editor.untitled", locale: locale, default: nil).presence
        end
      end
    end
  end
end
