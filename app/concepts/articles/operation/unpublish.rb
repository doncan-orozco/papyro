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
        return Success(model) if model.update(status: :draft, published_at: nil)

        fail_with_model!(model)
      end
    end
  end
end
