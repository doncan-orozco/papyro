#!/usr/bin/env ruby
# Demo script showing Dry-Validation contracts integrated with Trailblazer Operations
# Run with: bin/rails runner demo/validation_demo.rb

puts "=" * 80
puts "Papyro: Dry-Validation Contracts + Trailblazer Operations Demo"
puts "=" * 80
puts

# Test 1: Invalid Email
puts "📧 Test 1: Invalid Email Format"
puts "-" * 80
result = Users::Operation::Create.call(
  params: {
    email_address: "not-an-email",
    password: "password123",
    password_confirmation: "password123"
  }
)
puts "Result: #{result.success? ? '✅ SUCCESS' : '❌ FAILURE'}"
puts "Errors: #{result[:errors]}" if result.failure?
puts

# Test 2: Password Mismatch
puts "🔐 Test 2: Password Mismatch"
puts "-" * 80
result = Users::Operation::Create.call(
  params: {
    email_address: "valid@example.com",
    password: "password123",
    password_confirmation: "different456"
  }
)
puts "Result: #{result.success? ? '✅ SUCCESS' : '❌ FAILURE'}"
puts "Errors: #{result[:errors]}" if result.failure?
puts

# Test 3: Missing Required Fields
puts "📝 Test 3: Missing Required Fields"
puts "-" * 80
result = Users::Operation::Create.call(
  params: {
    email_address: "",
    password: "",
    password_confirmation: ""
  }
)
puts "Result: #{result.success? ? '✅ SUCCESS' : '❌ FAILURE'}"
puts "Errors: #{result[:errors]}" if result.failure?
puts

# Test 4: Valid User Creation
puts "✨ Test 4: Valid User Creation"
puts "-" * 80
# Clean up any existing test user
User.where(email_address: "demo@papyro.test").destroy_all

result = Users::Operation::Create.call(
  params: {
    email_address: "demo@papyro.test",
    password: "SecurePass123",
    password_confirmation: "SecurePass123"
  }
)
puts "Result: #{result.success? ? '✅ SUCCESS' : '❌ FAILURE'}"
if result.success?
  user = result[:model]
  puts "User created!"
  puts "  - ID: #{user.id}"
  puts "  - Email: #{user.email_address}"
  puts "  - Created at: #{user.created_at}"
end
puts

# Test 5: Duplicate Email
puts "🔄 Test 5: Duplicate Email"
puts "-" * 80
result = Users::Operation::Create.call(
  params: {
    email_address: "demo@papyro.test",
    password: "AnotherPass456",
    password_confirmation: "AnotherPass456"
  }
)
puts "Result: #{result.success? ? '✅ SUCCESS' : '❌ FAILURE'}"
puts "Errors: #{result[:errors]}" if result.failure?
puts

# Test 6: Update Operation
puts "🔄 Test 6: Update User Password"
puts "-" * 80
user = User.find_by(email_address: "demo@papyro.test")
if user
  result = Users::Operation::Update.call(
    params: {
      password: "NewSecurePass789",
      password_confirmation: "NewSecurePass789"
    },
    user: user
  )
  puts "Result: #{result.success? ? '✅ SUCCESS' : '❌ FAILURE'}"
  if result.success?
    puts "Password updated successfully!"
    puts "Can authenticate with new password: #{user.authenticate('NewSecurePass789') ? 'YES ✅' : 'NO ❌'}"
  end
end
puts

# Cleanup
User.where(email_address: "demo@papyro.test").destroy_all

puts "=" * 80
puts "Demo Complete!"
puts "=" * 80
puts
puts "Key Takeaways:"
puts "✅ Validations are defined in Dry-Validation Contracts"
puts "✅ Operations orchestrate validation + persistence"
puts "✅ Model has NO validations (pure persistence)"
puts "✅ Same operations work from controllers, jobs, console, scripts"
puts "✅ Result monad pattern: check .success? or .failure?"
puts "✅ Errors accessible via result[:errors]"
puts
