# frozen_string_literal: true

module Users
  module Form
    class Login < Reform::Form
      feature Reform::Form::Dry
      include Reform::Form::ActiveModel
      include Reform::Form::ActiveModel::FormBuilderMethods

      model :user

      property :email_address
      property :password, virtual: true

      validation do
        params do
          required(:email_address).filled(:string)
          required(:password).filled(:string)
        end

        rule(:email_address) do
          key.failure(I18n.t("errors.messages.invalid_email")) unless URI::MailTo::EMAIL_REGEXP.match?(value)
        end
      end

      def email_address=(value)
        super(value.to_s.strip.downcase)
      end
    end
  end
end
