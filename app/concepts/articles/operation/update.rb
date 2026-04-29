# frozen_string_literal: true

module Articles
  module Operation
    class Update < Dry::Operation
      include Dry::Monads[:result]

      def call(model:, params:)
        input = { model: model, params: params }
        sanitized_input = step sanitize_params(input)
        params_with_defaults = step prepare_defaults(sanitized_input)
        validated_input = step validate_input(params_with_defaults)
        input_with_model = step assign_attributes(validated_input)

        step persist_model(input_with_model)
      end

      private

      def sanitize_params(input)
        sanitized = input.fetch(:params).dup
        sanitized[:body] = sanitized.delete(:content) if sanitized.key?(:content)
        sanitized[:title] = sanitized[:title].to_s.strip if sanitized.key?(:title)
        sanitized[:slug] = sanitized[:slug].to_s.strip.downcase if sanitized.key?(:slug)
        Success(input.merge(params: sanitized))
      end

      def prepare_defaults(input)
        model = input.fetch(:model)
        params = input.fetch(:params)
        params_with_defaults = params.merge(
          title: params.fetch(:title, model.title),
          slug: params.fetch(:slug, model.slug),
          status: params.fetch(:status, model.status),
          body: params.key?(:body) ? params[:body] : model.body.content.to_s,
          published_at: params.key?(:published_at) ? params[:published_at] : model.published_at,
          excerpt: params.key?(:excerpt) ? params[:excerpt] : model.excerpt
        )

        Success(input.merge(params: params_with_defaults))
      end

      def validate_input(input)
        model = input.fetch(:model)
        contract_result = Articles::Contract::Update.new(article_id: model.id).call(input[:params])
        return Failure(errors: contract_result.errors.to_h, model: model) if contract_result.failure?

        Success(input.merge(attributes: contract_result.to_h))
      end

      def assign_attributes(input)
        model = input.fetch(:model)
        assignable_attributes = input.fetch(:attributes).except(:user_id)
        assignable_attributes.delete(:body) if assignable_attributes[:body].nil?
        model.assign_attributes(assignable_attributes)
        Success(input.merge(model: model))
      end

      def persist_model(input)
        model = input.fetch(:model)
        return Success(model: model) if model.save

        Failure(errors: model.errors.to_hash, model: model)
      end
    end
  end
end
