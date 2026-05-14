# frozen_string_literal: true

module Views
  module Articles
    class Show::TranslationFallbackBanner < Views::Base
      def view_template
        div(class: "mb-8 rounded-lg bg-muted/50 px-4 py-3 text-sm text-muted-foreground") do
          t("articles.show.translation_fallback_notice")
        end
      end
    end
  end
end
