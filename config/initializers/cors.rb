# frozen_string_literal: true

configured_origins = ENV.fetch("CORS_ALLOWED_ORIGINS", "")
  .split(",")
  .map(&:strip)
  .reject(&:empty?)

default_origins = [
  "https://studio.papyro.net",
  "https://studio.qa.papyro.net",
  "http://studio.lvh.me:3030",
  "http://localhost:3000",
  "http://localhost:3030"
]

allowed_origins = (configured_origins.presence || default_origins).freeze

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "/uploads",
      headers: :any,
      methods: [ :post, :options ],
      credentials: true,
      max_age: 600
  end
end
