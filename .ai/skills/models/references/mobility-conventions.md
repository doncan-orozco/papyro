# Mobility Conventions on Models

## Multi-Language / Mobility Conventions

If the model is translated using the `Mobility` gem, follow these rules:

### 1. No Translation Columns on Parent
**Do not store translated fields (title, excerpt) on the parent table.** They belong exclusively in the `_translations` table.

```ruby
# FORBIDDEN — Never do this
create_table :articles do |t|
  t.string :title          # ← NO! Title should be in article_translations
  t.string :slug           # ← NO! Slug should be in article_translations
  t.references :user
  t.timestamps
end

# CORRECT — Only locale-agnostic fields on parent
create_table :articles do |t|
  t.string :uuid, null: false
  t.references :user, null: false
  t.datetime :published_at
  t.datetime :archived_at
  t.datetime :deleted_at
  t.string :original_locale, null: false
  t.timestamps
end

create_table :article_translations do |t|
  t.references :article, null: false
  t.string :locale, null: false
  t.string :title, null: false
  t.string :slug, null: false
  t.string :excerpt
  t.string :cover_image_caption
  t.text :body_content
  t.string :status, null: false
  t.datetime :published_at
  t.timestamps
end
```

### 2. Store Original Locale
**Always store `original_locale` as a string on the parent table.** This allows for SEO fallbacks without querying the translation table on every request.

```ruby
class Article < ApplicationRecord
  validates :original_locale, presence: true, inclusion: { 
    in: ->(_record) { I18n.available_locales.map(&:to_s) } 
  }
  
  def original_translation_published?
    translation = if association(:article_translations).loaded?
      article_translations.find { |t| t.locale == original_locale }
    else
      article_translations.find_by(locale: original_locale)
    end
    translation&.published? || false
  end
end
```

### 3. No Display Helpers
**Do not write wrapper methods like `display_title`.** Use Mobility's native overriding: calling `model.title` automatically handles locale routing and fallbacks.

```ruby
# FORBIDDEN — Redundant and confusing
def display_title
  I18n.with_locale(current_locale) { title }
end

# CORRECT — Mobility handles it
article.title  # Automatically uses current I18n.locale and falls back per Mobility config
```

---
