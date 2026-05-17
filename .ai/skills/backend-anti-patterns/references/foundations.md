# Backend Anti-Patterns: Foundations

## Scope

Use this reference for cross-cutting backend mistakes that do not belong to a single layer.

## Comment Quality

Prefer comments that explain why a choice exists, what constraint it protects, or what future change is expected.

Avoid:
- section-label comments like `# Associations` or `# Instance methods`
- comments that restate obvious Ruby or Rails behavior
- comments that cite checklist sections instead of explaining the decision locally

Good comment targets:
- business constraints that are not obvious from the code
- SQLite or framework limitations that shaped the implementation
- temporary decisions with a clear future migration path

```ruby
# GOOD
# SQLite does not support case-insensitive unique indexes reliably here,
# so email is normalized before persistence to preserve uniqueness.
normalizes :email_address, with: ->(value) { value.to_s.strip.downcase }
```

## ApplicationController Composition

Keep `ApplicationController` composition-only.

Avoid:
- feature-specific locale logic implemented directly in `ApplicationController`
- auth, locale, or browser policy logic mixed with feature behavior

Prefer:
- cross-cutting concerns extracted to `app/controllers/concerns/*.rb`
- `ApplicationController` including concerns and exposing shared helpers only

```ruby
module LocaleManagement
  extend ActiveSupport::Concern

  included do
    prepend_before_action :set_locale
  end
end

class ApplicationController < ActionController::Base
  include Authentication
  include LocaleManagement
end
```

## Shared dry-schema Messages

Keep generic predicate messages under `dry_schema.errors.*` and reserve domain wording for contract rule failures.

Avoid:
- domain-specific copy in `dry_schema.errors.rules.<field>`
- field-name based rule messages that collide across contracts using the same attribute names

Prefer:
- generic shared messages in `config/locales/*/errors.yml`
- explicit `key.failure(I18n.t("domain.forms.validation.key"))` inside `rule(...)`

```yaml
en:
  dry_schema:
    errors:
      filled?: "cannot be blank"
      max_size?: "is too long (maximum is %{num} characters)"
```

```ruby
rule(:title) do
  key.failure(I18n.t("articles.forms.validation.title_too_long")) if value && value.length > 255
end
```

## Identifier Consistency

Choose one canonical identifier per route boundary.

Avoid:
- controller finders that accept `id || slug`
- route declarations using `param: :slug` while controllers still read `params[:id]`

Prefer:
- one canonical public identifier per bounded context
- controller finders that read the exact route param name

```ruby
resources :articles, param: :slug

# GOOD
policy_scope(Article).find_by!(slug: params[:slug])
```
