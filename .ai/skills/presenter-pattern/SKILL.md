---
name: presenter-pattern
description: "Golden archetype for presenters (SimpleDelegator, `Core::Presenter::Base`). Use when creating or editing files in `app/concepts/*/presenter/`, wrapping models or collections for display, or moving display logic out of views and controllers."
---

# Golden Presenter Pattern (Papyro)

## Quick Rules

Cite as `presenter-pattern R<n>`. Detail and examples follow below / in references/.

R1. **Inherit the base.** Every presenter inherits `Core::Presenter::Base`; `ApplicationPresenter` does not exist and must not be referenced. → detail: Presenter Base Class (Critical)
R2. **Route helpers via `helpers`.** Use `helpers.<path>`; never `include Rails.application.routes.url_helpers` or global route helpers in a presenter. → detail: Presenter Base Class (Critical)
R3. **No stuttering names.** Name classes `Default`/`Show`/`Index` inside `Domain::Presenter`; `ArticlePresenter`, `ShowPresenter`, `*_presenter.rb` are forbidden. → detail: Naming Contract (No Stuttering)
R4. **Files mirror names.** Path mirrors the class (`app/concepts/articles/presenter/show.rb` -> `Articles::Presenter::Show`), Zeitwerk-aligned, no legacy duplicates left. → detail: Presenter Migration Safety Checklist
R5. **Delegate, don't duplicate.** Use SimpleDelegator delegation; do not hand-write pass-through methods for the wrapped model. → detail: The SimpleDelegator Pattern
R6. **Return data, not markup.** No CSS classes or conditional HTML strings in presenters; return booleans, strings, counts and let the view style. → detail: Key Rules / DO NOT
R7. **Read-only.** Presenters never mutate the wrapped model or hold business logic (validation, transitions, permissions); that belongs in models/operations. → detail: Key Rules / DO NOT
R8. **No nesting, no per-view presenters.** Wrap related models with their own presenter; reuse one presenter across views instead of one per view. → detail: Key Rules / DO NOT
R9. **Context is injected.** Pass `ui_locale`, `viewer_id` etc. via the initializer; never read `Current.user` inside a presenter. → detail: Key Rules / DO NOT
R10. **Expose `.wrap` for collections.** Collection presenters provide `.wrap` so controllers wrap lists trivially. → detail: references/collection-wrapping.md
R11. **Split base vs page presenters.** Generic display in `Default`, page-only composition in `Show`; avoid a god presenter (200+ lines). → detail: Session-Proven Pattern (May 2026)
R12. **No hardcoded language.** Never compare locale to a literal like `"en"`; compare against `original_locale`. → detail: Key Rules / DO NOT
R13. **Keep public API on rename.** Preserve public methods used by views/components, or update views and tests in the same patch. → detail: Presenter Migration Safety Checklist
R14. **Preload what you read.** If a presenter reads associations, the feeding query must preload them (no N+1). → detail: Query Guardrail
R15. **No pointless presenters.** Do not add a presenter that merely renames one method or serves a one-off transformation. → detail: When to Use Presenters


## Presenter Base Class (Critical)

**All presenters MUST inherit from `Core::Presenter::Base`.**

- Do NOT use `ApplicationPresenter` (does not exist in Papyro)
- `Core::Presenter::Base` provides:
  - `SimpleDelegator` wrapping
  - Shared presenter logic
  - A `helpers` method for Rails route helpers

**Example:**

```ruby
class Studio::Articles::Presenter::Editor < ::Core::Presenter::Base
  # ...
end
```

**Accessing route helpers:**

Use `helpers` (from the base class) for all path/url helpers:

```ruby
def form_url
  helpers.studio_article_path(article.uuid, content_locale: content_locale)
end
```

**Do NOT:**
- Inherit from `ApplicationPresenter`
- Use `include Rails.application.routes.url_helpers` in presenters
- Access route helpers via global scope

## Purpose

