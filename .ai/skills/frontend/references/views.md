# Phlex Views Reference

For complete rules, use [copilot-instructions.md](/.github/copilot-instructions.md#views).

## Core Conventions

- Views inherit from `Views::Base`.
- Use namespace `Views::{Domain}::{Action}`.
- Use `view_template` and compose pages with components.
- Keep controllers thin and pass explicit data into the view initializer.
- Use fully-qualified i18n keys for user-facing text.
- For complex pages with distinct workflows, compose separate intent-specific components (for example editor form + settings form) instead of passing mode flags into one component.

## Modal/Overlay Composition in Views

When a page uses a Sheet, Dialog, or other fixed overlay, **the overlay's content must not be rendered inside a stacking context** (e.g. a `sticky + z-*` container or a container with `transform`/`filter`/`will-change`). If it is, the `position: fixed` panel/overlay will be confined to that stacking context and can appear behind higher-stacked ancestors such as a sticky navbar.

**Correct pattern:** keep the trigger inside the sticky toolbar, but place `sheet.content` *after* the sticky block, under the same Sheet root. The Sheet compound-component block can wrap arbitrary page DOM to allow this split.

```ruby
# CORRECT — trigger stays in sticky toolbar; content is outside it
render Components::Ui::Sheet.new do |sheet|
  div(class: "sticky top-0 z-20 ...") do   # sticky toolbar
    sheet.trigger { ... }                   # trigger inside toolbar
  end
  div(class: "main-content ...") { ... }   # page body
  sheet.content(...) { ... }              # content OUTSIDE sticky context
end

# WRONG — content rendered inside sticky container creates a stacking conflict
div(class: "sticky top-0 z-20 ...") do
  render Components::Ui::Sheet.new do |sheet|
    sheet.trigger { ... }
    sheet.content(...) { ... }  # ← trapped inside sticky stacking context
  end
end
```

## View Example

```ruby
module Views
  module Admin
    module Articles
      class Index < Views::Base
        def initialize(articles)
          @articles = articles
        end

        def view_template
          div(class: "bg-background") do
            div(class: "mx-auto max-w-6xl px-4 py-8") do
              render Components::Ui::Breadcrumb.new(class: "mb-6") do |breadcrumb|
                breadcrumb.list do
                  breadcrumb.item do
                    breadcrumb.link(href: admin_root_path) { t("admin.articles.breadcrumbs.home") }
                  end
                  breadcrumb.separator
                  breadcrumb.item do
                    breadcrumb.page { t("admin.articles.breadcrumbs.articles") }
                  end
                end
              end

              render Components::Ui::Card.new do
                render Components::Ui::CardHeader.new do
                  render Components::Ui::CardTitle.new { t("admin.articles.index.title") }
                end
              end
            end
          end
        end
      end
    end
  end
end
```

## Controller Integration

```ruby
class Admin::ArticlesController < ApplicationController
  def index
    render Views::Admin::Articles::Index.new(Current.user.articles)
  end
end
```
