---
name: turbo
description: Turbo Frames patterns for decomposing pages into domain-based segments with Hotwire. Use when implementing lazy-loading content, creating frame-based interactions, or organizing complex pages. Covers frame loading strategies (eager/lazy), frame response structure, and domain-driven decomposition.
---

# Turbo Frames (Hotwire Decomposition)

## Dependencies
- hotwire-turbo-rails
- turbo-rails

## Overview
Use Turbo Frames to decompose complex pages into domain-based segments. Frames typically represent meaningful domain concepts rather than atomic UI elements.

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

## Frame Response Structure (Example)

Example response wraps content in a matching `turbo-frame` tag. See the checklist for requirements.

```ruby
# app/views/articles/featured.rb (response)
turbo_frame_tag("featured_articles") do
  # Frame content here
end
```

## Domain-Based Frame Design

Example domain concepts for frames:

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

Example: dedicated controller actions for frames using collection routes (custom actions on a resource):

```ruby
# config/routes.rb
resources :articles do
  collection do
    get :featured  # Creates GET /articles/featured
  end
end

# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  def featured
    render Views::Articles::Featured.new
  end
end
```

### RESTful Pattern with Turbo Frames

Route naming convention example:
```ruby
resources :articles do
  collection do
    get :featured      # Articles domain, featured subset
    get :popular       # Articles domain, popular subset
    get :trending      # Articles domain, trending subset
  end
end
```

Custom collection actions can work well when the action describes a domain subset consumed by a Turbo Frame.

## Frame ID and Route Notes

See requirements in:
- [Turbo Frames](/.github/copilot-instructions.md#-turbo-frames)
- [Task and issue requirements](/.github/copilot-instructions.md#taskissue-requirements)

## Component vs Frame Trade-offs

| Aspect | Component | Frame |
|--------|-----------|-------|
| **Purpose** | Reusable UI building block | Page decomposition/domain segment |
| **Location** | `app/components/` | `app/views/` with controller |
| **Data Source** | Constructor arguments | Database query via controller |
| **Caching** | Can be expensive (per-request) | HTTP caching friendly |
| **Navigation** | No link/form handling | Full link/form scope |
| **Use Case** | Article card in a list | Entire featured articles section |

> **For detailed frontend/backend checklists, see [copilot-instructions.md](/.github/copilot-instructions.md)**

## Companion Skills

- **[../phlex-view-pattern/SKILL.md](../phlex-view-pattern/SKILL.md)** — **PRIMARY view structure source**: Golden archetype for all Phlex views and components. Load this first for any work in `app/views/` or `app/components/`. This turbo skill defers to phlex-view-pattern for Turbo Frame ID conventions (stable IDs, `_top` targeting, empty placeholder placement), sub-component decomposition, and frame composition shape.
- **[../frontend/SKILL.md](../frontend/SKILL.md)** for Stimulus integration and Hotwire patterns

