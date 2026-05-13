module Studio
  module ContentLocaleHandling
    extend ActiveSupport::Concern

    included do
      helper_method :studio_content_locale_query
    end

    private

    def studio_content_locale(default: nil)
      normalized_locale(params[:content_locale]) ||
        normalized_locale(params[:locale]) ||
        normalized_locale(default) ||
        I18n.default_locale
    end

    def studio_content_locale_param(default: nil)
      studio_content_locale(default: default).to_s
    end

    def studio_content_locale_query(default: nil)
      locale = studio_content_locale_param(default: default)
      baseline = default.to_s.presence || I18n.default_locale.to_s
      return {} if locale == baseline

      { content_locale: locale }
    end
  end
end
