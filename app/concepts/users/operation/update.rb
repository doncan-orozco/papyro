# frozen_string_literal: true

module Users
  module Operation
    class Update < Trailblazer::Operation
      step :validate_input
      step :update_user

      def validate_input(ctx, params:, user:, **)
        form = Users::Form::Update.new(user)
        ctx[:form] = form
        params_with_context = params.merge(id: user.id)

        if form.validate(params_with_context)
          form.sync

          # Apply password updates manually because password fields are virtual.
          if form.password.present?
            user.password = form.password
            user.password_confirmation = form.password_confirmation
          end

          ctx[:model] = user
          true
        else
          form.sync
          apply_form_errors_to_model(user, form)
          ctx[:model] = user
          ctx[:errors] = user.errors.to_hash
          false
        end
      end

      def update_user(ctx, user:, **)
        if user.save
          ctx[:model] = user
          true
        else
          ctx[:model] = user
          ctx[:errors] = user.errors.to_hash
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
