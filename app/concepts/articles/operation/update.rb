# frozen_string_literal: true

module Articles
  module Operation
    class Update < Trailblazer::Operation
      step :find_article
      step :validate_input
      step :update_article

      def find_article(ctx, params:, **)
        article = ::Article.find_by(id: params[:id])
        if article
          ctx[:model] = article
          true
        else
          ctx[:errors] = { base: [I18n.t("errors.messages.article_not_found")] }
          false
        end
      end

      def validate_input(ctx, params:, **)
        contract = Articles::Contract::Update.new
        result = contract.call(params)

        if result.success?
          ctx[:validated_params] = result.to_h
          true
        else
          ctx[:errors] = result.errors.to_h
          false
        end
      end

      def update_article(ctx, model:, validated_params:, **)
        if model.update(validated_params.except(:id))
          true
        else
          ctx[:errors] = model.errors.to_hash
          false
        end
      end
    end
  end
end
