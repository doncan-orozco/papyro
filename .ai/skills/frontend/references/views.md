# Phlex Views Reference

For complete rules, use [VERIFICATION_CHECKLIST.md](../../../VERIFICATION_CHECKLIST.md#views).

## Core Conventions

- Views inherit from `Views::Base`.
- Use namespace `Views::{Domain}::{Action}`.
- Use `view_template` and compose pages with components.
- Keep controllers thin and pass explicit data into the view initializer.
- Use fully-qualified i18n keys for user-facing text.

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
