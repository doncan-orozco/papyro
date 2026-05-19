  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2,
      Rails.application.credentials.dig(:google, :client_id),
      Rails.application.credentials.dig(:google, :client_secret),
      scope: "email, profile",
      prompt: "select_account"
  end

  if Rails.env.development?
    OmniAuth.config.on_failure = proc do |env|
      strategy = env["omniauth.error.strategy"]&.name
      error = env["omniauth.error"]
      error_type = env["omniauth.error.type"]

      Rails.logger.error(
        "[OmniAuth] failure strategy=#{strategy.inspect} type=#{error_type.inspect} error=#{error&.class}: #{error&.message}"
      )

      OmniAuth::FailureEndpoint.new(env).redirect_to_failure
    end
  end
