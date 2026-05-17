# frozen_string_literal: true

module Users
  module Contract
    class PasswordResetRequest < Dry::Validation::Contract
      params do
        required(:email_address).filled(:string)
      end

      rule(:email_address) do
        key.failure(I18n.t("errors.messages.invalid_email")) unless URI::MailTo::EMAIL_REGEXP.match?(value)
      end
    end
  end
end
