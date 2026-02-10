# frozen_string_literal: true

module Articles
  module Operation
    class Create < Trailblazer::Operation
      step :validate_input
      step :create_article

      def validate_input(ctx, params:, **)
        contract = Articles::Contract::Create.new
        result = contract.call(params)

        if result.success?
          ctx[:validated_params] = result.to_h
          true
        else
          ctx[:errors] = result.errors.to_h
          false
        end
      end

      def create_article(ctx, validated_params:, **)
        article = ::Article.new(validated_params)

        if article.save
          ctx[:model] = article
          true
        else
          ctx[:errors] = article.errors.to_hash
          false
        end
      end
    end
  end
end
