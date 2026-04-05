---
name: frontend
description: Frontend development with Hotwire, Phlex, and Tailwind CSS. Use when creating views, components, or implementing frontend features. Covers Phlex file structure, component patterns, view patterns, Stimulus controllers, and Turbo integration.
---

# Frontend (Hotwire + Phlex + Tailwind)

## Development Server
- Development server runs on **port 3030** (not 3000)
- Command: `bin/dev` from workspace root
- Design System page: http://localhost:3030/design-system

## Dependencies
- phlex-rails
- phlex

## Phlex File Structure

### Components (`app/components/`)
Reusable UI building blocks - buttons, cards, avatars, etc.
```
app/components/
  game/
    player_card.rb
    move_button.rb
    map_viewport.rb
  ui/
    button.rb
    card.rb
    modal.rb
  shared/
    navbar.rb
```

### Views (`app/views/`)
Page-level templates rendered by controllers - index, show, new, edit.
```
app/views/
  games/
    index.rb
    show.rb
  players/
    index.rb
    new.rb
    edit.rb
```

## Components (Patterns)

### All Components Use `initialize(**attrs)` 
Every component must accept keyword arguments and store them in `@attrs`:
```ruby
class Button < Components::Base
  def initialize(**attrs)
    @attrs = attrs
  end
  
  def view_template(&block)
    button(class: merged_classes, **attrs_without_class, &block)
  end
end
```

### Compound Component Pattern (For ALL Multi-Part Components)
**All components with child parts (Accordion, Alert, Breadcrumb, Card, Dialog, Dropdown, etc.) MUST use the compound pattern.**

The parent component:
1. **Yields itself** to the block (not individual child components)
2. **Exposes helper methods** for each child type (not direct class access)
3. **Defines nested classes** for each child part
4. **Provides backward-compatibility aliases** for legacy code

**Pattern Structure:**
```ruby
class Accordion < Components::Base
  def initialize(**attrs)
    @attrs = attrs
  end

  def view_template(&block)
    div(class: merged_classes, **attrs_without_class) do
      yield self if block
    end
  end

  # Helper methods — these are what views call
  def item(**attrs, &block)
    render Item.new(**attrs, &block)
  end

  def trigger(**attrs, &block)
    render Trigger.new(**attrs, &block)
  end

  # Nested child classes
  class Item < Components::Base
    def initialize(**attrs)
      @attrs = attrs
    end
    
    def view_template(&block)
      div(class: merged_classes, **attrs_without_class, &block)
    end
  end

  class Trigger < Components::Base
    def initialize(**attrs)
      @attrs = attrs
    end
    
    def view_template(&block)
      button(type: :button, class: merged_classes, **attrs_without_class, &block)
    end
  end

  # Legacy compatibility aliases (for gradual migration)
  AccordionItem = Item
  AccordionTrigger = Trigger
end
```

**Usage in Views:**
```ruby
# NEW — Cleaner, strongly typed, no `.new` calls on children
render Components::Ui::Accordion.new do |accordion|
  accordion.item do
    accordion.trigger { "Question 1" }
    accordion.content { "Answer 1" }
  end
end

# OLD (still works via aliases, but avoid for new code)
render Components::Ui::AccordionItem.new do
  render Components::Ui::AccordionTrigger.new { "Question" }
end
```

**When to Use Compound Pattern:**
- ✅ **ANY** component with multiple related parts (Accordion, Alert, Breadcrumb, Card, Carousel, Collapsible, Command, Context Menu, Data Table, Dialog, Dropdown, Form, Hover Card, Menu Bar, Navigation Menu, Pagination, Popover, Radio Group, Resizable, Scroll Area, Sheet, Table, Tabs, Toast, Toggle Group)
- ❌ Simple components without children (Button, Badge, Input, Label, Separator, Skeleton, Slider)

