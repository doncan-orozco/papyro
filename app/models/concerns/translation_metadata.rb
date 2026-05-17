module TranslationMetadata
  extend ActiveSupport::Concern

  def approved?(loc = I18n.locale)
    # Legacy approval maps to published translation status.
    translation_for(loc)&.published? || false
  end

  def original?(loc = I18n.locale)
    loc.to_s == original_locale.to_s
  end

  def translation_published?(loc = I18n.locale)
    translation_for(loc)&.published? || false
  end

  def original_locale
    self[:original_locale].presence || I18n.default_locale.to_s
  end

  private

  def translation_for(loc)
    translations = all_translations

    if translations.respond_to?(:loaded?) && translations.loaded?
      translations.find { |translation| translation.locale == loc.to_s }
    else
      translations.find_by(locale: loc.to_s)
    end
  end

  def all_translations
    send("#{self.class.name.underscore}_translations")
  end
end