A **Presenter** is a lightweight wrapper around a single model (or small aggregate) that encapsulates display logic and UI transformations. It acts as a translation layer between the domain model and the view, ensuring:

1. **View-agnostic display logic** — the same presenter works for multiple views (web, API, emails).
2. **Model purity** — no UI concerns pollute the ActiveRecord model.
3. **Clean controller-to-view boundary** — controllers build presenters; views consume them.
4. **Reusable transformations** — display methods are shared across all render contexts.

## Session-Proven Pattern (May 2026)


For article pages, use two presenters with clear intent and **no namespace stuttering**:

1. `Articles::Presenter::Default` for reusable article display logic (cards, lists, related items, `.wrap`).
2. `Articles::Presenter::Show` for show-page-only orchestration (continuation blocks, show-only composition).

This avoids a "god presenter" and keeps `.wrap` collections lightweight. **Never use `ArticlePresenter` or `ShowPresenter` as class or file names.**

## Naming Contract (No Stuttering)

Presenter naming in this repository follows the architecture no-stuttering rule:

1. Use `Default`, `Show`, `Index`, etc. inside `Domain::Presenter` namespaces.
2. Do not use names like `ArticlePresenter`, `ShowPresenter`, `ProfilePresenter`.
3. File names must mirror these short intent names (for example `default.rb`, `show.rb`).

**Correct examples:**
- `app/concepts/articles/presenter/default.rb` → `Articles::Presenter::Default`
- `app/concepts/articles/presenter/show.rb` → `Articles::Presenter::Show`
- `app/concepts/studio/presenter/default.rb` → `Studio::Presenter::Default`

**Incorrect examples:**
- `app/concepts/articles/presenter/article_presenter.rb`
- `app/concepts/articles/presenter/show_presenter.rb`
- `app/concepts/authors/presenter/profile_presenter.rb`

## When to Use Presenters

✅ **Use a Presenter when:**
- A single model needs display-specific methods (e.g., `display_title`, `status_label`, `published_at_label`).
- The same model is displayed in multiple views with different context (e.g., `Articles::Presenter::Default` works in studio/show and public/show).
- You need locale-aware or context-aware presentation (e.g., `ui_locale`, `viewer_id`).
- You have a collection of models and need a uniform wrapper (use `.wrap(collection)`).
- Display logic depends on user permissions or request context (e.g., show draft status only to author).

❌ **Do NOT use a Presenter when:**
- The logic belongs in the model (validation, state predicates, associations).
- You're just renaming a single method (e.g., `article.title` → `presenter.title` adds no value).
- You need to compose multiple unrelated models (use a custom view component instead).
- The transformation is one-off and never reused.

## The SimpleDelegator Pattern

All Papyro presenters inherit from or wrap `SimpleDelegator`. This allows:

1. **Transparent delegation** — call any model method directly on the presenter.
2. **Method override** — define display-specific versions of model methods without losing access to originals.
3. **Lightweight** — no performance overhead compared to raw objects.

### Why SimpleDelegator?

```ruby
# Without SimpleDelegator, you'd write:
class Articles::Presenter::Default
  def initialize(article)
    @article = article
  end
  
  def title
    @article.title
  end
  
  def excerpt
    @article.excerpt
  end
  
  # ... and repeat for every method you want to delegate
end

# With SimpleDelegator, you write:
class Articles::Presenter::Default < SimpleDelegator
  def initialize(article, ui_locale: I18n.locale)
    super(article)  # SimpleDelegator automatically delegates to article
    @ui_locale = ui_locale.to_s
  end
  
  def display_title
    # Custom logic — but you can still call `title` on the wrapped article!
    # SimpleDelegator passes through everything else automatically.
  end
end
```

---

> **Presenter Archetype Example:** file naming and complete presenter → [references/archetype-example.md](references/archetype-example.md)

> **Controller and View Integration:** how controllers build and views consume presenters → [references/integration.md](references/integration.md)

## Key Rules

### ✅ DO

