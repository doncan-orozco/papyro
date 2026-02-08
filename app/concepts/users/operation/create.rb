# frozen_string_literal: true

module Users
  module Operation
    class Create < Trailblazer::Operation
      step :validate_input
      step :create_user
      
      def validate_input(ctx, params:, **)
        contract = Users::Contract::Create.new
        result = contract.call(params)
        
        if result.success?
          ctx[:validated_params] = result.to_h
          true
        else
          ctx[:errors] = result.errors.to_h
          false
        end
      end
      
      def create_user(ctx, validated_params:, **)
        user = ::User.new(validated_params)
        
        if user.save
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
