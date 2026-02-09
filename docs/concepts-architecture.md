# Papyro Concepts - Operations & Contracts

This directory contains the business logic layer following the Trailblazer architecture pattern.

## Architecture Overview

```
app/concepts/
  └── users/                    # Domain namespace
      ├── contract/            # Dry-Validation contracts
      │   ├── create.rb       # Validation for user creation
      │   └── update.rb       # Validation for user updates
      └── operation/          # Trailblazer operations
          ├── create.rb       # User creation logic
          └── update.rb       # User update logic
```

## How It Works

### 1. Contracts (Validation)

Contracts define ALL validation rules. The User model has NO validations.

```ruby
# app/concepts/users/contract/create.rb
module Users
  module Contract
    class Create < Dry::Validation::Contract
      params do
        required(:email_address).filled(:string)
        required(:password).filled(:string)
        required(:password_confirmation).filled(:string)
      end

      rule(:email_address) do
        unless URI::MailTo::EMAIL_REGEXP.match?(value)
          key.failure(I18n.t('errors.messages.invalid_email'))
        end
      end
      
      # ... more rules
    end
  end
end
```

### 2. Operations (Business Logic)

Operations orchestrate the flow: validate → persist → return result.

```ruby
# app/concepts/users/operation/create.rb
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
```

### 3. Usage in Controllers

Controllers call operations and handle results:

```ruby
# app/controllers/passwords_controller.rb
def update
  result = Users::Operation::Update.call(
    params: params.permit(:password, :password_confirmation).to_h,
    user: @user
  )

  if result.success?
    # Success path
    @user.sessions.destroy_all
    redirect_to new_session_path, notice: t("passwords.update.success")
  else
    # Failure path - validation errors
    flash.now[:alert] = format_validation_errors(result[:errors])
    render Views::Passwords::Edit.new(token: params[:token]), 
           status: :unprocessable_entity
  end
end

private

def format_validation_errors(errors)
  errors.map { |field, messages| 
    "#{field.to_s.humanize}: #{messages.join(', ')}" 
  }.join("; ")
end
```

### 4. Usage in Seeds/Scripts

```ruby
# db/seeds.rb
result = Users::Operation::Create.call(
  params: {
    email_address: "admin@papyro.local",
    password: "password123",
    password_confirmation: "password123"
  }
)

if result.success?
  puts "✅ User created: #{result[:model].email_address}"
else
  puts "❌ Failed: #{result[:errors]}"
end
```

## Testing Operations

Operations are tested independently from controllers:

```ruby
# test/concepts/users/operation/create_test.rb
test "creates user with valid params" do
  params = {
    email_address: "test@example.com",
    password: "password123",
    password_confirmation: "password123"
  }
  
  result = Users::Operation::Create.call(params: params)
  
  assert result.success?
  assert_instance_of User, result[:model]
  assert_equal "test@example.com", result[:model].email_address
end

test "fails with invalid email" do
  params = {
    email_address: "invalid-email",
    password: "password123",
    password_confirmation: "password123"
  }
  
  result = Users::Operation::Create.call(params: params)
  
  assert result.failure?
  assert_includes result[:errors][:email_address], I18n.t('errors.messages.invalid_email')
end
```

## Why This Architecture?

1. **Separation of Concerns**: Models are for persistence only, no business logic
2. **Testability**: Operations and contracts can be tested independently
3. **Reusability**: Same validation/logic can be used from controllers, jobs, console
4. **Maintainability**: All business rules in one place (contracts + operations)
5. **Type Safety**: Dry-Validation provides schema validation
6. **Railway-Oriented**: Trailblazer operations use railway pattern (success/failure tracks)

## Key Principles

- ✅ **Models**: Persistence only, NO validations, NO callbacks
- ✅ **Contracts**: ALL validations, schema definitions
- ✅ **Operations**: Business logic, orchestration, return Result monads
- ✅ **Controllers**: Thin, call operations, handle HTTP concerns only

## Further Reading

- [Dry-Validation](https://dry-rb.org/gems/dry-validation/)
- [Trailblazer Operations](https://trailblazer.to/2.1/docs/operation.html)
- [Papyro Verification Checklist](../../ai_agent/VERIFICATION_CHECKLIST.md)
