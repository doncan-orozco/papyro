Rails.application.config.session_store :cookie_store,
  key: "_papyro_session",
  domain: Rails.configuration.x.cookie_domain,
  tld_length: 2
