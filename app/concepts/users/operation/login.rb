# frozen_string_literal: true

module Users
  module Operation
    class Login < Core::Operation
      def call(params:)
        validated_attributes = step validate_input(params)
        authenticated_user = step authenticate_user(validated_attributes)

        { model: authenticated_user }
      end

      private

      def validate_input(params)
        normalized_params = normalize_params(params)
        contract = Users::Contract::Login.new
        result = contract.call(normalized_params)

        return Success(result.to_h) if result.success?

        user = User.new(email_address: normalized_params[:email_address])
        fail_with_model!(inject_errors!(user, result.errors.to_h))
      end

      def authenticate_user(params)
        user = User.authenticate_by(email_address: params[:email_address], password: params[:password])
        return Success(user) if user.present?

        fail_with_code!(
          User.new(email_address: params[:email_address]),
          :invalid_credentials,
          message: I18n.t("sessions.create.invalid_credentials")
        )
      end

      def normalize_params(params)
        params.merge(email_address: params[:email_address].to_s.strip.downcase)
      end
    end
  end
end
