# frozen_string_literal: true

module Users
  module Operation
    class Create < ApplicationOperation
      def call(params:)
        validated_attributes = step validate_input(params)
        user = step build_user(validated_attributes)
        persisted_user = step persist_user(user)

        { model: persisted_user }
      end

      private

      def validate_input(params)
        contract = Users::Contract::Create.new
        result = contract.call(params)

        return Success(result.to_h) if result.success?

        user = User.new(email_address: params[:email_address])
        profile_attrs = params[:profile_attributes] || {}
        user.build_profile(display_name: profile_attrs[:display_name])
        fail_with_model!(inject_errors!(user, result.errors.to_h))
      end

      def build_user(attributes)
        user = ::User.new(attributes.except(:profile_attributes))
        profile_attrs = attributes[:profile_attributes] || {}
        user.build_profile(display_name: profile_attrs[:display_name])
        Success(user)
      end

      def persist_user(user)
        return Success(user) if user.save

        fail_with_model!(user)
      end
    end
  end
end
