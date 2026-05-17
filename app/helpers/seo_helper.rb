module SeoHelper
  LOCALE_TO_OG = {
    en: "en_US",
    es: "es_ES"
  }.freeze

  def seo_title
    content_for(:title) || t("seo.default_title", default: t("app.title"))
  end

  def seo_description
    return @presenter.excerpt if article_show_page? && @presenter.excerpt.present?

    content_for(:description) || t("seo.default_description", default: t("app.description"))
  end

  def canonical_url
    article_show_page? ? article_url_for_locale(I18n.locale) : current_request_url
  end

  def alternate_locale_url(locale)
    return article_url_for_locale(locale) if article_show_page?

    route_name, route_params = recognized_route
    return current_request_url unless route_name.present?

    locale_pattern = I18n.available_locales.map(&:to_s).join("|")
    normalized_route_name = route_name.to_s
      .sub(/\A(?:#{locale_pattern})_/, "")
      .sub(/_(?:#{locale_pattern})\z/, "")

    localized_helper_name = "#{normalized_route_name}_#{locale}_url"
    generic_helper_name = "#{normalized_route_name}_url"

    localized_params = route_params.symbolize_keys
      .except(:locale, :format, :controller, :action)
      .merge(request.query_parameters.symbolize_keys.except(:locale))

    if respond_to?(localized_helper_name)
      return public_send(localized_helper_name, **localized_params)
    end

    return public_send(generic_helper_name, **localized_params.merge(locale: locale)) if respond_to?(generic_helper_name)

    current_request_url
  end

  def og_locale
    LOCALE_TO_OG.fetch(I18n.locale.to_sym, "en_US")
  end

  def og_locale_for(locale)
    LOCALE_TO_OG.fetch(locale.to_sym, "en_US")
  end

  def x_default_url
    "#{request.base_url}/"
  end

  private

  def article_show_page?
    controller_name == "articles" && action_name == "show" && defined?(@presenter) && @presenter.respond_to?(:original_locale)
  end

  def article_canonical_url
    article_url_for_locale(I18n.locale)
  end

  def article_url_for_locale(target_locale)
    localized_slug = @presenter.localized_slug_for(target_locale)
    article_url(localized_slug, locale: target_locale)
  end

  def current_request_url
    request.original_url.sub(%r{\?.*\z}, "")
  end

  def recognized_route
    route_name = nil
    route_params = nil

    Rails.application.routes.router.recognize(request) do |route, params|
      next if route.name.blank?

      route_name = route.name
      route_params = params
      break
    end

    [ route_name, route_params || {} ]
  end
end
