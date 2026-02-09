# frozen_string_literal: true

# Development environment seeds

# Create default admin user for development
unless User.exists?(email_address: "admin@papyro.local")
  result = Users::Operation::Create.call(
    params: {
      email_address: "admin@papyro.local",
      password: "password123",
      password_confirmation: "password123"
    }
  )

  if result.success?
    puts "✅ Admin user created:"
    puts "   Email: admin@papyro.local"
    puts "   Password: password123"
  else
    puts "❌ Failed to create admin user:"
    puts "   #{result[:errors]}"
  end
end
