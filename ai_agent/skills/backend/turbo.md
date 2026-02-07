# Turbo Frames Skill (Hotwire Decomposition)

## Dependencies
- hotwire-turbo-rails
- turbo-rails

## Overview
Use Turbo Frames to decompose complex pages into domain-based segments. Each frame should represent a meaningful domain concept, not just atomic UI elements.

## Frame Loading Strategies

### Eager-Loading Frames
Load immediately when the page renders. Use for above-the-fold content that should be visible on initial page load.

```ruby
# app/views/pages/index.rb
turbo_frame_tag("featured_articles", src: featured_articles_path)
```

**When to use:**
- ✓ Content needed immediately
- ✓ Critical for page layout
- ✓ Content in viewport on load
- ✗ Heavy/expensive queries

### Lazy-Loading Frames
Load only when the frame becomes visible (scrolls into view). Use for below-the-fold content.

```ruby
# app/views/pages/index.rb
turbo_frame_tag("featured_articles", src: featured_articles_path, loading: :lazy)
```

**When to use:**
- ✓ Below-the-fold content
- ✓ Optional/supplementary sections
- ✓ Improving initial page load time
- ✗ Critical above-fold content

## Frame Response Structure

Frames must wrap content in matching `turbo-frame` tags with the same ID.

```ruby
# app/views/articles/featured.rb (response)
turbo_frame_tag("featured_articles") do
  # Frame content here
end
```

## Domain-Based Frame Design

Each frame should represent a complete domain concept, not just UI components:

```
GOOD (Domain Concepts):
- featured_articles (Articles domain)
- user_notifications (Notifications domain)
- activity_feed (Activity domain)

BAD (Atomic/UI only):
- card_section
- button_group
- header_nav
```

## Controller Structure for Frames

Create dedicated controller actions for each frame:

```ruby
# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  def featured
    render Views::Articles::Featured.new
  end
end

# config/routes.rb
get "articles/featured", to: "articles#featured", as: :featured_articles
```

## Component vs Frame Trade-offs

| Aspect | Component | Frame |
|--------|-----------|-------|
| **Purpose** | Reusable UI building block | Page decomposition/domain segment |
| **Location** | `app/components/` | `app/views/` with controller |
| **Data Source** | Constructor arguments | Database query via controller |
| **Caching** | Can be expensive (per-request) | HTTP caching friendly |
| **Navigation** | No link/form handling | Full link/form scope |
| **Use Case** | Article card in a list | Entire featured articles section |

## Verification Checklist ✓

- [ ] Frame represents a **complete domain concept** (not just UI)
- [ ] Frame has a **dedicated controller action** with clear responsibility
- [ ] Frame response is **wrapped in matching turbo-frame tag** with same ID
- [ ] Frame src path **uses a route helper** (e.g., `featured_articles_path`)
- [ ] **Loading strategy is intentional**: `loading: :lazy` for below-fold, no `loading` for eager
- [ ] Frame is **scoped in views with `Views::` namespace**
- [ ] Frame content uses **components from `app/components/`** for UI
- [ ] No **implicit dependencies** between frames
- [ ] Frame route is **named and documented** in routes.rb
- [ ] Translation keys use **domain-based structure** (e.g., `components.landing.featured_articles.title`)

> **For detailed frontend/backend checklists, see [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md)**