### Set Default Stimulus Data in `initialize`
For components that require a Stimulus controller, set it as a default:
```ruby
def initialize(**attrs)
  @attrs = attrs
  # Set default controller if not already provided
  @attrs[:data] ||= {}
  @attrs[:data][:controller] = "ui--dropdown" unless @attrs[:data][:controller]
end
```

This eliminates repetitive `data: { controller: "..." }` in views.

### Required Child `data-*` Defaults for Interactive Compound Components
For interactive compound components, required child target/action bindings must be defaults in parent helper methods (not repeated in views).

Example for `DropdownMenu`:
```ruby
def trigger(**attrs, &block)
  render Trigger.new(
    **with_required_data(attrs, target: "trigger", required_action: "click->ui--dropdown#toggle"),
    &block
  )
end

def content(**attrs, &block)
  render Content.new(
    **with_required_data(attrs, target: "content", required_action: "keydown->ui--dropdown#navigate"),
    &block
  )
end

def item(**attrs, &block)
  render Item.new(
    **with_required_data(attrs, target: "item", required_action: "click->ui--dropdown#select keydown->ui--dropdown#itemKeydown"),
    &block
  )
end
```

Rules:
- Merge caller-provided `data` with defaults.
- Ensure required target/action keys are always present.
- Append required actions without removing caller actions.

Current required defaults in this codebase:
- `Switch` injects parent `controller/action`, checked value (from `checked:`), and thumb target via `switch.thumb`.
- `Tabs` injects parent controller and trigger/content targets/actions via `tabs.trigger` and `tabs.content`.
- `Select` injects parent controller/value/placeholder defaults; `select.trigger`, `select.content`, `select.item`, and `select.value` inject required select target/action bindings.
- `Tooltip` injects parent controller/delay/placement/offset defaults; `tooltip.trigger` and `tooltip.content` inject required tooltip target/action bindings.
- `Popover` injects parent `ui--popover` controller/open state defaults; `popover.trigger` injects the toggle action and trigger target, and `popover.content` injects the content target.
- `HoverCard` injects parent `ui--hover-card` controller/open state defaults; `hover_card.trigger` and `hover_card.content` inject the required hover/focus actions and targets.
- `Sheet` injects parent `ui--dialog` controller/open state defaults; `sheet.trigger` injects open action and `sheet.content` injects content target/slide transition while rendering overlay target internally.
- `Dialog` injects parent `ui--dialog` controller/open state defaults; `dialog.trigger` injects open action and `dialog.content` injects content target while rendering overlay internally.
- `AlertDialog` injects parent `ui--dialog` controller/open state defaults; `alert_dialog.trigger`, `alert_dialog.content`, `alert_dialog.cancel`, and `alert_dialog.action` inject required dialog actions/targets.

- Use Phlex for reusable UI
- Organize by domain in `app/components/`
- Pass data via arguments
- Compose larger components from smaller ones
- Example: components inherit `Components::Base` (see checklist)

## Views (Patterns)
- Use Phlex for page-level views in `app/views/`
- Rendered by controllers with data passed in
- Compose views using components from `app/components/`
- One view per action (index, show, new, edit, create)
- Example: views inherit `Views::Base` (see checklist)

## I18n (English + Spanish)
- **Always use fully-qualified keys** — `t("admin.articles.index.title")`, never `t(".title")`
- Components read from `components.*` keys
- Model attributes/enums come from `activerecord.*` keys
- Domain-based locale files in `config/locales/en/` and `config/locales/es/`

## Stimulus File Structure

```
app/javascript/
  application.js           # Rails entry point
  controllers/
    application.js         # Base Stimulus controller
    index.js              # Auto-register controllers
    game/
      connection_controller.js
      player_controller.js
      move_controller.js
    ui/
      modal_controller.js
      dropdown_controller.js
      select_controller.js
      button_controller.js
```

