# UI vs. Domain Component Separation

## RULE 3 — Strict UI vs. Domain Component Separation

## RULE — Form Errors Must Be Visible

When a form re-renders with an invalid model (`status: :unprocessable_entity`), users must be able to see and fix field-level errors in the same surface.

- Prefer `form.field` wrappers from `PapyroFormBuilder` because they render inline `field_errors` automatically.
- If a component uses raw helpers (`file_field`, `text_field`, `text_area`, etc.), it must explicitly render `field_errors` (or equivalent model error output) for each editable field.
- If a form lives in an overlay/sheet/modal, keep that surface open on failure so errors are not hidden in closed DOM.

Failure to surface errors is a UX regression and a review blocker.

### `app/components/ui/` — Generic shadcn/Phlex Primitives

- Ports of shadcn/ui components: Card, Button, Table, Badge, Dialog, Sheet, etc.
- Must accept `**attrs` and forward all caller HTML attributes without discarding them.
- Must be **purely generic** — zero knowledge of Papyro models, named routes, or domain
  locale keys.
- No domain vocabulary (`article`, `translation`, `studio`) may appear inside a `ui/` component.

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

### ❌ Forbidden — domain logic inside a UI component

```ruby
# Inside Components::Ui::Card — NEVER add domain-specific logic
def render_article_status(article)
  span { article.published? ? t("articles.published") : t("articles.draft") }
end
```

---
