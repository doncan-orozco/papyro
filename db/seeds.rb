# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Load environment-specific seed data
environment_seeds = Rails.root.join("db", "seeds", "#{Rails.env}.rb")

if File.exist?(environment_seeds)
  puts "Loading #{Rails.env} seeds..."
  load environment_seeds
else
  puts "No seed file found for #{Rails.env} environment"
end
