---
name: phlex-view-pattern
description: "Golden archetype for Phlex views, components, Hotwire and styling. ALWAYS load when creating or editing files in `app/views/`, `app/components/`, or `app/assets/stylesheets/` (host and the papyro_studio engine): dumb views, presenter extraction, sub-component decomposition, UI vs domain components, Turbo Frames/Streams targeting, domain-driven CSS organization. Stimulus controllers have their own `stimulus` skill."
---

# Golden Phlex View Archetype (Papyro)

## Quick Rules

Cite as `phlex-view-pattern R<n>`. Detail and examples follow below / in references/.

R1. **Dumb views.** Display logic (fallbacks, sorting, composed strings) lives in a presenter built by the controller; views never instantiate presenters. → detail: RULE 1
R2. **Decompose big views.** Extract sub-components when helpers exceed ~50 lines; one-page-only parts live in an action folder (`index/`, `edit/`, `shared/`) with `Index::*`/`Edit::*`/`Shared::*` constants. → detail: references/sub-components.md
R3. **UI vs domain.** `app/components/ui/` holds generic primitives only (no Papyro models, routes or domain locale keys, forwards `**attrs`); domain markup goes in views or domain components. → detail: references/ui-vs-domain-components.md
R4. **Reuse shared patterns.** Use `Components::Ui::Pagination` and existing components; never inline pagination or re-implement common patterns. → detail: RULE 4
R5. **Safe Turbo frame targeting.** Frame ids are explicit and stable (never random/session data), empty placeholder frames sit at the top of `view_template`, and `_top` is written explicitly to break out. → detail: references/turbo-frame-targeting.md
R6. **Explicit data flow.** Views use only constructor arguments; no `Current.*`, `request`, `params`, `session` or request-bound helpers inside views. → detail: RULE 6
R7. **Form errors visible.** Forms prefer `form.field`; raw inputs must render `field_errors` explicitly; overlay forms stay open on failure. → detail: references/ui-vs-domain-components.md
R8. **Base classes and keys.** Views inherit `Views::Base`, components `Components::Base`; snake_case files; i18n keys fully-qualified (never `t(".key")`), added in both `en` and `es`. → detail: File Conventions
R9. **Semantic tokens only.** Use design-system tokens in Tailwind classes; no hardcoded palette classes. → detail: File Conventions
R10. **Compound helpers.** Multi-part components are called through parent helpers (`card.header`), never child `.new`; Stimulus defaults live in component helpers, not repeated in views. → detail: references/frontend-overview.md
R11. **Stimulus naming.** Controllers mirror view ownership in their path (`studio/articles/autosave_controller.js`) and use the matching identifier (`studio--articles--autosave`) in `data-controller`/`data-action`. → detail: references/frontend-overview.md
R12. **Overlay stacking.** Never place Sheet/Dialog `content` inside a stacking-context container (`sticky`/`relative`+z-index, transform, filter, will-change); overlays use fixed positioning, no animating `top`/`left`. → detail: references/frontend-overview.md
R13. **Links use route helpers.** Never write a raw `a(href: ...)`/`<a>` or a hand-built path string (`"/articles/#{slug}"`); use `link_to` with a route helper or presenter path so route_translator localizes the URL. → detail: references/frontend-overview.md
R14. **Domain-based frames.** Frame decomposition follows domain concepts (`featured_articles`), not atomic UI pieces (`card_section`, `button_group`). → detail: references/turbo-frames.md
R15. **Stylesheet placement.** No domain CSS in `app/assets/tailwind/application.css` (import manifest only); use `domains/`, `components/`, `foundation/`, `utilities/`, imported explicitly; no mixed-domain files or global domain selectors. → detail: references/stylesheet-organization.md
R16. **Split divergent form intents.** Editor vs settings (or other divergent interactions) are separate components, not one mode-switched form. → detail: references/ui-vs-domain-components.md
R17. **house-md toolbar styling.** The house-md toolbar is styled via `house.css`, not Tailwind utilities. → detail: references/frontend-overview.md


**Load this skill FIRST for any work in `app/views/` or `app/components/`.**

Frontend references (frontend overview, Turbo frames, stylesheets) live in `references/`; `design-system`
defers to this one for structural decisions about how views and components are shaped.

---

## What Views Are For

Phlex views are strictly for **emitting HTML and assembling UI components**. They map
structured data to visual elements using Tailwind CSS classes and Papyro's component library.

Views are **NOT** for:

| Concern | Correct Layer |
|---|---|
| Database queries or N+1 lookups | Query Objects → passed in by controller |
| Complex display logic, fallback chains, format transforms | Presenters (`app/presenters/`) |
| Direct record mutation | Operations (`app/concepts/*/operation/`) |
| Business validation | Contracts / Operations |

---

## RULE 1 — Extract Display Logic to Presenters

If a view needs to calculate fallbacks, sort arrays, or compose multi-field strings,
that logic belongs in `app/presenters/{domain}_presenter.rb`.

