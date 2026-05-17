---
name: phlex-view-pattern
description: >
  Golden archetype for ALL Phlex views and components in Papyro.
  ALWAYS load when creating or modifying any file in `app/views/` or `app/components/`.
  Enforces dumb views, presenter extraction for display logic, sub-component decomposition
  above 150 lines, strict UI vs. domain component separation, shared UI reuse, and safe
  Turbo Frame targeting. This is the primary source of frontend structure guidelines —
  all other view-adjacent skills defer to this one for view and component shape decisions.
  Triggers: Phlex view, Phlex component, app/views, app/components, index view,
  sub-component, presenter, domain view, UI component, page view.
---

# Golden Phlex View Archetype (Papyro)

**Load this skill FIRST for any work in `app/views/` or `app/components/`.**

All other frontend skills (design-system, frontend, turbo, frontend-design, frontend-style-ddd)
defer to this one for structural decisions about how views and components are shaped.

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

## RULE 2 — Break Down Massive Views (Sub-Components)

A Phlex view should **rarely exceed 150 lines**. When a private `render_*` helper grows
complex — for example a table row with dropdowns, badges, and modal triggers — extract it
into its own Phlex class in the same module namespace.

### Directory and namespace convention

```text
app/views/studio/articles/
  index.rb                    # Views::Studio::Articles::Index
  index/
    row.rb                    # Views::Studio::Articles::Index::Row
    tabs.rb                   # Views::Studio::Articles::Index::Tabs
    empty_state.rb            # Views::Studio::Articles::Index::EmptyState
  edit.rb                     # Views::Studio::Articles::Edit
  edit/
    editor_form_component.rb  # Views::Studio::Articles::Edit::EditorFormComponent
    settings_form_component.rb # Views::Studio::Articles::Edit::SettingsFormComponent
  shared/
    autosave_status.rb        # Views::Studio::Articles::Shared::AutosaveStatus
    slug_input.rb             # Views::Studio::Articles::Shared::SlugInput
```

### RULE 2A — Action-Based Nesting (required)

If a sub-component belongs exclusively to one page view, it MUST live in a folder
named after that view action.

- Index-only parts live in `app/views/.../index/` and use `Index::*` constants.
- Edit-only parts live in `app/views/.../edit/` and use `Edit::*` constants.
- Shared parts across multiple actions live in `app/views/.../shared/` and use
  `Shared::*` constants.

This gives clear ownership, safe deletion, and avoids a flat `junk drawer` directory.

### ❌ Forbidden — bloated single view

```ruby
class Views::Studio::Articles::Index < Views::Base
  # 300 lines — render_article_row alone is 80 lines of badges,
  # dropdown menus, and modal triggers
  def render_article_row(table, article)
    # ...
  end
end
```

### ✅ Correct — extracted sub-component

```ruby
# app/views/studio/articles/index/row.rb
class Views::Studio::Articles::Index::Row < Views::Base
  def initialize(article:)
    @article = article
  end

  def view_template
    # self-contained, focused row markup
  end
end

# In Views::Studio::Articles::Index
@articles.each do |article|
  render Row.new(article: article)
end
```

### Migration Playbook — Existing Monolith to Action-Based Layout

Use this when refactoring an already-large view (for example `show.rb` or `index.rb`) into
action-owned sub-components.

1. **Capture boundaries first**
  - List top-level regions in the current file (for example: header, filters, list/table,
    empty state, footer, modals).
  - Mark each region as `action-owned` (`index/`, `show/`, `edit/`) or `shared` (`shared/`).

2. **Extract display logic before markup moves**
  - Move fallback/title/date/status formatting into a presenter in `app/presenters/`.
  - Keep route generation and domain i18n calls in views; keep computed labels in presenter.

3. **Create target folders and constants up front**
  - Create `app/views/{domain}/{resource}/{action}/` before moving code.
  - Use constants that match folders exactly (for example `Show::Byline`, `Index::TablesSection`).

4. **Convert parent into orchestrator incrementally**
  - Extract one region at a time into a new class, then replace with `render Action::Part.new(...)`.
  - Keep each pass behavior-preserving; avoid styling rewrites during migration.

5. **Deduplicate repeated section helpers**
  - If multiple extracted parts repeat wrappers like card/section containers, move those helpers
    into a small action-local shared module (for example `index/shared/section_helpers.rb`).

6. **Run validation at each stage**
  - `get_errors` on touched files.
  - RuboCop on touched files.
  - Focused controller/system tests for the affected page.

7. **Finish with parent cleanup**
  - Remove now-unused private methods from the parent.
  - Parent should end as a composition file with minimal logic.

#### Refactor Checklist (quick)

- Parent view mostly composes sub-components.
- No complex fallback logic left in view classes.
- Action-owned components live in action folders.
- Cross-action pieces live in `shared/`.
- Turbo frame IDs and `_top` behavior unchanged.
- i18n keys unchanged or added in both `en` and `es`.
- Focused tests still pass.

---

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

## RULE 5 — Safe Turbo Frame Targeting

- Frame IDs must be **explicit and stable**; never generate IDs from random or
  session-ephemeral data.
- Use a **static container ID** for list-level swaps (e.g. `"studio_articles_list"`).
- Record-scoped IDs are acceptable when they encode a stable identifier
  (e.g. `"article_#{article.uuid}_publish_modal"`).
- Declare **empty placeholder frame tags** at the top of `view_template` so Turbo can
  find them before the rest of the page is parsed.
- Always write `_top` **explicitly** when a link or form submission must break out of a
  frame to navigate or redirect the full page.

```ruby
def view_template
  # Declare modal placeholder first so Turbo can resolve it immediately
  turbo_frame_tag("article_publish_modal") { }

  turbo_frame_tag "studio_articles_list" do
    # ... list content
  end
end

# Full-page navigation from inside a frame
render Components::Ui::Button.new(
  as: :a,
  href: new_studio_article_path,
  data: { turbo_method: :post, turbo_frame: "_top" }
) { t("studio.articles.index.new_article") }
```

For detailed frame decomposition strategies, also load
**[../turbo/SKILL.md](../turbo/SKILL.md)**.

---

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
- **[../frontend/SKILL.md](../frontend/SKILL.md)** — Stimulus controllers, compound
  component wiring, Hotwire integration; load alongside this skill, not instead of it.
- **[../frontend-design/SKILL.md](../frontend-design/SKILL.md)** — Aesthetic quality,
  typography, and visual polish.
- **[../frontend-style-ddd/SKILL.md](../frontend-style-ddd/SKILL.md)** — Domain-driven
  stylesheet placement when adding CSS beyond Tailwind utilities.
- **[../turbo/SKILL.md](../turbo/SKILL.md)** — Frame decomposition strategies; defers to
  this skill for frame ID conventions and empty placeholder rules.
- **[../i18n/SKILL.md](../i18n/SKILL.md)** — Translation key structure and file placement.
- **[../query-object-pattern/SKILL.md](../query-object-pattern/SKILL.md)** — Read-model
  patterns when a view feels like it needs to query data directly.

---

## Reference Map

- **[references/view-decomposition-example.md](references/view-decomposition-example.md)**
  Worked example: a complex index view split into sub-components with a presenter.
