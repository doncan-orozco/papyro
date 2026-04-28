---
name: mobility-table-expert
description: Professional-grade internationalization (i18n) for Rails using Mobility with a Table Backend. Provides a clean API for content translations and workflow metadata (approval status, original language flags). Use for all translatable models.
license: MIT
---

# Rails Mobility: Table Backend Expert

This skill implements a robust, relational translation strategy where every translatable model uses a dedicated `_translations` table to store localized content and workflow metadata.

## Core Principles

1.  **Relational Integrity**: Use dedicated tables instead of JSON/blobs for better indexing and data safety in SQLite.
2.  **Metadata Co-location**: Store `is_approved` and `is_original` flags directly on the translation record.
3.  **Clean API**: Access metadata via intuitive methods (e.g., `@article.approved?`) rather than querying associations manually.

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
  t.boolean :is_original, default: false, null: false
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
    translation_for(loc)&.is_original? || false
  end

  def original_locale
    all_translations.find_by(is_original: true)&.locale
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

* **Explicit Originality**: When creating the first version of a record, the corresponding translation row **must** have `is_original: true`.
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