Presenters are **plain Ruby objects** — not ActiveRecord models, not helpers, not concerns.
They accept a model (or multiple) in their initializer and expose clean reader methods.

### ❌ Forbidden — display logic inside a view

```ruby
# Inside a Phlex view
def display_title(article)
  if article.title.present?
    article.title
  elsif article.original_title.present?
    article.original_title
  else
    t("studio.articles.untitled")
  end
end
```

### ✅ Correct — logic in a presenter, view stays dumb

```ruby
# app/presenters/article_presenter.rb
class ArticlePresenter
  def initialize(article)
    @article = article
  end

  def display_title
    @article.title.presence ||
      @article.original_title.presence ||
      I18n.t("studio.articles.untitled")
  end

  def status_badge_variant
    @article.published? ? :default : :secondary
  end
end

# In the Phlex view
span { @presenter.display_title }
render Components::Ui::Badge.new(variant: @presenter.status_badge_variant) { ... }
```

**Data flow rule:** Controllers initialize the presenter and pass it to the view as an
instance variable (`@presenter = ArticlePresenter.new(article)`). Views never instantiate
presenters themselves.

---

> **Sub-Component Decomposition:** directory convention, action-based nesting, migration playbook → [references/sub-components.md](references/sub-components.md)

## RULE 3 — Strict UI vs. Domain Component Separation

`app/components/ui/` = generic shadcn/Phlex primitives (no domain logic); `app/views/` = domain pages; `app/components/shared/` = cross-domain helpers; `app/components/studio/` = Studio layout. Never put domain logic in a UI component. Form errors must always be visible. Details and examples: [references/ui-vs-domain-components.md](references/ui-vs-domain-components.md).

## RULE 4 — Reuse Shared UI Patterns (No Reinvention)

Do not reimplement pagination, empty-state layouts, or other common patterns in each view.
Reach for the existing component; extract a shared view class if a pattern repeats.

### Pagination

Always use `Components::Ui::Pagination`. Never inline pagination markup.

```ruby
render Components::Ui::Pagination.new do |pagination|
  pagination.content do
    pagination.item do
      pagination.previous(
        href: (@pagy.previous ? path(page: @pagy.previous) : nil),
        data: { turbo_frame: "studio_articles_list" }
      ) { t("design_system.pagination.previous") }
    end
    # ... pages
  end
end
```

---

> **Safe Turbo Frame Targeting:** frame ids, full-page navigation from inside frames → [references/turbo-frame-targeting.md](references/turbo-frame-targeting.md)

## RULE 6 — Explicit Data Flow (No Ambient State in Views)

Views receive **only** what is passed via `initialize`. They must not reach into:

- `Current.user` / `Current.locale`
- `request`, `params`, or `session`
- ActionView helpers that access HTTP request context

If a view needs the current user or locale, the controller passes them explicitly as
constructor arguments.

---

## File Conventions

| Convention | Detail |
|---|---|
| Base class (views) | `Views::Base` |
| Base class (components) | `Components::Base` |
| Sub-component location | Same directory as the parent view |
| File naming | `snake_case.rb` |
| Class naming | `CamelCase` inside correct module namespace |
| i18n keys | Fully-qualified only; never `t(".key")` relative shortcuts |
| Tailwind classes | Semantic design-system tokens only; no hardcoded palette classes |

---

## Workflow

1. Decide the **layer**: page view (`app/views/`), domain component
   (`app/components/{domain}/`), or UI primitive (`app/components/ui/`).
2. If the view needs formatted or derived data → create or extend a **Presenter** first.
3. Implement `view_template`. If private helpers grow beyond ~50 lines, extract
   sub-components.
4. Apply Tailwind via semantic design-system tokens.
5. Add fully-qualified i18n keys in **both** `en` and `es` locale files.
6. Verify Turbo Frame IDs are stable; use `_top` for full-page transitions.
7. Load companion skills for adjacent concerns (see below).

---

## Companion Skills

This skill owns **view and component shape**. Load these for adjacent concerns:

- **[../design-system/SKILL.md](../design-system/SKILL.md)** — UI primitive construction
  in `app/components/ui/`; defers to this skill for how views compose UI components.
- **[references/frontend-overview.md](references/frontend-overview.md)** — Stimulus controllers, compound
  component wiring, Hotwire integration; load alongside this skill, not instead of it.
- **[references/stylesheet-organization.md](references/stylesheet-organization.md)** — Domain-driven
  stylesheet placement when adding CSS beyond Tailwind utilities.
- **[references/turbo-frames.md](references/turbo-frames.md)** — Frame decomposition strategies; defers to
  this skill for frame ID conventions and empty placeholder rules.
- **[../i18n/SKILL.md](../i18n/SKILL.md)** — Translation key structure and file placement.
- **[../query-object-pattern/SKILL.md](../query-object-pattern/SKILL.md)** — Read-model
  patterns when a view feels like it needs to query data directly.

---

## Reference Map

- **[references/view-decomposition-example.md](references/view-decomposition-example.md)**
  Worked example: a complex index view split into sub-components with a presenter.