1. **Use SimpleDelegator** — inherit from it, never duplicate delegation logic.
2. **Provide a .wrap helper** — makes collection wrapping trivial in controllers.
3. **Accept context parameters** — `ui_locale`, `viewer_id`, `request_context`, etc.
4. **Return simple values** — booleans, strings, integers, arrays. Let the view decide rendering.
5. **Use no-stutter names** — `Default`/`Show` inside `Domain::Presenter`, not `ArticlePresenter`.
6. **Make presenters immutable** — treat them as read-only wrappers.
7. **Document transformation intent** — add a comment explaining why the method exists.
8. **Use base + context presenters when needed** — keep generic model presentation in base presenter and page-specific composition in context presenter (e.g., `Default` + `Show`).

### ❌ DO NOT

1. **Add CSS classes to presenters** — return data, not HTML markup. Let the view decide styling.
2. **Embed conditional HTML** — no `if published? ? "published" : "draft"` returning strings with semantic meaning. Return simple values; let view handle UI.
3. **Create nested presenters** — if you need to present a related model, just wrap it with its own presenter.
4. **Mutate the wrapped model** — presenters are read-only views; they never modify state.
5. **Use presenters for business logic** — validation, state transitions, permissions — those belong in models/operations.
6. **Create presenter per view** — reuse the same presenter across multiple views when the logic is identical.
7. **Forget to pass context** — if a method depends on `Current.user`, accept it as an initializer parameter instead.
8. **Hardcode a default language** — never compare locale to literal values such as `"en"`; compare against `original_locale`.
9. **Break presenter compatibility during renames** — preserve existing public presenter methods used by views unless the view and tests are updated in the same change.

---

## Presenter Migration Safety Checklist

When renaming or moving presenters:

1. Preserve all public methods consumed by current views/components unless intentionally removed.
2. Remove legacy duplicate files after migration (`*_presenter.rb` leftovers are forbidden).
3. Verify module/class/path alignment for Zeitwerk.
4. Update all controller and view references in the same patch.
5. Run targeted presenter/controller tests, then full suite.

---

> **Presenter Types and Testing:** domain, aggregate, collection presenters; tests → [references/types-and-testing.md](references/types-and-testing.md)

## Troubleshooting

| Problem | Solution |
|---|---|
| "Presenter doesn't have method X from the model" | `SimpleDelegator` passes through undefined methods automatically. If it's not working, check: does the method exist on the wrapped model? Is it being called on the presenter or on the wrapped model directly? |
| "I'm duplicating logic across multiple presenters" | Extract a shared method or private helper to a concern/module, then include it. Or consider if a single presenter can serve multiple views. |
| "My presenter is 200+ lines" | Split into multiple presenters (e.g., `Show` + `Index`) or move complex transformations to Query Objects or Services. |
| "I'm adding CSS classes in my presenter" | Stop. Return clean data (booleans, status strings, counts). Let the view decide styling via Phlex/Tailwind. |
| "I'm creating presenters but my controller still has display logic" | Move that logic into the presenter. Controllers should only orchestrate operations and build presenters, never compute display strings. |

## Query Guardrail

If a presenter reads associated data (for example `user.profile.username`), make sure the query preloads those associations to avoid N+1.

Example:

```ruby
Articles::PublishedBySlugQuery
  .call({ slug: slug, locale: I18n.locale })
  # query should include: includes(user: :profile)
```

---

## See Also

- **[phlex-view-pattern/SKILL.md](./../phlex-view-pattern/SKILL.md)** — Primary view structure guidance. Views consume presenters but do not create them.
- **[operation-pattern/SKILL.md](./../operation-pattern/SKILL.md)** — Presenters complement operations; operations handle writes, presenters handle reads.
- **[models/SKILL.md](./../models/SKILL.md)** — Keep models skinny; move display logic to presenters.
- **[query-object-pattern/SKILL.md](./../query-object-pattern/SKILL.md)** — Queries fetch data; presenters transform it for display.
