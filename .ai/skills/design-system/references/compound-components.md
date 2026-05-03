# Compound Component Pattern - Complete Reference

## Overview

**Every multi-part Phlex component in Papyro uses the compound component pattern.** This ensures consistency, maintainability, and a clean API across all 40+ UI components.

The pattern ensures:
- Clean, intuitive view code without `.new` calls on children
- Type-safe composition (IDE autocomplete)
- Consistent styling across child parts
- Easy backward compatibility migration
- Single source of truth for default styling

## Components Using This Pattern (Complete List)

| Component | Child Parts | Interactive |
|-----------|------------|-------------|
| **Accordion** | Item, Trigger, Content | Yes (Stimulus) |
| **Alert** | Title, Description | No |
| **AlertDialog** | Overlay, Content, Header, Footer, Title, Description, Cancel, Action | Yes |
| **Avatar** | Image, Fallback | No |
| **Breadcrumb** | List, Item, Link, Page, Separator | No |
| **Calendar** | Header, Body, Day Cell | Yes |
| **Card** | Header, Title, Description, Content, Footer | No |
| **Carousel** | Content, Item, Previous, Next, Indicators | Yes |
| **Collapsible** | Trigger, Content | Yes |
| **Command** | Input, List, Empty, Group, Item, Shortcut, Separator | Yes |
| **ContextMenu** | Trigger, Content, Item, CheckboxItem, RadioGroup, Separator, Label | Yes |
| **DataTable** | Header, Body, Row, Head, Cell, Footer, Pagination | No |
| **Dialog** | Overlay, Content, Header, Title, Description, Footer, Close | Yes |
| **DropdownMenu** | Trigger, Content, Item, Separator, Label | Yes |
| **Form** | Field, Label, Input, Error, Help | No |
| **HoverCard** | Trigger, Content | Yes |
| **MenuBar** | Menu, Trigger, Content, Item, Separator, Sub | Yes |
| **NavigationMenu** | List, Item, Link, Trigger, Content, Indicator, Viewport | Yes |
| **Pagination** | Content, Item, PreviousLink, NextLink, Ellipsis | No |
| **Popover** | Trigger, Content, Anchor | Yes |
| **RadioGroup** | Item, Label | Yes |
| **Resizable** | PanelGroup, Panel, Handle | Yes |
| **ScrollArea** | Viewport, Scrollbar, Thumb | No |
| **Sheet** | Overlay, Content, Header, Title, Description, Footer, Close | Yes |
| **Table** | Header, Body, Footer, Row, Head, Cell, Caption | No |
| **Tabs** | List, Trigger, Content | Yes |
| **Toast** | Provider, Viewport, Root, Title, Description, Action, Close | Yes |
| **ToggleGroup** | Item | Yes |

## Complete Pattern Example: DropdownMenu

This is the canonical example showing all pattern elements:

