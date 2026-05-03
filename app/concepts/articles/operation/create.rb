# frozen_string_literal: true

module Articles
  module Operation
    class Create < ApplicationOperation
      def call(params:, user:)
        validated_attributes = step validate_input(params)
        article = step build_and_enforce_domain_rules(validated_attributes, user)
        persisted_article = step persist_with_transaction(article)

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

      def build_and_enforce_domain_rules(attributes, user)
        article = user.articles.build(attributes)
        Success(article)
      end

      def persist_with_transaction(article)
        persisted_article = nil

        Article.transaction do
          if article.save
            persisted_article = article
          else
            raise ActiveRecord::Rollback
          end
        end

        return Success(persisted_article) if persisted_article

        fail_with_model!(article)
      end
    end
  end
end
