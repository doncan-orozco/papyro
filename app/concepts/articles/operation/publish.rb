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
        if model.title.blank? || body_html.strip.blank?
          return fail_with_business_error!(model, I18n.t("errors.messages.article_incomplete_for_publish"))
        end

        Success(model)
      end

      def persist_publish_state(model)
        return Success(model) if model.update(status: :published, published_at: Time.current)

        fail_with_model!(model)
      end
    end
  end
end
