# frozen_string_literal: true

module Users
  module Form
    class PasswordResetRequest
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :email_address, :string

      validates :email_address, presence: true

      def validate(params)
        self.email_address = params[:email_address]
        contract_result = contract.call(email_address: email_address)

        merge_contract_errors(contract_result.errors.to_h)
        contract_result.success?
      end

      private

      def contract
        @contract ||= Class.new(Dry::Validation::Contract) do
          params do
            required(:email_address).filled(:string)
          end

          rule(:email_address) do
            key.failure(I18n.t("errors.messages.invalid_email")) unless URI::MailTo::EMAIL_REGEXP.match?(value)
          end
        end.new
      end

      def merge_contract_errors(errors_hash)
        errors.clear
        errors_hash.each do |field, messages|
          Array(messages).each { |message| errors.add(field, message) }
        end
      end

      def email_address=(value)
        super(value.to_s.strip.downcase)
      end
    end
  end
end