```ruby
# app/components/ui/dropdown_menu.rb

module Components
  module Ui
    # Parent component that yields itself
    class DropdownMenu < Components::Base
      def initialize(**attrs)
        @attrs = attrs
        # Set default Stimulus controller (eliminates boilerplate in views)
        @attrs[:data] ||= {}
        @attrs[:data][:controller] = "ui--dropdown" unless @attrs[:data][:controller]
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class) do
          yield self if block
        end
      end

      # === Helper Methods for Child Parts ===
      # These are what views call. They handle instantiation internally.

      def trigger(**attrs, &block)
        render Trigger.new(**attrs, &block)
      end

      def content(**attrs, &block)
        render Content.new(**attrs, &block)
      end

      def item(**attrs, &block)
        render Item.new(**attrs, &block)
      end

      def separator(**attrs)
        render Separator.new(**attrs)
      end

      def label(**attrs, &block)
        render Label.new(**attrs, &block)
      end

      # === Nested Child Classes ===
      # Each child is a nested class with full styling responsibility

      class Trigger < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          button(
            type: :button,
            class: merged_classes,
            **attrs_without_class,
            &block
          )
        end

        private

        def classes
          [
            "inline-flex items-center justify-center",
            "rounded-lg px-3 py-2",
            "text-sm font-medium",
            "transition-colors",
            "hover:bg-muted",
            "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/20",
            "disabled:pointer-events-none disabled:opacity-50"
          ].join(" ")
        end
      end

      class Content < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          div(
            role: :menu,
            class: merged_classes,
            **attrs_without_class,
            &block
          )
        end

        private

        def classes
          [
            "!fixed z-50 min-w-[8rem]",
            "overflow-hidden",
            "rounded-lg border border-border bg-popover p-1",
            "text-popover-foreground shadow-md"
          ].join(" ")
        end
      end

      class Item < Components::Base
        def initialize(href: nil, variant: :default, **attrs)
          @href = href
          @variant = variant
          @attrs = attrs
        end

        def view_template(&block)
          element = @href ? :a : :button
          
          send(element,
            href: @href,
            type: (@href ? nil : :button),
            role: :menuitem,
            class: merged_classes,
            **attrs_without_class,
            &block
          )
        end

        private

        def classes
          [
            "relative flex cursor-pointer select-none items-center w-full",
            "rounded-md px-2 py-1.5",
            "text-sm text-left outline-none",
            "transition-colors",
            "hover:bg-accent hover:text-accent-foreground",
            "focus:bg-accent focus:text-accent-foreground",
            "disabled:pointer-events-none disabled:opacity-50",
            variant_classes.fetch(@variant, "")
          ].join(" ")
        end

        def variant_classes
          {
            default: "",
            destructive: "text-destructive hover:bg-destructive hover:text-destructive-foreground"
          }
        end
      end

      class Separator < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template
          div(class: merged_classes, **attrs_without_class)
        end

        private

        def classes
          "-mx-1 my-1 h-px bg-muted"
        end
      end

      class Label < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          div(class: merged_classes, **attrs_without_class, &block)
        end

        private

        def classes
          "px-2 py-1.5 text-xs font-medium text-muted-foreground"
        end
      end

      # === Legacy Compatibility Aliases ===
      # Maps old class names to new nested classes for gradual migration
      DropdownMenuTrigger = Trigger
      DropdownMenuContent = Content
      DropdownMenuItem = Item
      DropdownMenuSeparator = Separator
      DropdownMenuLabel = Label
    end
  end
end
```

## Usage Examples

### Simple Dropdown Menu (New Pattern)

```ruby
# app/views/articles/show.rb

render Components::Ui::DropdownMenu.new(
  data: { ui__dropdown_placement_value: "bottom-end" }
) do |dropdown|
  dropdown.trigger(variant: :ghost, size: :icon) do
    render Components::Ui::Icon.new(:"more-horizontal")
  end

  dropdown.content do
    dropdown.item { "Edit" }
    dropdown.item { "Duplicate" }
    dropdown.separator
    dropdown.item(variant: :destructive) { "Delete" }
  end
end
```

### Card with Multiple Sections (New Pattern)

```ruby
# app/views/admin/dashboard/index.rb

render Components::Ui::Card.new(class: "mb-6") do |card|
  card.header do
    card.title { "User Statistics" }
    card.description { "Year-to-date overview" }
  end

  card.content(class: "space-y-4") do
    # Chart or list content
  end

  card.footer do
    render Components::Ui::Button.new { "View Details" }
  end
end
```

### Table with Rows (New Pattern)

```ruby
# app/views/admin/articles/index.rb

render Components::Ui::Table.new do |table|
  table.header do
    table.row do
      table.head { "Title" }
      table.head { "Author" }
      table.head { "Published" }
    end
  end

  table.body do
    articles.each do |article|
      table.row do
        table.cell { article.title }
        table.cell { article.author.name }
        table.cell { l(article.published_at, format: :short) }
      end
    end
  end
end
```

### Accordion with Multiple Items (New Pattern)

