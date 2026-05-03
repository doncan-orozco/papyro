# frozen_string_literal: true

module Articles
  module Operation
    class Update < ApplicationOperation
      def call(model:, params:)
        validated_attributes = step validate_input(model: model, params: params)
        updated_article = step assign_attributes(model: model, attributes: validated_attributes)
        persisted_article = step persist_with_transaction(updated_article)

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

      def assign_attributes(model:, attributes:)
        assignable_attributes = attributes.except(:user_id)
        assignable_attributes.delete(:body) if assignable_attributes[:body].nil?
        model.assign_attributes(assignable_attributes)
        Success(model)
      end

      def persist_with_transaction(model)
        persisted_model = nil

        Article.transaction do
          if model.save
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
