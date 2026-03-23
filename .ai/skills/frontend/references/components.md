# Phlex Component Reference

For complete rules, use [VERIFICATION_CHECKLIST.md](../VERIFICATION_CHECKLIST.md#components).

## Core Conventions

- Components inherit from `Components::Base`.
- Use `view_template` (not `template`).
- Use `initialize(..., **attrs)` and pass attrs via `attrs_without_class` + `merged_classes` helpers when rendering tags.
- Use proper namespace casing: `Components::Ui`, not `Components::UI`.

## Compound Component Convention

For compound components, the parent yields itself and child helpers render directly.

```ruby
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
```

Do not use child `.new` calls inside yielded APIs.

## Minimal Component Example

```ruby
module Components
  module Ui
    class Notice < Components::Base
      def initialize(variant: :info, **attrs)
        @variant = variant
        @attrs = attrs
      end

      def view_template(&block)
        div(class: classes, **attrs_without_class, &block)
      end

      private

      def classes
        ["rounded-lg border px-3 py-2 text-sm", variant_classes[@variant], @attrs[:class]].compact.join(" ")
      end

      def variant_classes
        {
          info: "border-border bg-muted text-foreground",
          danger: "border-destructive/30 bg-destructive/10 text-destructive"
        }
      end
    end
  end
end
```
