# frozen_string_literal: true

module Users
  module Contract
    class UpdateProfile < Dry::Validation::Contract
      params do
        optional(:email_address).filled(:string)
        optional(:profile_attributes).maybe(:hash)
      end
    end
  end
end
