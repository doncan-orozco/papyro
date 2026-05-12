# frozen_string_literal: true

module Articles
  module Operation
    class Publish < ApplicationOperation
      def call(model:)
        publishable_model = step validate_publishable(model)
        persisted_model = step persist_publish_state(publishable_model)

        { model: persisted_model }
      end

      private

      def validate_publishable(model)
        if model.status_published?
          return fail_with_business_error!(model, I18n.t("errors.messages.article_already_published"))
        end

        body_html = model.body&.to_html.to_s
        if model.title.blank? || body_html.strip.blank? || model.excerpt.to_s.strip.blank?
          return fail_with_business_error!(model, I18n.t("errors.messages.article_incomplete_for_publish"))
        end

        Success(model)
      end

      def persist_publish_state(model)
        failed = false
        now = Time.current

        model.class.transaction do
          unless model.update(published_at: now, archived_at: nil)
            failed = true
            raise ActiveRecord::Rollback
          end

          original_translation = model.article_translations.find_by(locale: model.original_locale)
          if original_translation.blank?
            model.errors.add(:base, I18n.t("errors.messages.translation_not_found"))
            failed = true
            raise ActiveRecord::Rollback
          end

          # Update translation with status enum (published=2) and published_at timestamp.
          unless original_translation.update(status: :published, published_at: now)
            model.errors.add(:base, I18n.t("studio.articles.operations.publish.failure"))
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
