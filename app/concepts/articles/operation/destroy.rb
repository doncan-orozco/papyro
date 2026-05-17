# frozen_string_literal: true

module Articles
  module Operation
    class Destroy < Core::Operation
      def call(model:)
        soft_deleted_model = step soft_delete_model(model)
        { model: soft_deleted_model }
      end

      private

      def soft_delete_model(model)
        return Success(model) if model.update(deleted_at: Time.current)

        fail_with_model!(model)
      end
    end
  end
end
