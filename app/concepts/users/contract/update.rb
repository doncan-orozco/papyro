# frozen_string_literal: true

module Users
  module Contract
    class Update < Dry::Validation::Contract
      option :user_id, optional: true
      
      params do
        optional(:email_address).filled(:string)
        optional(:password).filled(:string)
        optional(:password_confirmation).filled(:string)
      end

      rule(:email_address) do
        if key? && value
          unless URI::MailTo::EMAIL_REGEXP.match?(value)
            key.failure(I18n.t('errors.messages.invalid_email'))
          end
        end
      end

      rule(:password, :password_confirmation) do
        if values[:password] && values[:password_confirmation]
          if values[:password] != values[:password_confirmation]
            key(:password_confirmation).failure(I18n.t('errors.messages.password_mismatch'))
          end
        end
      end

      rule(:email_address) do
        if key? && value && user_id
          normalized_email = value.strip.downcase
          if ::User.where.not(id: user_id).exists?(email_address: normalized_email)
            key.failure(I18n.t('errors.messages.email_taken'))
          end
        end
      end
    end
  end
end
