# frozen_string_literal: true

module Views
  module Articles
    class Show::TranslationFallbackBanner < Views::Base
      def initialize(original_locale:)
        @original_locale = original_locale.to_sym
      end

      def view_template
        div(class: "mb-8 rounded-lg bg-muted/50 px-4 py-3 text-sm text-foreground/75") do
          t("articles.show.translation_fallback_notice",
            original_language: t("language.name", locale: @original_locale))
        end
      end
    end
  end
end
