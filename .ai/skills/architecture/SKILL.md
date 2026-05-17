---
name: architecture
description: Clean Architecture patterns with pure dry-rb operations for Rails applications. Use when implementing Operations, Contracts, Controllers, Queries, Services, or organizing application structure following the Papyro architecture patterns. Covers domain-driven organization, file structure, and common development workflows.
---

# Architecture (Clean Architecture + dry-rb)

## Dependencies
- dry-monads
- dry-validation

## File Structure (Domain + Rails Conventions)
```
app/
  concepts/
    articles/
      operation/
        create.rb
        update.rb
      contract/
        create.rb
        update.rb
      query/
        published.rb
      service/
        content_analysis.rb
      presenter/
        default.rb
      validator/
        body.rb
  
  components/        ← Reusable UI components (Phlex)
    game/
      player_card.rb
    ui/
      button.rb
  
  views/             ← Page-level views (Phlex)
    games/
      index.rb
      show.rb
    players/
      index.rb
  
  controllers/       ← Thin controllers
  channels/          ← WebSocket channels
  models/            ← ActiveRecord (persistence only)
  javascript/
    controllers/
      studio/
        articles/
          autosave_controller.js
```

### Vertical Slice Rule

For domain-specific backend code, prefer `app/concepts/{domain}/...` over horizontal top-level folders.

#### 🚫 No Namespace Stuttering
**Do not repeat the domain or type in the class or file name.**
For example, use `Published` (not `PublishedQuery`), `Body` (not `BodyValidator`), and `Default`/`Show` (not `ArticlePresenter`/`ShowPresenter`).

**Correct:**
- `app/concepts/articles/query/published.rb` → `Articles::Query::Published`
- `app/concepts/articles/validator/body.rb` → `Articles::Validator::Body`
- `app/concepts/articles/presenter/default.rb` → `Articles::Presenter::Default`

**Incorrect:**
- `published_query.rb`, `body_validator.rb`, `article_presenter.rb`

1. Put read flows in `app/concepts/{domain}/query/` using `Domain::Query::*` namespaces (no stuttering).
2. Put domain services in `app/concepts/{domain}/service/` using `Domain::Service::*` namespaces.
3. Put domain validators in `app/concepts/{domain}/validator/` using `Domain::Validator::*` namespaces.
4. Put domain presenters in `app/concepts/{domain}/presenter/` using `Domain::Presenter::*` namespaces.
5. Keep controllers thin and call these namespaced objects directly.

### Refactor Safety Checklist (Required)

When performing structural refactors (renames/moves between `app/presenters`, `app/queries`, and `app/concepts`):

1. Remove legacy duplicate files immediately after references are migrated.
2. Verify file path, module nesting, and class name alignment for Zeitwerk.
3. Confirm all call sites are updated (controllers, views, operations, tests).
4. Run targeted suites for touched domains before full test runs.
5. Finish with full regression (`bin/rails test` and `bin/rails test:system`).

## Host-Coupled Engine Pattern (Papyro Studio)

When working on the private `PapyroStudio` engine in this workspace:

1. Treat the host app as the owner of database schema, core models (`User`, `Article`), and authentication/session lifecycle.
2. Treat the engine as an orchestration and UI boundary mounted under the `studio` subdomain.
3. Keep mutations and policies aligned with host-domain behavior so the engine does not fork domain logic accidentally.
4. Run engine tests from the host app root so the engine reuses the host environment and fixtures.

For the ownership matrix, mount boundary, test helper wiring, and run commands, load:
- [references/host-coupled-engine-pattern.md](references/host-coupled-engine-pattern.md)

## Implementation Notes

