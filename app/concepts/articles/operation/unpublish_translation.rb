# frozen_string_literal: true

module Articles
  module Operation
    # Marks the current locale's translation as a draft (not publicly visible).
    class UnpublishTranslation < Core::Operation
      def call(model:, locale:)
        persisted = step unpublish_translation_with_state_transition(model: model, locale: locale)

        { model: model, translation: persisted }
      end

      private

      def unpublish_translation_with_state_transition(model:, locale:)
        transaction_failure = nil

        persisted_translation = ActiveRecord::Base.transaction do
          translatable_model = validate_translatable_locale(model: model, locale: locale)
          unless translatable_model.success?
            transaction_failure = translatable_model
            raise ActiveRecord::Rollback
          end

          translation = find_translation(model: model, locale: locale)
          unless translation.success?
            transaction_failure = translation
            raise ActiveRecord::Rollback
          end

          persisted_translation = persist_translation(translation.value!)
          unless persisted_translation.success?
            transaction_failure = persisted_translation
            raise ActiveRecord::Rollback
          end

          persisted_translation.value!
        end

        return transaction_failure if transaction_failure

        Success(persisted_translation)
      end

      def validate_translatable_locale(model:, locale:)
        return Success(model) unless locale.to_s == model.original_locale.to_s

        fail_with_code!(
          model,
          :original_locale_not_applicable,
          message: I18n.t("studio.articles.operations.publish_translation.english_not_applicable")
        )
      end

      def find_translation(model:, locale:)
        translation = model.article_translations.find_by(locale: locale.to_s)
        return Success(translation) if translation.present?

        fail_with_business_error!(model, I18n.t("errors.messages.translation_not_found"))
      end

      def persist_translation(translation)
        return Success(translation) if translation.update(status: :draft, published_at: nil)

        fail_with_model!(translation)
      end
    end
  end
end
