# frozen_string_literal: true

module Users
  module Form
    class Update < Reform::Form
      feature Reform::Form::Dry
      include Reform::Form::ActiveModel
      include Reform::Form::ActiveModel::FormBuilderMethods

      model :user

      property :id, virtual: true
      property :email_address
      property :password, virtual: true
      property :password_confirmation, virtual: true

      validation do
        params do
          optional(:id).maybe(:integer)
          optional(:email_address).filled(:string)
          optional(:password).maybe(:string)
          optional(:password_confirmation).maybe(:string)
        end

        rule(:email_address) do
          if key? && value
            key.failure(I18n.t("errors.messages.invalid_email")) unless URI::MailTo::EMAIL_REGEXP.match?(value)
          end
        end

        rule(:password, :password_confirmation) do
          if values[:password] && values[:password_confirmation] && values[:password] != values[:password_confirmation]
            key(:password_confirmation).failure(I18n.t("errors.messages.password_mismatch"))
          end
        end

        rule(:email_address) do
          if key? && value && values[:id]
            normalized_email = value.strip.downcase
            if ::User.where.not(id: values[:id]).exists?(email_address: normalized_email)
              key.failure(I18n.t("errors.messages.email_taken"))
            end
          end
        end
      end

      def email_address=(value)
        super(value.to_s.strip.downcase)
      end
    end
  end
end