This file focuses on patterns and examples. For requirements, see:
- [Architecture rules](/.github/copilot-instructions.md#-architecture--organization)
- [Queries](/.github/copilot-instructions.md#queries-read-model)
- [Services](/.github/copilot-instructions.md#services)
- [Task and issue requirements](/.github/copilot-instructions.md#taskissue-requirements)

For the canonical mutation-command shape, also load `.ai/skills/operation-pattern/SKILL.md`.
For all view and component work in `app/views/` or `app/components/`, load `.ai/skills/phlex-view-pattern/SKILL.md` — it is the primary source of frontend structure guidelines.

## Reference Map

- **[references/architecture-overview.md](references/architecture-overview.md)**
  Use for layer responsibilities and high-level composition guidance.
- **[references/operations.md](references/operations.md)**
  Use for write-flow patterns with `ApplicationOperation` and `Dry::Monads`.
- **[references/contracts.md](references/contracts.md)**
  Use for dry-validation contract structure and examples.
- **[references/controllers.md](references/controllers.md)**
  Use for thin controller patterns and operation orchestration.
- **[references/queries.md](references/queries.md)**
  Use for query-object structure and read-model boundaries.
- **[references/services.md](references/services.md)**
  Use for focused domain service patterns.
- **[references/jobs.md](references/jobs.md)**
  Use for background job orchestration around operations.
- **[references/models.md](references/models.md)**
  Use for persistence-only model guidance.
- **[references/deployment.md](references/deployment.md)**
  Use for deployment considerations that affect architecture decisions.
- **[references/WRITEBOOK_IMPLEMENTATION_SUMMARY.md](references/WRITEBOOK_IMPLEMENTATION_SUMMARY.md)**
  Use as a larger end-to-end implementation example when you need a concrete slice of the architecture in practice.
- **[references/session-learnings-mutation-flows.md](references/session-learnings-mutation-flows.md)**
  Use for compact, recent decisions on mutation operation shape, validation boundaries, and update-flow anti-patterns.
- **[references/host-coupled-engine-pattern.md](references/host-coupled-engine-pattern.md)**
  Use for host-app/engine ownership boundaries, mounted subdomain routing, shared-session expectations, and host-driven engine test execution.

Example: custom collection actions can support Turbo Frames when they describe a domain subset. See:
- [Turbo Frames](/.github/copilot-instructions.md#-turbo-frames)
## Operations Flow (typical)
1. Authorize at the controller boundary (Pundit)
2. Validate and sanitize with dry-validation contract
3. Build model and enforce business rules in the operation
4. Persist model and rely on ActiveRecord state validations
5. Return `Success(payload)` or `Failure(model: ...)` for form rerender paths

## For Verification & Requirements

See [copilot-instructions.md](/.github/copilot-instructions.md#-architecture--organization) for complete requirements.

## Controller Concerns (Cross-Cutting Features)

Use concerns for cross-cutting controller features (locale, tenant selection, request context setup, audit metadata) instead of placing feature methods directly in `ApplicationController`.

**Pattern:**

1. Create concern in `app/controllers/concerns/{feature}.rb`
2. Use `ActiveSupport::Concern`
3. Register callbacks in the concern `included` block
4. Keep `ApplicationController` as composition root (`include Authentication`, `include LocaleManagement`, framework config)

```ruby
# app/controllers/concerns/locale_management.rb
module LocaleManagement
  extend ActiveSupport::Concern

  included do
    prepend_before_action :set_locale
  end

  private

  def set_locale
    I18n.locale = requested_locale || I18n.default_locale
  end
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Authentication
  include LocaleManagement
end
```

## Common Development Patterns

### Adding a Page

1. Create `app/controllers/{domain}_controller.rb`
2. Create `app/views/{domain}/action.rb` (inherit from `Views::Base`)
3. Create route in `config/routes.rb`
4. Create `config/locales/{en,es}/{file}.yml`
5. Use fully-qualified keys: `t("articles.index.title")`

**Example:**
```ruby
# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  def index
    @articles = Articles::Query::Published.call
  end
end

# app/views/articles/index.rb
module Views
  module Articles
    class Index < Views::Base
      def view_template
        h1 { t("articles.index.title") }
        # ... rest of view
      end
    end
  end
end

# config/routes.rb
get "articles", to: "articles#index", as: :articles

# config/locales/en/pages.yml
en:
  articles:
    index:
      title: "Articles"
```

### Adding a Component

1. Create `app/components/{domain}/name.rb` (inherit from `Components::Base`)
2. Create locale keys in `config/locales/{en,es}/components.yml`
3. Use full path keys: `t("components.domain.section.key")`
4. Include `**attrs` for Stimulus support

**Example:**
```ruby
# app/components/articles/card.rb
module Components
  module Articles
    class Card < Components::Base
      def initialize(article:, **attrs)
        @article = article
        @attrs = attrs
      end
      
      def view_template
        div(class: "card", **@attrs) do
          h2 { @article.title }
          p { t("components.articles.card.read_more") }
        end
      end
    end
  end
end

# config/locales/en/components.yml
en:
  components:
    articles:
      card:
        read_more: "Read more"
```

### Adding a Turbo Frame

1. Create `app/controllers/{domain}_controller.rb` with action
2. Create `app/views/{domain}/action.rb` with `turbo_frame_tag`
3. Add route: `get "path", to: "{domain}#action", as: :route_name`
4. In main view: `turbo_frame_tag("id", src: route_name_path, loading: :lazy)`
5. Add i18n translations

**Example:**
```ruby
# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  def featured
    @articles = Articles::FeaturedQuery.call.limit(3)
  end
end

# app/views/articles/featured.rb
module Views
  module Articles
    class Featured < Views::Base
      def view_template
        turbo_frame_tag("featured_articles") do
          h2 { t("articles.featured.title") }
          @articles.each do |article|
            render Components::Articles::Card.new(article: article)
          end
        end
      end
    end
  end
end

# In main page view:
turbo_frame_tag(
  "featured_articles",
  src: featured_articles_path,
  loading: :lazy
) do
  p { t("articles.featured.loading") }
end

# config/routes.rb
get "articles/featured", to: "articles#featured", as: :featured_articles
```

### Adding Stimulus Interaction

1. Create `app/javascript/controllers/{domain}/{feature}_controller.js`
2. Add data attributes to component: `data: { controller: "domain--feature", ... }`
3. Use `static targets`, `values` for data binding
4. Dispatch custom events for communication

**Example:**
```javascript
// app/javascript/controllers/articles/filter_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "results"]
  static values = {
    url: String
  }
  
  async filter(event) {
    event.preventDefault()
    
    const formData = new FormData(this.formTarget)
    const params = new URLSearchParams(formData)
    
    const response = await fetch(`${this.urlValue}?${params}`)
    const html = await response.text()
    
    this.resultsTarget.innerHTML = html
    
    // Dispatch event for other controllers
    this.dispatch("filtered", { detail: { count: results.length } })
  end
}
```

```ruby
# In component:
div(data: { 
  controller: "articles--filter",
  articles__filter_url_value: articles_path
}) do
  form(data: { articles__filter_target: "form" }) do
    # form fields
  end
  
  div(data: { articles__filter_target: "results" }) do
    # results
  end
end
```
