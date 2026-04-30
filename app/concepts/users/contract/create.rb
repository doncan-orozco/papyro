# frozen_string_literal: true

module Users
  module Contract
    class Create < Dry::Validation::Contract
      params do
        required(:display_name).filled(:string)
        required(:email_address).filled(:string)
        required(:password).filled(:string)
        required(:password_confirmation).filled(:string)
      end

      rule(:display_name) do
        if value.length > 100
          key.failure(I18n.t("users.forms.validation.display_name_too_long"))
        end
      end

      rule(:email_address) do
        unless URI::MailTo::EMAIL_REGEXP.match?(value)
          key.failure(I18n.t("errors.messages.invalid_email"))
        end
      end

      rule(:password, :password_confirmation) do
        if values[:password] != values[:password_confirmation]
          key(:password_confirmation).failure(I18n.t("errors.messages.password_mismatch"))
        end
      end

      rule(:email_address) do
        normalized_email = value.strip.downcase
        if ::User.exists?(email_address: normalized_email)
          key.failure(I18n.t("errors.messages.email_taken"))
        end
      end
    end
  end
end
