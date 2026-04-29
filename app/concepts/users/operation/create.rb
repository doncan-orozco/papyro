# frozen_string_literal: true

module Users
  module Operation
    class Create < Dry::Operation
      include Dry::Monads[:result]

      def call(params:)
        input = { params: params }
        validated_input = step validate_input(input)

        step create_user(validated_input)
      end

      private

      def validate_input(input)
        contract = Users::Contract::Create.new
        result = contract.call(input.fetch(:params))

        return Failure(errors: result.errors.to_h) if result.failure?

        Success(input.merge(attributes: result.to_h))
      end

      def create_user(input)
        user = ::User.new(input.fetch(:attributes))
        return Success(model: user) if user.save

        Failure(errors: user.errors.to_hash, model: user)
      end
    end
  end
end
