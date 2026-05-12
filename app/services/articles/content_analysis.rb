# frozen_string_literal: true

module Articles
  class ContentAnalysis
    WORDS_PER_MINUTE = 200

    def initialize(article)
      @article = article
    end

    def html_body
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
  end
end
