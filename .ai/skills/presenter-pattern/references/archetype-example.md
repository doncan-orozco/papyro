# Presenter Archetype Example

## Golden Presenter Archetype

### File Naming & Location

```
app/concepts/
  articles/
    presenter/
      default.rb                   # ← Reusable article display behavior
      show.rb                      # ← Show-page composition only
  studio/
    presenter/
      default.rb                   # ← Studio article display logic
  admin/
    presenter/
      default.rb                   # ← Admin article display logic
```

**Naming convention:** short intent names in `Domain::Presenter::*` (not presenter-suffixed class names).

Why? Because the same logic is useful anywhere that domain is displayed. Tie the presenter to the **domain**, not the **view** or **controller**.

### Presenter Structure (Complete Example)

```ruby
# app/concepts/articles/presenter/default.rb
# frozen_string_literal: true

module Articles
  module Presenter
    class Default < SimpleDelegator
    # 1. The Collection Wrapper Helper (optional, but recommended)
    def self.wrap(collection, locale: I18n.locale)
      collection.map { |item| new(item, locale: locale) }
    end

    # 2. Initialization with context
    attr_reader :locale

    def initialize(article, locale: I18n.locale)
      super(article)                    # Delegate to article via SimpleDelegator
      @locale = locale.to_s
    end

    # 3. Display methods (view-agnostic logic)
    
    # Example: Locale-aware title selection
    # Locale fallback must compare against original_locale, not hardcoded "en"
    def translation_fallback?
      locale.to_s != original_locale.to_s && !translation_published?(locale)
    end

    # Example: Status badge variant logic (NO CSS, just logic)
    def status_variant
      return :destructive if trashed?
      case status
      when "draft" then :secondary
      when "published" then :default
      when "archived" then :outline
      else :secondary
      end
    end

    def status_label
      trashed? ? I18n.t("statuses.trashed") : I18n.t("statuses.#{status}")
    end

    # Example: Formatted timestamp
    def published_at_label
      if trashed?
        I18n.t("articles.deleted_at", time: I18n.l(deleted_at, format: :short))
      elsif published_at
        I18n.l(published_at, format: :short)
      else
        I18n.t("articles.not_published")
      end
    end

    # Example: Sorted collection for views
    def sorted_translations
      baseline = original_locale.to_s
      article_translations.sort_by do |translation|
        [ translation.locale.to_s == baseline ? 0 : 1, translation.locale.to_s ]
      end
    end

    # Example: Logic check (view receives the result, not the logic)
    def locale_published?(translation)
      if translation.locale.to_s == original_locale.to_s
        published?
      else
        translation.published?
      end
    end

    # 4. Private helpers (delegate to internal state)
    private

    def content_analysis
      @content_analysis ||= ::Articles::Service::ContentAnalysis.new(__getobj__)
    end
  end
  end
end
```

---
