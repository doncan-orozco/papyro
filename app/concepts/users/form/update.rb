# frozen_string_literal: true

module Users
  module Form
    class Update
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :id, :integer
      attribute :email_address, :string
      attribute :password, :string
      attribute :password_confirmation, :string

      attr_reader :model

      def initialize(model, attributes = {})
        @model = model
        super(attributes)
      end

      def validate(params)
        assign_attributes(params)
        contract_result = Users::Contract::Update.new(user_id: id).call(validation_params)

        merge_contract_errors(contract_result.errors.to_h)
        contract_result.success?
      end

      def sync
        model.email_address = email_address if email_address.present?

        if password.present?
          model.password = password
          model.password_confirmation = password_confirmation
        end
      end

      private

      def assign_attributes(params)
        self.id = params[:id]
        self.email_address = params[:email_address] if params.key?(:email_address)
        self.password = params[:password] if params.key?(:password)
        self.password_confirmation = params[:password_confirmation] if params.key?(:password_confirmation)
      end

      def validation_params
        {
          email_address: email_address,
          password: password,
          password_confirmation: password_confirmation
        }.compact
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
