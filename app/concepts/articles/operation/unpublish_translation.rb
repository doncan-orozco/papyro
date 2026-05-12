# frozen_string_literal: true

module Articles
  module Operation
    # Marks the current locale's translation as a draft (not publicly visible).
    class UnpublishTranslation < ApplicationOperation
      def call(model:, locale:)
        translation = step find_translation(model: model, locale: locale)
        persisted   = step persist_translation(translation)

        { model: model, translation: persisted }
      end

      private

      def find_translation(model:, locale:)
        translation = model.article_translations.find_by(locale: locale.to_s)
        return Success(translation) if translation.present?

        fail_with_business_error!(model, I18n.t("errors.messages.translation_not_found"))
      end

      def persist_translation(translation)
        return Success(translation) if translation.update(status: :draft, published_at: nil)

        Failure(model: translation)
      end
    end
  end
end
