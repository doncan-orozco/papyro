# frozen_string_literal: true

module Articles
  module Operation
    class Create < Dry::Operation
      include Dry::Monads[:result]

      def call(params:)
        input = { params: params }
        sanitized_input = step sanitize_params(input)
        validated_input = step validate_input(sanitized_input)

        step create_article(validated_input)
      end

      private

      def sanitize_params(input)
        sanitized = input.fetch(:params).dup
        sanitized[:body] = sanitized.delete(:content) if sanitized.key?(:content)
        sanitized[:title] = sanitized[:title].to_s.strip if sanitized.key?(:title)
        sanitized[:slug] = sanitized[:slug].to_s.strip.downcase if sanitized.key?(:slug)
        Success(input.merge(params: sanitized))
      end

      def validate_input(input)
        contract_result = Articles::Contract::Create.new.call(input[:params])
        return Failure(errors: contract_result.errors.to_h, model: build_article(input[:params])) if contract_result.failure?

        Success(input.merge(attributes: contract_result.to_h))
      end

      def create_article(input)
        article = build_article(input[:attributes])
        return Success(model: article) if article.save

        Failure(errors: article.errors.to_hash, model: article)
      end

      def build_article(attributes)
        normalized_attributes = attributes.dup
        normalized_attributes[:body] = "" if normalized_attributes[:body].nil?
        Article.new(normalized_attributes)
      end
    end
  end
end
