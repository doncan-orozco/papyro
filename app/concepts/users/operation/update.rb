# frozen_string_literal: true

module Users
  module Operation
    class Update < Dry::Operation
      include Dry::Monads[:result]

      def call(params:, user:)
        input = { params: params, user: user }
        form_input = step prepare_form(input)
        validated_input = step validate_input(form_input)
        synced_input = step sync_form(validated_input)

        step persist_user(synced_input)
      end

      private

      def prepare_form(input)
        user = input.fetch(:user)
        form = Users::Form::Update.new(user)
        sanitized_params = input.fetch(:params).compact_blank
        params_with_context = sanitized_params.merge(id: user.id)
        Success(input.merge(form: form, params: params_with_context))
      end

      def validate_input(input)
        form = input.fetch(:form)
        user = input.fetch(:user)
        params_with_context = input.fetch(:params)
        return Failure(errors: form.errors.to_hash, model: user, form: form) unless form.validate(params_with_context)

        Success(input)
      end

      def sync_form(input)
        input.fetch(:form).sync
        Success(input)
      end

      def persist_user(input)
        user = input.fetch(:user)
        form = input.fetch(:form)
        return Success(model: user, form: form) if user.save

        Failure(errors: user.errors.to_hash, model: user, form: form)
      end
    end
  end
end
