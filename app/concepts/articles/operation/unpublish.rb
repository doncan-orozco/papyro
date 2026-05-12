# frozen_string_literal: true

module Articles
  module Operation
    class Unpublish < ApplicationOperation
      def call(model:)
        unpublishable_model = step validate_unpublishable(model)
        persisted_model = step persist_draft_state(unpublishable_model)

        { model: persisted_model }
      end

      private

      def validate_unpublishable(model)
        unless model.status_published?
          return fail_with_business_error!(model, I18n.t("errors.messages.article_not_published"))
        end

        Success(model)
      end

      def persist_draft_state(model)
        failed = false

        model.class.transaction do
          unless model.update(published_at: nil)
            failed = true
            raise ActiveRecord::Rollback
          end

          original_translation = model.article_translations.find_by(locale: model.original_locale)
          if original_translation.blank?
            model.errors.add(:base, I18n.t("errors.messages.translation_not_found"))
            failed = true
            raise ActiveRecord::Rollback
          end

          # Update translation with status enum (draft=0) and clear published_at timestamp.
          unless original_translation.update(status: :draft, published_at: nil)
            model.errors.add(:base, I18n.t("studio.articles.operations.unpublish.failure"))
            failed = true
            raise ActiveRecord::Rollback
          end
        end

        if failed
          model.reload
          return fail_with_model!(model)
        end

        Success(model)
      end
    end
  end
end
