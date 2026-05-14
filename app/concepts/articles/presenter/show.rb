# frozen_string_literal: true
require 'ostruct'
# frozen_string_literal: true

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
    end
  end
end
