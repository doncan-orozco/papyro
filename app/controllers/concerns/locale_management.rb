module LocaleManagement
  extend ActiveSupport::Concern

  included do
    prepend_before_action :set_locale
  end

  private

  def set_locale
    locale = requested_locale || x_default_root_locale || stored_locale || browser_locale || I18n.default_locale
    I18n.locale = locale
    Current.locale = locale
  end

  def default_url_options
    { locale: I18n.locale }
  end

  def requested_locale
    locale = normalized_locale(params[:locale])
    session[:locale] = locale if locale
    locale
  end

  # Keep the unlocalized homepage (/) deterministic for crawlers.
  # We treat it as x-default and always render in default locale when
  # no explicit locale param is provided.
  def x_default_root_locale
    return unless request.path == "/" && params[:locale].blank?

    I18n.default_locale
  end

  def stored_locale
    normalized_locale(session[:locale])
  end

  def browser_locale
    request
      .get_header("HTTP_ACCEPT_LANGUAGE")
      .to_s
      .split(",")
      .filter_map do |entry|
        normalized_locale(entry.split(";").first.to_s.strip.split("-").first)
      end
      .first
  end

  def normalized_locale(value)
    locale = value.to_s.presence&.to_sym
    return unless locale && I18n.available_locales.include?(locale)

    locale
  end
end
