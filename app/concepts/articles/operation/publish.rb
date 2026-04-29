# frozen_string_literal: true

module Articles
  module Operation
    class Publish < Dry::Operation
      include Dry::Monads[:result]

      def call(model:, params:)
        input = { model: model, params: params }
        input_with_action = step resolve_action(input)
        publishable_input = step validate_publishable(input_with_action)

        step persist_publish_state(publishable_input)
      end

      private

      def resolve_action(input)
        action = input.fetch(:params, {}).fetch(:action, "publish")
        Success(input.merge(action: action))
      end

      def validate_publishable(input)
        model = input.fetch(:model)
        action = input.fetch(:action)

        unless [ "publish", "unpublish" ].include?(action)
          return Failure(errors: { base: [ I18n.t("errors.messages.invalid_action") ] }, model: model)
        end

        if action == "publish"
          return Failure(errors: { base: [ I18n.t("errors.messages.article_already_published") ] }, model: model) if model.status_published?

          body_html = model.body&.to_html.to_s
          if model.title.blank? || body_html.strip.blank?
            return Failure(errors: { base: [ I18n.t("errors.messages.article_incomplete_for_publish") ] }, model: model)
          end
        elsif !model.status_published?
          return Failure(errors: { base: [ I18n.t("errors.messages.article_not_published") ] }, model: model)
        end

        Success(input)
      end

      def persist_publish_state(input)
        model = input.fetch(:model)
        action = input.fetch(:action)

        success = if action == "publish"
          model.update(status: :published, published_at: Time.current)
        else
          model.update(status: :draft, published_at: nil)
        end

        return Success(model: model) if success

        Failure(errors: model.errors.to_hash, model: model)
      end
    end
  end
end
