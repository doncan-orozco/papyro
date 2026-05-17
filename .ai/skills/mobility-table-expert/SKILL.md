---
name: mobility-table-expert
description: Professional-grade internationalization (i18n) for Rails using Mobility with a Table Backend. Provides a clean API for content translations and workflow metadata (approval status, original language flags). Use for all translatable models.
license: MIT
---

# Rails Mobility: Table Backend Expert

This skill implements a robust, relational translation strategy where every translatable model uses a dedicated `_translations` table to store localized content and workflow metadata.

## Core Principles

1.  **Single Source of Truth (No Duplicate Columns)**: Never duplicate translated columns in the parent table. All localized content must live exclusively in the `_translations` table to prevent synchronization issues and `sync_legacy_` hooks.
2.  **Relational Integrity**: Use dedicated tables instead of JSON/blobs for better indexing and data safety in SQLite. Add unique indices for `[:model_id, :locale]` and `[:locale, :slug]` to ensure data consistency.
3.  **Ownership Metadata at Parent Level**: Store `original_locale` on the parent record (e.g., `articles.original_locale`), while translation workflow state like `is_approved` stays on translation rows.
4.  **Clean API**: Access metadata via intuitive methods (e.g., `@article.approved?`) rather than querying associations manually. Use pure Mobility accessors (e.g., `article.title`), not `display_*` wrappers.
5.  **Fallbacks Configuration**: Rely on I18n fallbacks configured at the application level to handle missing translations elegantly without custom model fallbacks.

## Implementation Workflow

### 1. The Migration Pattern
Every translatable model (e.g., `Article`) requires a companion table named `[singular_model]_translations`.

```ruby
# Example: rails generate model ArticleTranslation ...
create_table :article_translations do |t|
  t.references :article, null: false, foreign_key: true
  t.string :locale, null: false
  
  # Translated Attributes
  t.string :title
  t.text :content
  
  # Workflow Metadata
  t.boolean :is_approved, default: false, null: false

  t.timestamps
end
add_index :article_translations, [:article_id, :locale], unique: true
```

### 2. The Unified Metadata Concern
Create `app/models/concerns/translation_metadata.rb` to provide a clean API across all models.

```ruby
module TranslationMetadata
  extend ActiveSupport::Concern

  def approved?(loc = I18n.locale)
    translation_for(loc)&.is_approved? || false
  end

  def original?(loc = I18n.locale)
    loc.to_s == original_locale.to_s
  end

  def original_locale
    self[:original_locale].presence || I18n.default_locale.to_s
  end

  private

  def translation_for(loc)
    all_translations.find_by(locale: loc.to_s)
  end

  def all_translations
    send("#{self.class.name.underscore}_translations")
  end
end
```

### 3. Model Implementation
```ruby
class Article < ApplicationRecord
  extend Mobility
  include TranslationMetadata

  # Uses the default :table backend configured in the initializer
  translates :title, :content
end
```

## Quality Standards

* **Explicit Originality**: When creating the first version of a record, set `original_locale` on the parent record.
* **Search Engine Safety**: In your views, use the metadata to add `noindex` tags or UI warnings if a translation is not yet `approved?`.
* **Performance**: Always ensure the `[model_id, locale]` index exists to keep SQLite lookups O(1).

## Global Configuration
Ensure `config/initializers/mobility.rb` is set to:
```ruby
Mobility.configure do |config|
  config.default_backend = :table
  config.accessor_method = :translates
  config.query_method    = :i18n
end
```
