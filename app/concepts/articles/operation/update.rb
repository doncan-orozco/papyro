# frozen_string_literal: true

module Articles
  module Operation
    class Update < ApplicationOperation
      def call(model:, params:)
        validated_attributes = step validate_input(model: model, params: params)
        persisted_article    = step persist_article(model: model, attributes: validated_attributes)

        { model: persisted_article }
      end

      private

      def validate_input(model:, params:)
        contract_result = Articles::Contract::Update.new.call(params)

        if contract_result.failure?
          invalid_article = inject_errors!(model, contract_result.errors.to_h)
          return fail_with_model!(invalid_article)
        end

        Success(contract_result.to_h)
      end

      def persist_article(model:, attributes:)
        model.assign_attributes(attributes)

        return Success(model) if model.save

        fail_with_model!(model)
      end
    end
  end
end
