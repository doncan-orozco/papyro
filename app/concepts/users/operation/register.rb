# frozen_string_literal: true

module Users
  module Operation
    class Register < Core::Operation
      def call(params:)
        validated_attributes = step validate_input(params)
        persisted_user = step persist_user_with_profile(validated_attributes)

        { model: persisted_user }
      end

      private

      def validate_input(params)
        normalized_params = normalize_params(params)
        contract = Users::Contract::Register.new
        result = contract.call(normalized_params)

        return Success(result.to_h) if result.success?

        user = User.new(email_address: normalized_params[:email_address])
        fail_with_model!(inject_errors!(user, result.errors.to_h))
      end

      def persist_user_with_profile(attributes)
        user = User.new(email_address: attributes[:email_address], password: attributes[:password])

        begin
          ActiveRecord::Base.transaction do
            user.save!

            username = User.next_available_profile_username(User.build_oauth_username_base(user.email_address))
            user.create_profile!(
              display_name: build_default_display_name(username),
              username: username
            )
          end
        rescue ActiveRecord::RecordInvalid => e
          record = e.record
          if record == user
            return fail_with_model!(user)
          end

          inject_errors!(user, record.errors.to_hash)
          return fail_with_model!(user)
        end

        Success(user)
      end

      def normalize_params(params)
        params.merge(email_address: params[:email_address].to_s.strip.downcase)
      end

      def build_default_display_name(username)
        username.to_s.tr("_", " ").split.map(&:capitalize).join(" ")
      end
    end
  end
end
