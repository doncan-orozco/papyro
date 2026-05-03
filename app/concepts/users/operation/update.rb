# frozen_string_literal: true

module Users
  module Operation
    class Update < ApplicationOperation
      def call(params:, user:)
        validated_attributes = step validate_input(params: params, user: user)
        persisted_user = step persist_user(user: user, attributes: validated_attributes)

        { model: persisted_user }
      end

      private

      def validate_input(params:, user:)
        contract = Users::Contract::Update.new
        result = contract.call(params.compact_blank)

        return Success(result.to_h) if result.success?

        fail_with_model!(inject_errors!(user, result.errors.to_h))
      end

      def persist_user(user:, attributes:)
        user.assign_attributes(attributes)

        return Success(user) if user.save

        fail_with_model!(user)
      end
    end
  end
end
