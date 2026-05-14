# frozen_string_literal: true

module Articles
  module Operation
    class Purge < Core::Operation
      def call(model:)
        purged_model = step purge_model(model)
        { model: purged_model }
      end

      private

      def purge_model(model)
        return Success(model) if model.destroy

        fail_with_model!(model)
      end
    end
  end
end
