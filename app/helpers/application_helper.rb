module ApplicationHelper
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
    alternate_locale_url(I18n.locale)
  end

  def alternate_locale_url(locale)
    params = request.path_parameters.symbolize_keys.except(:locale, :format)
      .merge(request.query_parameters.symbolize_keys.except(:locale))
      .merge(locale: locale, only_path: false)

    url_for(params)
  rescue ActionController::UrlGenerationError
    root_url(locale: locale)
  end

  def og_locale
    og_locale_for(I18n.locale)
  end

  def og_locale_for(locale)
    LOCALE_TO_OG.fetch(locale.to_sym, "en_US")
  end
end
