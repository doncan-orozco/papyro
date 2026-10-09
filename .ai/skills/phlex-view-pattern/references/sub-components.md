# Sub-Component Decomposition

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
