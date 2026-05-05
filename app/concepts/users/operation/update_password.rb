# frozen_string_literal: true

module Users
  module Operation
    class UpdatePassword < ApplicationOperation
      def call(params:, user:)
        validated_attributes = step validate_input(params: params, user: user)
        authenticated_user = step authenticate_user(user: user, current_password: validated_attributes[:current_password])
        persisted_user = step persist_password(user: authenticated_user, password: validated_attributes[:password])

        { model: persisted_user }
      end

      private

      def validate_input(params:, user:)
        contract = Users::Contract::UpdatePassword.new
        result = contract.call(params)

        return Success(result.to_h) if result.success?

        fail_with_model!(inject_errors!(user, result.errors.to_h))
      end

      def authenticate_user(user:, current_password:)
        return Success(user) if user.authenticate(current_password)

        user.errors.add(:current_password, I18n.t("users.operations.update_password.current_password_invalid"))
        fail_with_model!(user)
      end

      def persist_password(user:, password:)
        user.password = password

        return Success(user) if user.save

        fail_with_model!(user)
      end
    end
  end
end
