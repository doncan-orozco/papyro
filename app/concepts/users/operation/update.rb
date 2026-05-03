# frozen_string_literal: true

module Users
  module Operation
    class Update < ApplicationOperation
      def call(params:, user:)
        validated_attributes = step validate_input(params: params, user: user)
        updated_user = step assign_attributes(user: user, attributes: validated_attributes)
        persisted_user = step persist_user(updated_user)

        { model: persisted_user }
      end

      private

      def validate_input(params:, user:)
        contract = Users::Contract::Update.new
        result = contract.call(params.compact_blank)

        return Success(result.to_h) if result.success?

        fail_with_model!(inject_errors!(user, result.errors.to_h))
      end

      def assign_attributes(user:, attributes:)
        profile = user.profile || user.build_profile
        profile_attributes = attributes[:profile_attributes]
        if profile_attributes.is_a?(Hash) && profile_attributes.key?(:display_name)
          profile.display_name = profile_attributes[:display_name]
        end
        user.email_address = attributes[:email_address] if attributes.key?(:email_address)

        if attributes.key?(:password)
          user.password = attributes[:password]
          user.password_confirmation = attributes[:password_confirmation]
        end

        Success(user)
      end

      def persist_user(user)
        return Success(user) if user.save

        fail_with_model!(user)
      end
    end
  end
end
