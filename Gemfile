source "https://rubygems.org"

# Load environment variables from .env
gem "dotenv", groups: [ :development, :test ], require: "dotenv/load"

# Framework & Core
gem "rails", "~> 8.1.2"
gem "sqlite3", ">= 2.1"
gem "puma", ">= 5.0"
gem "jbuilder"
gem "rack-cors"

# Rails 8 Solid Suite
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Frontend & Hotwire
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# UI (Phlex + Tailwind)
gem "phlex"
gem "phlex-rails"
gem "tailwindcss-rails"
gem "tailwind_merge"
gem "lucide-rails" # Server-rendered SVGs

# Papyro Core Engines
gem "papyro_studio", git: "https://github.com/doncan-orozco/papyro_studio.git", branch: "main"

# Models, Auth & I18n
gem "bcrypt", "~> 3.1.22"
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"
gem "friendly_id", "< 5.6"
gem "mobility", "~> 1.3"
gem "friendly_id-mobility", "~> 1.0"

# Business Logic (dry-rb & Utilities)
gem "dry-monads"
gem "dry-validation"
gem "dry-operation"
gem "pagy"
gem "pundit"
gem "route_translator"
gem "sitemap_generator"

# Active Storage & Processing
gem "image_processing", "~> 1.2"

# Markdown rendering with syntax highlighting
gem "redcarpet"
gem "rouge"

# Jobs & Server
gem "mission_control-jobs"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Security & Migrations
  gem "bundler-audit", require: false
  gem "brakeman", "~> 8.0.4", require: false
  gem "strong_migrations"

  # Linting
  gem "rubocop-rails-omakase", require: false
  gem "mcp", ">= 0.9.2", require: false
  gem "rubocop", ">= 1.41", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-minitest", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-capybara", require: false

  # N+1 detection
  gem "bullet"
end

group :development do
  gem "web-console"
  gem "awesome_print"
  gem "ruby-lsp", ">= 0.26.9"
  gem "database_consistency"
end

group :test do
  gem "simplecov", require: false
  gem "capybara"
  gem "cuprite", require: false
end
