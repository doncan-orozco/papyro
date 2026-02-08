# frozen_string_literal: true

module User
  module Contract
    class Create < Dry::Validation::Contract
      params do
        required(:email_address).filled(:string)
        required(:password).filled(:string)
        required(:password_confirmation).filled(:string)
      end

      rule(:email_address) do
        unless URI::MailTo::EMAIL_REGEXP.match?(value)
          key.failure("must be a valid email address")
        end
      end

      rule(:password, :password_confirmation) do
        if values[:password] != values[:password_confirmation]
          key(:password_confirmation).failure("must match password")
        end
      end

      rule(:email_address) do
        normalized_email = value.strip.downcase
        if User.where.not(id: context[:user_id]).exists?(email_address: normalized_email)
          key.failure("is already taken")
        end
      end
    end
  end
end
