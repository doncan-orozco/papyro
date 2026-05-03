# frozen_string_literal: true

module Users
  module Contract
    class Create < Dry::Validation::Contract
      params do
        required(:email_address).filled(:string)
        required(:password).filled(:string)
        required(:password_confirmation).filled(:string)
        optional(:profile_attributes).maybe(:hash) do
          optional(:display_name).maybe(:string)
        end
      end

      rule(:password, :password_confirmation) do
        if values[:password] != values[:password_confirmation]
          key(:password_confirmation).failure(I18n.t("errors.messages.password_mismatch"))
        end
      end
    end
  end
end
