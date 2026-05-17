# frozen_string_literal: true

module Core
  class Operation < Dry::Operation
    include Dry::Monads[:result]

    private

    def model_errors(model)
      model.errors.messages
    end

    def inject_errors!(model, errors_hash)
      errors_hash.each do |field, messages|
        Array(messages).each do |message|
          model.errors.add(field, message)
        end
      end
      model
    end

    def fail_with_business_error!(model, message)
      model.errors.add(:base, message)
      fail_with_model!(model)
    end

    def fail_with_code!(model, code, message: nil)
      model.errors.add(:base, message) if message.present?
      Failure(model: model, errors: model_errors(model), message: failure_message(model), code: code)
    end

    def fail_with_model!(model)
      Failure(model: model, errors: model_errors(model), message: failure_message(model))
    end

    def failure_message(model)
      Array(model_errors(model)[:base]).compact.first
    end
  end
end
