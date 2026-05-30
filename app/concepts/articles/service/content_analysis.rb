# frozen_string_literal: true

module Articles
  module Service
    class ContentAnalysis
      WORDS_PER_MINUTE = 200

      def initialize(article, locale: nil)
        @article = article
        @locale = locale&.to_s
      end

      def html_body
        localized_markdown = localized_translation_content
        return render_markdown(localized_markdown) if localized_markdown.present?

        @article.body.to_html
      end

      def searchable_content
        ActionText::Content.new(html_body).to_plain_text
      end

      def plain_text_body
        ActionText::Content.new(html_body).to_plain_text.squish
      end

      def content_word_count
        plain_text_body.scan(/\b[\p{L}\p{N}]+(?:['’\-][\p{L}\p{N}]+)*\b/u).size
      end

      def estimated_reading_time_minutes
        return 0 if content_word_count.zero?

        [ (content_word_count / WORDS_PER_MINUTE.to_f).ceil, 1 ].max
      end

      private

      def localized_translation_content
        return if @locale.blank?

        translation = if @article.association(:article_translations).loaded?
          @article.article_translations.find { |candidate| candidate.locale == @locale }
        else
          @article.article_translations.find_by(locale: @locale)
        end

        translation&.content.to_s.presence
      end

      def render_markdown(markdown_content)
        renderer = ActionText::Markdown.renderer.try(:call) || ActionText::Markdown.renderer
        renderer.render(markdown_content)
      end
    end
  end
end
