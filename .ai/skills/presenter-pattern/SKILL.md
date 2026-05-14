---
name: presenter-pattern
description: Golden archetype for display-logic presenters using SimpleDelegator. Use when creating or updating presenters that wrap models to provide view-agnostic display methods, locale-aware transformations, and collection helpers. Establishes clean separation between persistence logic, view rendering, and display transformation.
---

# Golden Presenter Pattern (Papyro)

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

## Golden Presenter Archetype

### File Naming & Location

```
app/concepts/
  articles/
    presenter/
      default.rb                   # ← Reusable article display behavior
      show.rb                      # ← Show-page composition only
  studio/
    presenter/
      default.rb                   # ← Studio article display logic
  admin/
    presenter/
      default.rb                   # ← Admin article display logic
```

**Naming convention:** short intent names in `Domain::Presenter::*` (not presenter-suffixed class names).

Why? Because the same logic is useful anywhere that domain is displayed. Tie the presenter to the **domain**, not the **view** or **controller**.

### Presenter Structure (Complete Example)

```ruby
# app/concepts/articles/presenter/default.rb
# frozen_string_literal: true

module Articles
  module Presenter
    class Default < SimpleDelegator
    # 1. The Collection Wrapper Helper (optional, but recommended)
    def self.wrap(collection, locale: I18n.locale)
      collection.map { |item| new(item, locale: locale) }
    end

    # 2. Initialization with context
    attr_reader :locale

    def initialize(article, locale: I18n.locale)
      super(article)                    # Delegate to article via SimpleDelegator
      @locale = locale.to_s
    end

    # 3. Display methods (view-agnostic logic)
    
    # Example: Locale-aware title selection
    # Locale fallback must compare against original_locale, not hardcoded "en"
    def translation_fallback?
      locale.to_s != original_locale.to_s && !translation_published?(locale)
    end

    # Example: Status badge variant logic (NO CSS, just logic)
    def status_variant
      return :destructive if trashed?
      case status
      when "draft" then :secondary
      when "published" then :default
      when "archived" then :outline
      else :secondary
      end
    end

    def status_label
      trashed? ? I18n.t("statuses.trashed") : I18n.t("statuses.#{status}")
    end

    # Example: Formatted timestamp
    def published_at_label
      if trashed?
        I18n.t("articles.deleted_at", time: I18n.l(deleted_at, format: :short))
      elsif published_at
        I18n.l(published_at, format: :short)
      else
        I18n.t("articles.not_published")
      end
    end

    # Example: Sorted collection for views
    def sorted_translations
      baseline = original_locale.to_s
      article_translations.sort_by do |translation|
        [ translation.locale.to_s == baseline ? 0 : 1, translation.locale.to_s ]
      end
    end

    # Example: Logic check (view receives the result, not the logic)
    def locale_published?(translation)
      if translation.locale.to_s == original_locale.to_s
        published?
      else
        translation.published?
      end
    end

    # 4. Private helpers (delegate to internal state)
    private

    def content_analysis
      @content_analysis ||= ::Articles::Service::ContentAnalysis.new(__getobj__)
    end
  end
  end
end
```

---

## Controller Integration

Controllers build and pass presenters to views. They do NOT use presenters internally for business logic.

```ruby
# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  allow_unauthenticated_access only: [:index, :show]

  def index
    scoped_articles = policy_scope(Article)
    articles = Articles::Query::Published.call({}, scope: scoped_articles).limit(6)

    # Use base presenter for collections
    presented_articles = Articles::Presenter::Default.wrap(articles, locale: I18n.locale)

    render Views::Articles::Index.new(
      articles: presented_articles,
      show_welcome_hero: Current.user.guest?
    )
  end

  def show
    article = find_published_article_by_slug!
    authorize article

    more_from_author = Articles::Query::Related.call(user: article.user, article_id: article.id, limit: 2)
    more_from_platform = Articles::Query::Related.call(exclude_user_id: article.user_id, article_id: article.id, limit: 2)

    # Single presenter
    render Views::Articles::Show.new(
      article: Articles::Presenter::Show.new(
        article,
        more_from_author: more_from_author,
        more_from_platform: more_from_platform,
        locale: I18n.locale
      )
    )
  end
end
```

---

## View Integration (Phlex)

In your Phlex view, the presenter appears as a regular model object with super-powers.

```ruby
# app/views/articles/show.rb
module Views
  module Articles
    class Show < Views::Base
      def initialize(article:, more_from_author: [], more_from_platform: [])
        @article = article  # This is actually a presenter
        @more_from_author = more_from_author
        @more_from_platform = more_from_platform
      end

      def view_template
        div(class: "space-y-4") do
          # Presenter methods are indistinguishable from model methods
          h1(class: "text-3xl font-bold") { @article.display_title }
          p(class: "text-muted-foreground") { @article.published_at_label }

          # Presenter can provide view-ready data
          if @article.continuation_articles.any?
            h2 { @article.continuation_heading }
            div(class: "grid grid-cols-2") do
              @article.continuation_articles.each do |related|
                render Articles::ArticleCard.new(article: related)
              end
            end
          end

          # Presenter logic is used to make decisions
          if @article.locale_published?(translation)
            render Components::Ui::Badge.new { "Published" }
          end
        end
      end
    end
  end
end
```

---

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

## Common Presenter Types

### 1. Domain Presenters (Single Model)

Wraps a single model with display methods shared across many views.

```ruby
module Articles
  module Presenter
    class Default < SimpleDelegator
  def initialize(article, locale: I18n.locale)
    super(article)
    @locale = locale
  end
  
  def display_title
    # Locale-aware title selection
  end
    end
  end
end
```

### 2. Aggregate Presenters (Related Models)

Wraps a primary model plus related data (but NOT nested presenters).

```ruby
module Authors
  module Presenter
    class Default < SimpleDelegator
  def initialize(profile, author:, current_user: nil)
    super(profile)
    @author = author
    @current_user = current_user
  end
  
  def bio
    super
  end
  
  def can_edit?
    @current_user&.id == @author.id
  end
    end
  end
end
```

### 3. Collection Presenters (Many Models)

Use `.wrap()` helper to present each model in a collection uniformly.

```ruby
# Controller
articles = Article.published.limit(10)
presented = Articles::Presenter::Default.wrap(articles, locale: I18n.locale)

# View iterates over presented articles
@articles.each do |article|
  render ArticleCard.new(article: article)  # article is a presenter
end
```

---

## Testing Presenters

Presenters are tested like any other Ruby object:

```ruby
class Articles::Presenter::ShowTest < ActiveSupport::TestCase
  test "display title falls back to original locale" do
    article = Article.create!(title: "Test", slug: "test-#{SecureRandom.hex(4)}", body: "Body", user: users(:admin))
    presenter = Articles::Presenter::Default.new(article, locale: :fr)

    assert_equal "Test", presenter.display_title
  end

  test ".wrap builds presenter collection" do
    articles = [ articles(:draft_article), articles(:published_article) ]
    presenters = Articles::Presenter::Default.wrap(articles, locale: :es)

    assert_equal 2, presenters.length
    assert presenters.all? { |presenter| presenter.is_a?(Articles::Presenter::Default) }
  end
end
```

---

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
