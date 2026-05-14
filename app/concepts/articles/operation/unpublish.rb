# frozen_string_literal: true

module Articles
  module Operation
    class Unpublish < Core::Operation
      def call(model:)
        persisted_model = step unpublish_with_state_transition(model: model)

        { model: persisted_model }
      end

      private

      def unpublish_with_state_transition(model:)
        transaction_failure = nil

        persisted_model = ActiveRecord::Base.transaction do
          unpublishable_model = validate_unpublishable(model)
          unless unpublishable_model.success?
            transaction_failure = unpublishable_model
            raise ActiveRecord::Rollback
          end

          persisted_model = persist_draft_state(unpublishable_model.value!)
          unless persisted_model.success?
            transaction_failure = persisted_model
            raise ActiveRecord::Rollback
          end

          persisted_model.value!
        end

        return transaction_failure if transaction_failure

        Success(persisted_model)
      end

      def validate_unpublishable(model)
        if model.trashed?
          return fail_with_code!(
            model,
            :trashed,
            message: I18n.t("studio.articles.operations.update.trashed")
          )
        end

        unless model.published?
          return fail_with_business_error!(model, I18n.t("errors.messages.article_not_published"))
        end

        Success(model)
      end

      def persist_draft_state(model)
        previous_published_at = model.published_at

        model.assign_attributes(published_at: nil)
        unless model.save
          restore_publish_timestamp(model, previous_published_at: previous_published_at)
          return fail_with_model!(model)
        end

        original_translation = model.article_translations.find_by(locale: model.original_locale)
        if original_translation.blank?
          restore_publish_timestamp(model, previous_published_at: previous_published_at)
          model.errors.add(:base, I18n.t("errors.messages.translation_not_found"))
          return fail_with_model!(model)
        end

        # Update translation with status enum (draft=0) and clear published_at timestamp.
        unless original_translation.update(status: :draft, published_at: nil)
          restore_publish_timestamp(model, previous_published_at: previous_published_at)
          model.errors.add(:base, I18n.t("studio.articles.operations.unpublish.failure"))
          return fail_with_model!(model)
        end

        Success(model)
      end

      def restore_publish_timestamp(model, previous_published_at:)
        model.published_at = previous_published_at
      end
    end
  end
end
