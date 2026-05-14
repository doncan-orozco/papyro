# frozen_string_literal: true

module Articles
  module Operation
    # Marks the current locale's translation as publicly visible.
    # Only valid when the parent article is published (English is live).
    class PublishTranslation < Core::Operation
      def call(model:, locale:)
        persisted = step publish_translation_with_state_transition(model: model, locale: locale)

        { model: model, translation: persisted }
      end

      private

      def publish_translation_with_state_transition(model:, locale:)
        transaction_failure = nil

        persisted_translation = ActiveRecord::Base.transaction do
          translatable_model = validate_translatable_locale(model: model, locale: locale)
          unless translatable_model.success?
            transaction_failure = translatable_model
            raise ActiveRecord::Rollback
          end

          published_parent = validate_parent_published(model)
          unless published_parent.success?
            transaction_failure = published_parent
            raise ActiveRecord::Rollback
          end

          translation = find_or_build_translation(model: model, locale: locale)
          unless translation.success?
            transaction_failure = translation
            raise ActiveRecord::Rollback
          end

          publishable_translation = validate_translation_has_content(translation.value!)
          unless publishable_translation.success?
            transaction_failure = publishable_translation
            raise ActiveRecord::Rollback
          end

          persisted_translation = persist_translation(publishable_translation.value!)
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
          return fail_with_model!(translation)
        end

        Success(translation)
      end

      def persist_translation(translation)
        return Success(translation) if translation.update(status: :published, published_at: Time.current)

        fail_with_model!(translation)
      end
    end
  end
end
