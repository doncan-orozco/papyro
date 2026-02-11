# frozen_string_literal: true

module Articles
  module Operation
    class Update < Trailblazer::Operation
      step :validate_input
      step :update_article

      def validate_input(ctx, params:, model:, **)
        contract = Articles::Contract::Update.new
        # Include id in params for slug uniqueness validation
        result = contract.call(params.merge(id: model.id))

        if result.success?
          ctx[:validated_params] = result.to_h
          true
        else
          # Domain-scoped error keys
          ctx[:errors] = result.errors.to_h.transform_values do |messages|
            messages.map { |msg| I18n.t("articles.errors.#{msg}") }
          end
          false
        end
      end

      def update_article(ctx, model:, validated_params:, **)
        # Model already pre-authorized by controller
        # Do NOT update user_id or other ownership fields
        if model.update(validated_params.except(:id, :user_id))
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
