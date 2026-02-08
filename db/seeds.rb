# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create default admin user for development
if Rails.env.development?
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
end
