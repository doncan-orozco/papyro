# frozen_string_literal: true

module Articles
  module Operation
    class Destroy < Trailblazer::Operation
      step :destroy_article

      # No find_article step - model is pre-authorized by controller

      def destroy_article(ctx, model:, **)
        if model.destroy
          ctx[:model] = model
          true
        else
          ctx[:errors] = model.errors.to_hash
          false
        end
      end
    end
  end
end
