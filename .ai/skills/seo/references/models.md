# Model Translation Strategy

## Mobility Setup
Use the `container` (JSONB) backend for PostgreSQL to maintain performance.

## Slug Resolution
By using `friendly_id-mobility`, you avoid custom `resolve_friendly_id` methods. The gem automatically scopes the slug lookup to the current `I18n.locale`.

## Migration Pattern (JSONB)
```ruby
add_column :articles, :translations, :jsonb, default: {}, null: false
add_index :articles, :translations,憑sing: :gin
```