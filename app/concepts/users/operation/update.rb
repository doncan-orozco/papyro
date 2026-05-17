# frozen_string_literal: true

module Users
  module Operation
    class Update < Core::Operation
      def call(params:, user:)
        validated_attributes = step validate_input(params: params, user: user)
        persisted_user = step persist_user(user: user, attributes: validated_attributes)

        { model: persisted_user }
      end

      private

      def validate_input(params:, user:)
        contract = Users::Contract::Update.new
        result = contract.call(normalized_params(params: params, user: user).compact_blank)

        return Success(result.to_h) if result.success?

        fail_with_model!(inject_errors!(user, result.errors.to_h))
      end

      def normalized_params(params:, user:)
        normalized = params.deep_dup
        profile_attributes = normalized["profile_attributes"] || normalized[:profile_attributes]
        return normalized unless profile_attributes

        profile_attributes = profile_attributes.to_h

        if user.profile.present?
          # For has_one nested updates, keep updating the existing profile record.
          profile_attributes["id"] = user.profile.id
          profile_attributes["username"] = user.profile.username
        end

        normalized["profile_attributes"] = profile_attributes
        normalized
      end

      def persist_user(user:, attributes:)
        user.assign_attributes(attributes)

        return Success(user) if user.save

        fail_with_model!(user)
      end
    end
  end
end
