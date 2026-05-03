# frozen_string_literal: true

module Articles
  module Operation
    class Destroy < ApplicationOperation
      def call(model:)
        destroyed_model = step destroy_model(model)
        { model: destroyed_model }
      end

      private

      def destroy_model(model)
        return Success(model) if model.destroy

        fail_with_model!(model)
      end
    end
  end
end
