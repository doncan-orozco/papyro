# frozen_string_literal: true

module Articles
  module Operation
    class Create < Trailblazer::Operation
      step :validate_input
      step :prepare_body
      step :create_article

      def validate_input(ctx, params:, **)
        # Support legacy `content` key on the API tests and public forms.
        params = params.dup
        params[:body] = params.delete(:content) if params.key?(:content)

        form = Articles::Form::Create.new(::Article.new)

        if form.validate(params)
          form.sync
          ctx[:model] = form.model
          true
        else
          form.sync
          model = form.model
          apply_form_errors_to_model(model, form)
          ctx[:model] = model
          ctx[:errors] = model.errors.to_hash
          false
        end
      end

      def prepare_body(_ctx, model:, **)
        # Ensure body is never nil to prevent NOT NULL constraint violations
        model.body = model.body.presence || ""
        true
      end

      def create_article(ctx, model:, **)
        if model.save
          ctx[:model] = model
          true
        else
          ctx[:model] = model
          ctx[:errors] = model.errors.to_hash
          false
        end
      end

      private

      def apply_form_errors_to_model(model, form)
        form.errors.messages.each do |attribute, messages|
          Array(messages).each { |message| model.errors.add(attribute, message) }
        end
      end
    end
  end
end
