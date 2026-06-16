# frozen_string_literal: true

module Articles
  module Operation
    class Translate < Core::Operation
      def call(article:, target_locale:)
        # 1. Fetch original content
        original_title = Mobility.with_locale(article.original_locale) { article.title(fallback: false) || "" }
        original_body  = Mobility.with_locale(article.original_locale) { article.body.content.to_s }

        if original_title.blank? && original_body.blank?
          throw_failure(Failure(message: "No content to translate"))
        end

        target_language = I18n.t("language.name", locale: target_locale)

        # 2. Call Gemini
        response_text = GeminiClient.new.prompt(build_prompt(target_language, original_title, original_body))

        unless response_text
          throw_failure(Failure(message: "Translation service unavailable. Please try again."))
        end

        # 3. Parse the delimited response
        new_title = response_text.match(/<<<TITLE>>>\s*\n(.+?)\n<<<END_TITLE>>>/m)&.[](1)&.strip
        new_body  = response_text.match(/<<<BODY>>>\s*\n(.+?)\n<<<END_BODY>>>/m)&.[](1)&.strip

        if new_title.blank? && new_body.blank?
          throw_failure(Failure(message: "Could not parse translated content from API response"))
        end

        # 4. Persist to database
        ActiveRecord::Base.transaction do
          if new_title.present?
            Mobility.with_locale(target_locale) do
              article.update!(title: new_title)
            end
          end

          if new_body.present?
            translation = article.translations.find_or_initialize_by(locale: target_locale.to_s)
            translation.update!(content: new_body)
          end
        end

        article
      end

      private

      def build_prompt(target_language, title, body)
        <<~PROMPT
          You are an expert bilingual editor for a premium literary magazine.
          Translate the following title and body into #{target_language}.
          CRITICAL INSTRUCTIONS:
          - Perfectly preserve all Markdown formatting in the body (headings, bolding, lists, links, images, code blocks).
          - DO NOT translate or alter URLs, image paths, or code blocks.
          - Maintain a serene, thoughtful, and highly professional tone.

          Return the translations using EXACTLY these delimiters with no other text:

          <<<TITLE>>>
          [translated title goes here]
          <<<END_TITLE>>>

          <<<BODY>>>
          [translated body goes here]
          <<<END_BODY>>>

          ORIGINAL CONTENT TO TRANSLATE:

          <<<TITLE>>>
          #{title}
          <<<END_TITLE>>>

          <<<BODY>>>
          #{body}
          <<<END_BODY>>>
        PROMPT
      end
    end
  end
end
