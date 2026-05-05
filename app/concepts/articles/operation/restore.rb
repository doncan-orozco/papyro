# frozen_string_literal: true

module Articles
  module Operation
    class Restore < ApplicationOperation
      def call(model:)
        restored_model = step restore_model(model)
        { model: restored_model }
      end

      private

      def restore_model(model)
        return Success(model) if model.update(deleted_at: nil)

        fail_with_model!(model)
      end
    end
  end
end
