# frozen_string_literal: true

module Articles
  module Operation
    class Publish < ApplicationOperation
      def call(model:, params:)
        action = step resolve_action(params)
        publishable_model = step validate_publishable(model: model, action: action)
        persisted_model = step persist_publish_state(model: publishable_model, action: action)

        { model: persisted_model }
      end

      private

      def resolve_action(params)
        Success(params.fetch(:action, "publish"))
      end

      def validate_publishable(model:, action:)
        unless [ "publish", "unpublish" ].include?(action)
          return fail_with_business_error!(model, I18n.t("errors.messages.invalid_action"))
        end

        if action == "publish"
          if model.status_published?
            return fail_with_business_error!(model, I18n.t("errors.messages.article_already_published"))
          end

          body_html = model.body&.to_html.to_s
          if model.title.blank? || body_html.strip.blank?
            return fail_with_business_error!(model, I18n.t("errors.messages.article_incomplete_for_publish"))
          end
        elsif !model.status_published?
          return fail_with_business_error!(model, I18n.t("errors.messages.article_not_published"))
        end

        Success(model)
      end

      def persist_publish_state(model:, action:)
        persisted_model = nil

        Article.transaction do
          success = if action == "publish"
            model.update(status: :published, published_at: Time.current)
          else
            model.update(status: :draft, published_at: nil)
          end

          if success
            persisted_model = model
          else
            raise ActiveRecord::Rollback
          end
        end

        return Success(persisted_model) if persisted_model

        fail_with_model!(model)
      end
    end
  end
end
