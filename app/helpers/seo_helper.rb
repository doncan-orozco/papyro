module SeoHelper
  LOCALE_TO_OG = {
    en: "en_US",
    es: "es_ES"
  }.freeze

  def seo_title
    content_for(:title) || t("seo.default_title", default: t("app.title"))
  end

  def seo_description
    content_for(:description) || t("seo.default_description", default: t("app.description"))
  end

  def canonical_url
    return x_default_url if x_default_home_request?
    return localized_home_url(I18n.locale) if home_index_request?

    alternate_locale_url(I18n.locale)
  end

  def alternate_locale_url(locale)
    return localized_home_url(locale) if home_index_request?

    localized_current_route_url(locale)
  rescue ActionController::UrlGenerationError
    root_url(locale: locale)
  end

  def og_locale
    og_locale_for(I18n.locale)
  end

  def x_default_url
    "#{request.base_url}/"
  end

  def localized_home_url(locale)
    root_url(locale: locale)
  end

  def localized_current_route_url(locale)
    route_name = nil
    route_params = nil

    Rails.application.routes.router.recognize(request) do |route, params|
      next if route.name.blank?

      route_name = route.name
      route_params = params
      break
    end

    raise ActionController::UrlGenerationError, "Unnamed route" if route_name.blank?

    locale_pattern = I18n.available_locales.map(&:to_s).join("|")
    normalized_route_name = route_name.to_s
      .sub(/\A(?:#{locale_pattern})_/, "")
      .sub(/_(?:#{locale_pattern})\z/, "")

    helper_name = "#{normalized_route_name}_url"
    raise ActionController::UrlGenerationError, "Missing helper: #{helper_name}" unless respond_to?(helper_name)

    localized_helper_name = "#{normalized_route_name}_#{locale}_url"

    localized_params = route_params.symbolize_keys
      .except(:locale, :format, :controller, :action)
      .merge(request.query_parameters.symbolize_keys.except(:locale))

    if respond_to?(localized_helper_name)
      return public_send(localized_helper_name, **localized_params)
    end

    localized_params = localized_params.merge(locale: locale)

    I18n.with_locale(locale) do
      public_send(helper_name, **localized_params)
    end
  end

  def home_index_request?
    controller_name == "home" && action_name == "index"
  end

  def x_default_home_request?
    home_index_request? && params[:locale].blank?
  end

  def og_locale_for(locale)
    LOCALE_TO_OG.fetch(locale.to_sym, "en_US")
  end
end
