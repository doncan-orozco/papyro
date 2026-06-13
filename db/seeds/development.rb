# frozen_string_literal: true

puts "🌱 Loading Papyro development seeds..."

# Create default admin user for development
unless User.exists?(email_address: "admin@papyro.local")
  result = Users::Operation::Create.new.call(
    params: {
      email_address: "admin@papyro.local",
      password: "password123",
      password_confirmation: "password123",
      profile_attributes: {
        display_name: "Admin",
        username: "papyro_admin"
      }
    }
  )

  if result.success?
    user = result.value![:model]

    # Enrich admin profile
    user.profile.update!(
      bio: "Platform administrator and curator. I tend the garden — making sure Papyro remains a calm, beautiful space for ideas worth reading.",
      location: "Papyro HQ"
    )

    # Verify email so admin can sign in immediately
    user.update!(verified_at: Time.current)

    puts "✅ Admin user created:"
    puts "   Email: admin@papyro.local"
    puts "   Password: password123"

  else
    errors = result.failure[:errors] rescue result.failure
    puts "❌ Failed to create admin user:"
    puts "   #{errors}"
  end
end

# Load sub-modules in dependency order
load Rails.root.join("db/seeds/development/authors.rb")
load Rails.root.join("db/seeds/development/articles.rb")

puts ""
puts "✅ Seeds complete!"
puts "   Authors:  #{AuthorProfile.count}"
puts "   Articles: #{Article.count} (#{Article.where.not(published_at: nil).count} published)"
puts ""
puts "   Sign in with any author email (password: password123):"
AuthorProfile.includes(:user).each do |profile|
  puts "     #{profile.display_name} — #{profile.user.email_address}"
end
