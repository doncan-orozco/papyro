# frozen_string_literal: true

module Users
  module Operation
    class UpdateProfile < Core::Operation
      def call(params:, user:)
        validated_attributes = step validate_input(params: params, user: user)
        persisted_user = step persist_user(user: user, attributes: validated_attributes)

        { model: persisted_user }
      end

      private

      def validate_input(params:, user:)
        contract = Users::Contract::UpdateProfile.new
        result = contract.call(normalized_params(params: params).compact_blank)

        return Success(result.to_h) if result.success?

        fail_with_model!(inject_errors!(user, result.errors.to_h))
      end

      def normalized_params(params:)
        params.deep_dup
      end

      def persist_user(user:, attributes:)
        profile_attributes = attributes["profile_attributes"] || attributes[:profile_attributes]

        user.assign_attributes(profile_attributes: profile_attributes) if profile_attributes.present?
        return Success(user) if user.save

        fail_with_model!(user)
      end
    end
  end
end
