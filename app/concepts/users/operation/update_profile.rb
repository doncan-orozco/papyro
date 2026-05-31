# frozen_string_literal: true

module Users
  module Operation
    class UpdateProfile < Core::Operation
      def call(params:, user:, locale: I18n.locale)
        validated_attributes = step validate_input(params: params, user: user)
        persisted_user = step persist_user(user: user, attributes: validated_attributes, locale: locale)

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
        normalized = params.deep_dup
        normalized
      end

      def persist_user(user:, attributes:, locale:)
        selected_locale = locale.to_s.presence || I18n.default_locale.to_s
        profile_attributes = extract_profile_attributes(attributes: attributes)

        persisted = Mobility.with_locale(selected_locale) do
          # Assign profile_attributes in locale context so translated fields write to selected locale.
          user.assign_attributes(profile_attributes: profile_attributes) if profile_attributes.present?
          user.save
        end
        return Success(user) if persisted

        fail_with_model!(user)
      end

      def extract_profile_attributes(attributes:)
        profile_attributes = attributes["profile_attributes"] || attributes[:profile_attributes]
        return if profile_attributes.blank?

        normalized_profile_attributes = profile_attributes.deep_dup
        normalized_profile_attributes.delete("bio_locale")
        normalized_profile_attributes.delete(:bio_locale)
        normalized_profile_attributes
      end
    end
  end
end
