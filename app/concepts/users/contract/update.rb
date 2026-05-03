# frozen_string_literal: true

module Users
  module Contract
    class Update < Dry::Validation::Contract
      params do
        optional(:display_name).filled(:string)
        optional(:email_address).filled(:string)
        optional(:password).filled(:string)
        optional(:password_confirmation).filled(:string)
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
