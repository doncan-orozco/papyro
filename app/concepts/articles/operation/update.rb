# frozen_string_literal: true

module Articles
  module Operation
    class Update < Trailblazer::Operation
      step :validate_input
      step :update_article

      def validate_input(ctx, params:, model:, **)
        # Support legacy `content` key on the API tests and public forms.
        params = params.dup
        params[:body] = params.delete(:content) if params.key?(:content)

        form = Articles::Form::Update.new(model)
        # Include id in params for slug uniqueness validation
        params_with_defaults = params.merge(id: model.id)
        params_with_defaults[:published_at] ||= model.published_at
        params_with_defaults[:body] ||= model.body.to_s

        if form.validate(params_with_defaults)
          form.sync
          ctx[:model] = model
          true
        else
          form.sync
          apply_form_errors_to_model(model, form)
          ctx[:model] = model
          ctx[:errors] = model.errors.to_hash
          false
        end
      end

      def update_article(ctx, model:, **)
        # Model already pre-authorized by controller
        # Do NOT update user_id or other ownership fields
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