## Stimulus Patterns
- One controller per feature
- Use `static targets`, `values`, `outlets`
- Dispatch custom events for loose coupling
- Organize by domain (`game/`, `ui/`)
- Name controllers as `domain--feature` (e.g., `data-controller="game--player"`)
- Register controllers in `index.js` or use auto-registration
- Avoid calling close handlers on initial connect when a component starts closed; do not restore focus or scroll on first render
- Only return focus to triggers after the component has actually been opened at least once

### Interactive Component Pattern
For shadcn UI components requiring interactivity (Switch, Tabs, Accordion, Dropdown, Select, Tooltip, Popover, HoverCard, Dialog), use the standardized pattern:

**Files:**
- Phlex component (static) → receives `data-*` attributes via `**attrs`
- Stimulus controller → manages state, keyboard nav, positioning
- Design system examples → test with interactive demo

**Reference:** See [design-system/references/stimulus-interactive-components.md](../design-system/references/stimulus-interactive-components.md)

### Overlay Positioning Pattern (Dropdown/Select/Tooltip/Popover/HoverCard)
- Use `strategy: 'fixed'` with Floating UI for overlays that can be clipped by parent containers
- Keep overlay hidden while computing position, then show after coordinates are applied
- Avoid `transition-all` on overlay containers because it animates `top/left` and causes position-jump artifacts
- Prefer opacity-only transition for open/close animations

### Stimulus Debugging Hygiene
- Remove temporary `console.log` statements before finalizing changes

**Example Integration:**
```ruby
# Component owns required Stimulus bindings
render Components::Ui::Switch.new(checked: false) do |switch|
  switch.thumb
end

# Controller manages state and updates DOM
export default class extends BaseController {
  static values = { checked: Boolean }
  toggle() { this.checkedValue = !this.checkedValue }
  // Updates data-state → CSS responds via data-[state=checked]:...
}
```

## Stimulus + Phlex Integration
Connect Stimulus to Phlex components via data attributes:

```ruby
# app/components/game/player_card.rb
div(
  data: {
    controller: "game--player",
    game__player_player_id_value: player.id,
    game__player_x_value: player.x,
    game__player_y_value: player.y
  }
) do
  # component content
end
```

## Navigation Helpers (link_to, not anchor elements)

### ✅ **Always Use `link_to` for Navigation**
Never use raw `<a>` (anchor) elements in Phlex views. The `link_to` helper ensures proper Turbo integration, Rails routing, and CSRF protection.

**Usage:**
```ruby
# For standard navigation
link_to "Home", root_path, 
  class: "text-foreground hover:text-muted-foreground",
  data: { turbo_frame: "_top", turbo_action: "advance" }

# Go back to previous page (with fallback)
link_to request.referrer || root_path,
  class: "inline-flex items-center gap-2",
  data: { turbo_frame: "_top" } do
  svg(...) # icon
  span { "Back" }
end

# As a button-like element
link_to "Delete", item_path(item),
  method: :delete,
  data: { turbo_confirm: "Are you sure?" }
```

### ✅ **Block Form for Complex Content**
When wrapping icons, multiple elements, or custom content:
```ruby
link_to user_path(@user),
  class: "flex items-center gap-2 hover:bg-muted rounded p-2" do
  img(src: @user.avatar_url, class: "w-8 h-8 rounded-full")
  div do
    p(class: "font-medium") { @user.name }
    p(class: "text-sm text-muted-foreground") { @user.email }
  end
end
```

### ❌ **Never Use Anchor Elements**
```ruby
# WRONG - Don't use this
a(href: user_path(@user),
  class: "flex items-center") do
  span { "Profile" }
end

# RIGHT - Use link_to instead
link_to user_path(@user),
  class: "flex items-center" do
  span { "Profile" }
end
```

**Benefits of `link_to`:**
- Automatic Turbo Frame handling via `data-*` attributes
- Built-in CSRF token for unsafe methods (DELETE, PATCH)
- Consistent Rails routing
- Proper link helpers (current_page?, etc.)
- Better accessibility and SEO

## Styling
- Tailwind utility classes are the common baseline

> **For verification checklists, see [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md)**


