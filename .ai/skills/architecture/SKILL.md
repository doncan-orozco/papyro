---
name: architecture
description: Clean Architecture patterns with Trailblazer 2.1 for Rails applications. Use when implementing Operations, Contracts, Controllers, Queries, Services, or organizing application structure following the Papyro architecture patterns. Covers domain-driven organization, file structure, and common development workflows.
---

# Architecture (Clean Architecture + Trailblazer 2.1)

## Dependencies
- trailblazer-operation
- trailblazer-rails
- dry-monads
- dry-validation

## File Structure (Hybrid: Trailblazer Concepts + Rails Conventions)
```
app/
  concepts/
    game/
      operation/
        move_player.rb
      contract/
        move_player.rb
    player/
      operation/
        create.rb
      contract/
        create.rb
  
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
  queries/           ← Query objects
  services/          ← Domain services
```

## Implementation Notes

This file focuses on patterns and examples. For requirements, see:
- [Architecture rules](../../VERIFICATION_CHECKLIST.md#-architecture--organization)
- [Queries](../../VERIFICATION_CHECKLIST.md#queries-read-model)
- [Services](../../VERIFICATION_CHECKLIST.md#services)
- [Task and issue requirements](../../VERIFICATION_CHECKLIST.md#taskissue-requirements)

Example: custom collection actions can support Turbo Frames when they describe a domain subset. See:
- [Turbo Frames](../../VERIFICATION_CHECKLIST.md#-turbo-frames)
## Operations Flow (typical)
1. `Model` step (load record from `app/models/`)
2. `Contract::Build` (from `app/concepts/{domain}/contract/`)
3. `Contract::Validate`
4. Domain/service steps
5. `Contract::Persist`
6. Broadcast step

## For Verification & Requirements

See [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md#-architecture--organization) for complete requirements.

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
    @articles = Articles::PublishedQuery.call
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
