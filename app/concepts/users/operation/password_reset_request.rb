# frozen_string_literal: true

module Users
  module Operation
    class PasswordResetRequest < ApplicationOperation
      def call(params:)
        validated_attributes = step validate_input(params)
        step deliver_reset_instructions(validated_attributes[:email_address])

        { email_address: validated_attributes[:email_address] }
      end

      private

      def validate_input(params)
        normalized_params = normalize_params(params)
        contract = Users::Contract::PasswordResetRequest.new
        result = contract.call(normalized_params)

        return Success(result.to_h) if result.success?

        user = User.new(email_address: normalized_params[:email_address])
        fail_with_model!(inject_errors!(user, result.errors.to_h))
      end

      def deliver_reset_instructions(email_address)
        user = User.find_by(email_address: email_address)
        PasswordsMailer.reset(user).deliver_later if user.present?
        Success(email_address)
      end

      def normalize_params(params)
        params.merge(email_address: params[:email_address].to_s.strip.downcase)
      end
    end
  end
end
