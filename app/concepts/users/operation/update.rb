# frozen_string_literal: true

module Users
  module Operation
    class Update < Trailblazer::Operation
      step :validate_input
      step :update_user
      
      def validate_input(ctx, params:, user:, **)
        contract = Users::Contract::Update.new(user_id: user.id)
        result = contract.call(params)
        
        if result.success?
          ctx[:validated_params] = result.to_h
          true
        else
          ctx[:errors] = result.errors.to_h
          false
        end
      end
      
      def update_user(ctx, validated_params:, user:, **)
        if user.update(validated_params)
          ctx[:model] = user
          true
        else
          ctx[:errors] = user.errors.to_hash
          false
        end
      end
    end
  end
end
