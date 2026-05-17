# frozen_string_literal: true

module Users
  module Contract
    class Update < Dry::Validation::Contract
      params do
        optional(:email_address).filled(:string)
        optional(:password).filled(:string)
        optional(:password_confirmation).filled(:string)
        optional(:profile_attributes).maybe(:hash)
      end

      rule(:password, :password_confirmation) do
        if values[:password] && values[:password_confirmation]
          if values[:password] != values[:password_confirmation]
            key(:password_confirmation).failure(I18n.t("errors.messages.password_mismatch"))
          end
        end
      end
    end
  end
end
