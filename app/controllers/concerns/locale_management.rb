module LocaleManagement
  extend ActiveSupport::Concern

  included do
    prepend_before_action :set_locale
  end

  private

  def set_locale
    locale = requested_locale || stored_locale || browser_locale || I18n.default_locale
    cookies.permanent[:papyro_locale] = locale if cookies[:papyro_locale] != locale.to_s
    I18n.locale = locale
    Current.locale = locale
  end

  def requested_locale
    locale = normalized_locale(params[:locale])
    session[:locale] = locale if locale
    locale
  end

  def stored_locale
    normalized_locale(cookies[:papyro_locale])
  end

  def browser_locale
    request.env['HTTP_ACCEPT_LANGUAGE']&.scan(/^[a-z]{2}/)&.first&.to_sym
  end

  def normalized_locale(value)
    locale = value.to_s.presence&.to_sym
    I18n.available_locales.include?(locale) ? locale : nil
  end
end
