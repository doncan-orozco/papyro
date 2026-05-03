# frozen_string_literal: true

module Articles
  module Operation
    class Create < ApplicationOperation
      def call(params:, user:)
        validated_attributes = step validate_input(params)
        persisted_article    = step persist_article(attributes: validated_attributes, user: user)

        { model: persisted_article }
      end

      private

      def validate_input(params)
        contract_result = Articles::Contract::Create.new.call(params)

        if contract_result.failure?
          invalid_article = inject_errors!(Article.new(params), contract_result.errors.to_h)
          return fail_with_model!(invalid_article)
        end

        Success(contract_result.to_h)
      end

      def persist_article(attributes:, user:)
        article = user.articles.build(attributes)

        return Success(article) if article.save

        fail_with_model!(article)
      end
    end
  end
end