```ruby
# app/views/help/index.rb

render Components::Ui::Accordion.new(type: :single) do |accordion|
  accordion.item do
    accordion.trigger { "How do I reset my password?" }
    accordion.content { "Visit the account settings page..." }
  end

  accordion.item do
    accordion.trigger { "What payment methods do you accept?" }
    accordion.content { "We accept all major credit cards..." }
  end
end
```

## Migration Guide (Old → New)

### Before (Old Pattern - Avoid in New Code)

```ruby
# Using old nested classes
render Components::Ui::CardHeader.new do
  render Components::Ui::CardTitle.new { "Settings" }
  render Components::Ui::CardDescription.new { "Manage your account" }
end

render Components::Ui::CardContent.new do
  # form fields
end
```

### After (New Pattern - Required for New Code)

```ruby
# Using yielded helper methods
render Components::Ui::Card.new do |card|
  card.header do
    card.title { "Settings" }
    card.description { "Manage your account" }
  end

  card.content do
    # form fields
  end
end
```

## Checklist for Creating Compound Components

When building a new multi-part UI component, follow this checklist:

1. **Parent Class Setup**
   - [ ] Inherit from `Components::Base`
   - [ ] Accept `**attrs` in `initialize`
   - [ ] Store as `@attrs = attrs`
   - [ ] Define `view_template(&block)` that yields self
   - [ ] If interactive, inject default Stimulus controller in initialize

2. **Child Helper Methods**
   - [ ] Define one method per child part (e.g., `def header(**attrs, &block)`)
   - [ ] Each method renders the child class immediately
   - [ ] Pass `**attrs` and `&block` to child

3. **Nested Child Classes**
   - [ ] Create one nested class per child part
   - [ ] Each inherits from `Components::Base`
   - [ ] Each has `initialize(**attrs)` storing to `@attrs`
   - [ ] Each implements `view_template` method
   - [ ] Each has private `classes` method with all styling

4. **Backward Compatibility**
   - [ ] Add aliases at end of parent: `ChildAlias = ChildClass`
   - [ ] Allows gradual migration from old code

5. **Design System**
   - [ ] Add examples to `app/views/design_system/index.rb`
   - [ ] Display all variants and interactive states
   - [ ] Add English and Spanish translations in `config/locales/{en,es}/design_system.yml`

6. **Documentation**
   - [ ] Update copilot-instructions.md if new component type
   - [ ] Add to compound components list at top of this document

## Performance Notes

- Each child helper method creates a new instance (standard Phlex pattern)
- No unnecessary re-renders because parent manages the tree
- Stimulus controllers attached once to parent, manage child interactions
- CSS class merging happens in `Components::Base` — use `merged_classes` in `view_template`

## Common Pitfalls

❌ **Don't**: Call `.new` on nested classes in views
```ruby
render Components::Ui::CardTitle.new { "Title" }  # ❌ Wrong
```

✅ **Do**: Call helper methods on parent
```ruby
render Components::Ui::Card.new do |card|
  card.title { "Title" }  # ✅ Correct
end
```

❌ **Don't**: Forget `initialize(**attrs)` in nested classes
```ruby
class Title < Components::Base
  # Missing initialize!
  def view_template(&block)
    h2(class: merged_classes, &block)
  end
end
```

✅ **Do**: Always include initialize
```ruby
class Title < Components::Base
  def initialize(**attrs)
    @attrs = attrs
  end

  def view_template(&block)
    h2(class: merged_classes, **attrs_without_class, &block)
  end
end
```

❌ **Don't**: Hardcode Stimulus data in parent without allowing override
```ruby
def initialize(**attrs)
  @attrs = attrs
  @attrs[:data][:controller] = "ui--dropdown"  # No escape hatch!
end
```

✅ **Do**: Allow caller to override
```ruby
def initialize(**attrs)
  @attrs = attrs
  @attrs[:data] ||= {}
  @attrs[:data][:controller] = "ui--dropdown" unless @attrs[:data][:controller]
end
```

## Questions?

Refer to the implementations in `app/components/ui/`. All 40+ components follow this exact pattern.
