class RootRouterController < ApplicationController
  allow_unauthenticated_access

  def route
    skip_authorization
    locale = detect_locale
    redirect_to root_path(locale: locale), status: :found
  end

  private

  def detect_locale
    cookies[:papyro_locale] || extract_locale_from_accept_language_header || I18n.default_locale
  end

  def extract_locale_from_accept_language_header
    request.env["HTTP_ACCEPT_LANGUAGE"]&.scan(/[a-z]{2}/)&.find { |lang| I18n.available_locales.map(&:to_s).include?(lang) }
  end
end
