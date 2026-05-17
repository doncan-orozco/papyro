# frozen_string_literal: true

module Users
  module Contract
    class UpdateProfile < Dry::Validation::Contract
      params do
        optional(:email_address).filled(:string)
        optional(:profile_attributes).maybe(:hash) do
          optional(:display_name).maybe(:string)
          required(:username).filled(:string)
          optional(:portrait).maybe(Types::Any)
          optional(:bio).maybe(:string)
          optional(:location).maybe(:string)
          optional(:website_url).maybe(:string)
          optional(:x_handle).maybe(:string)
          optional(:linkedin_handle).maybe(:string)
        end
      end
    end
  end
end
