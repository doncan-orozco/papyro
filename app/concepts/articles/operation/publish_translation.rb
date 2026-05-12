# frozen_string_literal: true

module Articles
  module Operation
    # Marks the current locale's translation as publicly visible.
    # Only valid when the parent article is published (English is live).
    class PublishTranslation < ApplicationOperation
      def call(model:, locale:)
        step validate_parent_published(model)
        translation = step find_or_build_translation(model: model, locale: locale)
        step validate_translation_has_content(translation)
        persisted = step persist_translation(translation)

        { model: model, translation: persisted }
      end

      private

      def validate_parent_published(model)
        return Success(model) if model.published?

        fail_with_business_error!(model, I18n.t("errors.messages.article_must_be_published_first"))
      end

      def find_or_build_translation(model:, locale:)
        translation = model.article_translations.find_or_initialize_by(locale: locale.to_s)
        Success(translation)
      end

      def validate_translation_has_content(translation)
        # Content body is managed by markdown storage; publication eligibility for a
        # translation is based on locale-owned translated fields.
        if translation.title.blank?
          translation.errors.add(:base, I18n.t("errors.messages.translation_incomplete_for_publish"))
          return Failure(model: translation)
        end

        Success(translation)
      end

      def persist_translation(translation)
        return Success(translation) if translation.update(status: :published, published_at: Time.current)

        Failure(model: translation)
      end
    end
  end
end
