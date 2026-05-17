# frozen_string_literal: true

module Users
  module Contract
    class UpdatePassword < Dry::Validation::Contract
      params do
        required(:current_password).filled(:string)
        required(:password).filled(:string)
        required(:password_confirmation).filled(:string)
      end

      rule(:password, :password_confirmation) do
        if values[:password] != values[:password_confirmation]
          key(:password_confirmation).failure(I18n.t("errors.messages.password_mismatch"))
        end
      end
    end
  end
end
