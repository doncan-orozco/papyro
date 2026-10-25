# UI vs. Domain Component Separation

## RULE 3 — Strict UI vs. Domain Component Separation

## RULE — Form Errors Must Be Visible

When a form re-renders with an invalid model (`status: :unprocessable_entity`), users must be able to see and fix field-level errors in the same surface.

- Prefer `form.field` wrappers from `PapyroFormBuilder` because they render inline `field_errors` automatically.
- If a component uses raw helpers (`file_field`, `text_field`, `text_area`, etc.), it must explicitly render `field_errors` (or equivalent model error output) for each editable field.
- If a form lives in an overlay/sheet/modal, keep that surface open on failure so errors are not hidden in closed DOM.

Failure to surface errors is a UX regression and a review blocker.

### Generic primitives: the `chadcn` gem

- Card, Button, Table, Badge, Dialog, Sheet, DropdownMenu, Pagination, etc. come from the `chadcn` gem (`Chadcn::*`); the app does not define them.
- Icons come from `Components::Shared::Icon`.
- Papyro does not add domain knowledge to gem components: wrap them in a domain or shared component instead (zero use of `article`, `translation`, `studio` vocabulary inside a primitive).
- Every Papyro component should still accept `**attrs` and forward caller HTML attributes.

### `app/views/` — Domain Page Views

- Allowed to accept ActiveRecord models, domain presenters, and Pagy objects.
- Allowed to call named route helpers and domain-specific translation keys.
- These are assembled pages, not reusable components.

### `app/components/shared/` — Cross-Domain Helpers

Small shared components (Flash, LanguageToggle, ThemeToggle) used across all domains.
No model knowledge; no route coupling.

### `app/components/studio/` — Studio-Scoped Layout Components

Layout-level components like `Navbar` that belong to a single domain but are not page
views. May reference studio-scoped routes and translations.

### ❌ Forbidden — domain logic inside a generic primitive

```ruby
# Inside a generic primitive (e.g. a Chadcn::Card wrapper) — NEVER add domain-specific logic
def render_article_status(article)
  span { article.published? ? t("articles.published") : t("articles.draft") }
end
```

---
