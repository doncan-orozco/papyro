# frozen_string_literal: true

module Articles
  module Operation
    class Destroy < Dry::Operation
      include Dry::Monads[:result]

      def call(model:)
        step destroy_model(model: model)
      end

      private

      def destroy_model(input)
        model = input.fetch(:model)
        return Success(model: model) if model.destroy

        Failure(errors: model.errors.to_hash, model: model)
      end
    end
  end
end
