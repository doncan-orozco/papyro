# frozen_string_literal: true

module Users
  module Operation
    class Create < ApplicationOperation
      def call(params:)
        validated_attributes = step validate_input(params)
        persisted_user = step persist_user(validated_attributes)

        { model: persisted_user }
      end

      private

      def validate_input(params)
        contract = Users::Contract::Create.new
        result = contract.call(params)

        return Success(result.to_h) if result.success?

        # Keep user-typed fields for re-render while avoiding password echoing.
        user = User.new(params.except(:password, :password_confirmation))
        fail_with_model!(inject_errors!(user, result.errors.to_h))
      end

      def persist_user(attributes)
        user = ::User.new(attributes)

        return Success(user) if user.save

        fail_with_model!(user)
      end
    end
  end
end
