---
name: design-system
description: shadcn/ui design patterns translated to Phlex components for consistent UI development. Use when creating or modifying UI components in app/components/ui/. Covers button, card, badge, input, label, and other base component patterns with variants and composition. Includes guidance for pixel-perfect shadcn Radix UI conversion with semantic tokens, class-based dark mode via ui--theme Stimulus controller, and SHADCN_VERSION tracking.
---

# Design System (shadcn/ui + Phlex)

## Dependencies
- phlex
- phlex-rails
- tailwindcss-rails (v4 with OKLCH color space support)

## Tracked Version
The shadcn component library version in use is stored as a constant on the base class:

```ruby
# app/components/base.rb
Components::Base::SHADCN_VERSION  # => "2.3.0"
```

Update this constant when upgrading shadcn components.

## Overview
Use shadcn/ui **Radix UI** design patterns translated to Phlex components. All base UI components live in `app/components/ui/`.

## Catalog Requirement
Maintain the design system catalog in `app/views/design_system/index.rb`.

- Every new UI component or variant must be added to the catalog.
- Add English and Spanish strings in `config/locales/{en,es}/design_system.yml`.
- Keep catalog examples professional and aligned with semantic tokens.

**IMPORTANT:** This project uses shadcn **Radix UI** components (not Base UI). Always verify component specifications from https://ui.shadcn.com when converting.

## Key Principles

### 1. Semantic Color Tokens (NOT Hardcoded Colors)
Always use semantic tokens with Tailwind CSS variables:
- ✅ `bg-primary`, `text-destructive`, `bg-destructive/10`
- ❌ `bg-slate-900`, `bg-red-500`, `text-white`

### 2. OKLCH Color Space (Tailwind v4)
CSS variables use OKLCH format for perceptually uniform colors:
```css
@theme {
  --color-primary: oklch(0.205 0 0);
  --color-destructive: oklch(0.577 0.245 27.325);
}
```
See [references/css-variables-guide.md](references/css-variables-guide.md) for complete setup.

### 3. CSS Variables in :root (Not @theme)
Colors must be defined as CSS custom properties in `:root`, then referenced in `@theme`:
```css
:root {
  --primary: 0.205 0 0;
  --border: 0.88 0 0;

  --color-primary: oklch(var(--primary));
  --color-border: oklch(var(--border));
  --tw-shadow-color: oklch(0 0 0 / 10%);
}

@theme {
  --color-primary: var(--color-primary);  /* Reference, not define */
  --color-border: var(--color-border);
}

html.dark {
  --primary: 0.922 0 0;
  --border: 0.269 0 0;

  --color-primary: oklch(var(--primary));
  --color-border: oklch(var(--border));
  --tw-shadow-color: oklch(0 0 0 / 30%);
}
```
Use `@custom-variant dark (&:where(.dark, .dark *));` with `html.dark` for class-based dark mode.

### 4. Shadow & Elevation Control
Use Tailwind's shadow utilities — they automatically use `--tw-shadow-color`:
```ruby
# Card with subtle shadow (automatic light/dark mode)
"rounded-lg border border-border bg-card text-card-foreground shadow-sm"
```

**How it works:**
- `shadow-sm`, `shadow-md`, `shadow-lg` use `var(--tw-shadow-color)` from CSS
- Light mode: 10% black opacity for subtle elevation
- Dark mode: 30% black opacity for visibility on dark backgrounds
- No additional classes needed — automatic!

### 5. Opacity Modifiers for Subtle Backgrounds
Use `/10`, `/20`, `/40` opacity modifiers for subtle backgrounds:
```ruby
# Destructive variant with subtle background
"bg-destructive/10 hover:bg-destructive/20 text-destructive"
```

### 6. Class-Based Dark Mode
The system uses class-based dark mode (`html.dark`), toggled by the `ui--theme` Stimulus controller:
- `@custom-variant dark (&:where(.dark, .dark *));` in `application.css` enables `dark:` Tailwind prefixes to respond to the `html.dark` class (not OS media query alone)
- `html.dark { }` CSS block in `application.css` overrides all token variables for dark palette
- All semantic colors change instantly when the class is toggled
- Works across all components that use semantic tokens

**`ui--theme` Stimulus controller** (`app/javascript/controllers/ui/theme_controller.js`):
- Reads saved preference from `localStorage("papyro-theme")` on `connect()`
- Falls back to `window.matchMedia("prefers-color-scheme: dark")` when no preference is saved
- Applies `dark` or `light` class on `<html>` and persists the choice to localStorage
- Dispatches `ui--theme:changed` event after each toggle

**Wiring the toggle button in a view:**
```ruby
render Components::Ui::Button.new(
  variant: :outline,
  size: :sm,
  type: :button,
  data: {
    controller: "ui--theme",
    action: "click->ui--theme#toggle",
    ui_theme_dark_label: t("design_system.catalog.toggle_dark"),   # label when switching TO dark
    ui_theme_light_label: t("design_system.catalog.toggle_light")  # label when switching TO light
  }
) do
  span(class: "dark:hidden") { "🌙 #{t("design_system.catalog.dark")}" }
  span(class: "hidden dark:inline") { "☀️ #{t("design_system.catalog.light")}" }
end
```

**Note on ARIA labels:** `ui_theme_dark_label` is shown when the page is currently in light mode (the action being offered is "switch to dark"), and `ui_theme_light_label` is shown when in dark mode (offering "switch to light"). These must NOT be swapped.

Example: `bg-card` shows white in light mode, dark gray in dark mode — same class, no `dark:` needed!

### 7. Radix UI Sizing Standards
- Button default height: `h-8` (32px) - more compact than Base UI
- Border radius: `rounded-lg` (8px)
- Focus ring: `ring-3` (thicker) with opacity modifiers
- Transitions: `transition-all` for smooth animations

## Base Component Pattern

**CRITICAL:** Every component class must have an `initialize(**attrs)` method, including nested child components.

## Compound Component Yielding Convention (MANDATORY FOR ALL MULTI-PART COMPONENTS)

**Applies to: Accordion, Alert, AlertDialog, Avatar, Breadcrumb, Calendar, Card, Carousel, Collapsible, Command, ContextMenu, DataTable, Dialog, Dropdown, Form, HoverCard, MenuBar, NavigationMenu, Pagination, Popover, RadioGroup, Resizable, ScrollArea, Sheet, Table, Tabs, Toast, ToggleGroup**

The parent component yields itself to the view, exposing child render methods. This eliminates `.new` calls and provides a clean, composable API.

### Component Structure

```ruby
# app/components/ui/card.rb
module Components
  module Ui
    class Card < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class) do
          yield self if block
        end
      end

      # Helper methods that views call
      def header(**attrs, &block)
        render Header.new(**attrs, &block)
      end

      def title(**attrs, &block)
        render Title.new(**attrs, &block)
      end

      def description(**attrs, &block)
        render Description.new(**attrs, &block)
      end

      def content(**attrs, &block)
        render Content.new(**attrs, &block)
      end

      def footer(**attrs, &block)
        render Footer.new(**attrs, &block)
      end

      # Nested child classes (one for each part)
      class Header < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          div(class: merged_classes, **attrs_without_class, &block)
        end

        private

        def classes
          "flex flex-col space-y-1.5 p-6"
        end
      end

      class Title < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          h2(class: merged_classes, **attrs_without_class, &block)
        end

        private

        def classes
          "text-2xl font-semibold leading-none tracking-tight"
        end
      end

      # ... other child classes

      # Legacy compatibility aliases (gradual migration)
      CardHeader = Header
      CardTitle = Title
      CardDescription = Description
      CardContent = Content
      CardFooter = Footer
    end
  end
end
```

### Usage in Views

```ruby
# NEW — The standard pattern
render Components::Ui::Card.new(class: "mb-6") do |card|
  card.header do
    card.title { "Settings" }
    card.description { "Manage your account preferences" }
  end
  
  card.content(class: "space-y-4") do
    # form fields...
  end
  
  card.footer do
    render Components::Ui::Button.new { "Save" }
  end
end

# OLD (still works via aliases, but avoid for new code)
render Components::Ui::CardHeader.new do
  render Components::Ui::CardTitle.new { "Settings" }
  render Components::Ui::CardDescription.new { "..." }
end
```

### Why This Pattern

| Aspect | Old Pattern | New Pattern |
|--------|-----------|-----------|
| **Readability** | Nested render calls | Clean method chain (`card.header {...}`) |
| **Type Safety** | Loose (pass any class) | Tight (methods defined on parent) |
| **Defaults** | Per-component defaults | Inherited from parent context if needed |
| **Discoverability** | View docs to find children | IDE autocomplete on parent variable |
| **Testing** | More setup | Simpler parent-only setup |
| **Backward Compat** | N/A | Aliases provided for migration |

### Set Default Stimulus Controller

For interactive components (DropdownMenu, Dialog, Tabs, etc.), inject the default Stimulus controller in `initialize`:

```ruby
def initialize(**attrs)
  @attrs = attrs
  # Set default controller if not already provided by caller
  @attrs[:data] ||= {}
  @attrs[:data][:controller] = "ui--dropdown" unless @attrs[:data][:controller]
end
```

This eliminates boilerplate in views:

```ruby
# View code is cleaner
render Components::Ui::DropdownMenu.new(
  data: { ui__dropdown_placement_value: "bottom-end" }
) do |dropdown|
  dropdown.trigger { "Menu" }
  dropdown.content do
    dropdown.item { "Edit" }
    dropdown.item(variant: :destructive) { "Delete" }
  end
end

# Instead of repeating the controller everywhere
render Components::Ui::DropdownMenu.new(
  data: { controller: "ui--dropdown", ui__dropdown_placement_value: "bottom-end" }
) do |dropdown|
  # ...
end
```

### Required Child Data Defaults (Interactive Compound Components)

For interactive compound components, required `data-*` targets/actions must be injected by parent helper methods. Views should not have to repeat mandatory bindings.

For `DropdownMenu`, enforce these defaults in helper methods:

```ruby
def trigger(**attrs, &block)
  render Trigger.new(
    **with_required_data(attrs, target: "trigger", required_action: "click->ui--dropdown#toggle"),
    &block
  )
end

### ⚠️ Anti-Pattern: Never Nest `Components::Ui::Button` Inside a Compound Trigger

`DropdownMenu::Trigger`, `Dialog::Trigger`, `Sheet::Trigger`, and similar compound trigger helpers **already render a `<button>` element**. Placing `Components::Ui::Button` (which also renders a `<button>`) inside the block creates **invalid HTML** — browsers automatically eject the inner `<button>`, leaving the trigger empty and the icon/content orphaned as a sibling with no Stimulus action binding.

```ruby
# ❌ WRONG — button inside button, trigger renders empty, dropdown never opens
dropdown.trigger do
  render Components::Ui::Button.new(variant: :ghost, size: :icon, class: "size-8") do
    render Components::Ui::Icon.new(:sun)
  end
end

# ✅ CORRECT — pass styling attrs directly to trigger, put content inline
dropdown.trigger(class: "size-8 p-0") do
  render Components::Ui::Icon.new(:sun, class: "size-4 dark:hidden")
  render Components::Ui::Icon.new(:moon, class: "hidden size-4 dark:block")
end
```

**Rule:** The block passed to any compound trigger helper is content *inside* the trigger element. Never wrap it with another interactive element (`Button`, `a`, `label`).

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

Implementation rules:
- Merge `data` hashes; never discard caller-provided `data`.
- Preserve caller actions while appending required actions.
- Required bindings must always be present, even when caller omits `data`.

Also enforce the same rule for other interactive components:

```ruby
# Switch
def view_template(&block)
  dynamic_attrs = attrs_without_class.dup
  dynamic_attrs[:data] = with_required_data(
    dynamic_attrs[:data],
    controller: "ui--switch",
    action: "click->ui--switch#toggle keydown->ui--switch#keydown"
  )
  button(**dynamic_attrs) { yield self if block }
end

def thumb(**attrs, &block)
  render Thumb.new(**with_required_data(attrs, data: { ui__switch_target: "thumb" })), &block
end

# Tabs
def view_template(&block)
  dynamic_attrs = attrs_without_class.dup
  dynamic_attrs[:data] = with_required_data(dynamic_attrs[:data], controller: "ui--tabs")
  div(**dynamic_attrs) { yield self if block }
end

def trigger(**attrs, &block)
  render Trigger.new(
    **with_required_data(attrs, data: { ui__tabs_target: "trigger", action: "click->ui--tabs#select keydown->ui--tabs#keydown" }),
    &block
  )
end

def content(**attrs, &block)
  render Content.new(**with_required_data(attrs, data: { ui__tabs_target: "content" })), &block
end

# Select family
# select.trigger => ui__select_target: "trigger" + toggle/navigate actions
# select.content => ui__select_target: "content"
# select.item => ui__select_target: "item" + selectItem action
# select.value => ui__select_target: "valueDisplay"

# Tooltip family
# tooltip.trigger => ui__tooltip_target: "trigger" + hover/focus show/hide actions
# tooltip.content => ui__tooltip_target: "content"

# Popover family
# parent Popover => controller: "ui--popover" + ui__popover_open_value default
# popover.trigger => ui__popover_target: "trigger" + click->ui--popover#toggle
# popover.content => ui__popover_target: "content"

# HoverCard family
# parent HoverCard => controller: "ui--hover-card" + ui__hover_card_open_value default
# hover_card.trigger => ui__hover_card_target: "trigger" + hover/focus show/hide actions
# hover_card.content => ui__hover_card_target: "content" + hover/focus show/hide actions

# Sheet family
# parent Sheet => controller: "ui--dialog" + ui__dialog_open_value default
# sheet.trigger => action: "click->ui--dialog#open"
# sheet.content => ui__dialog_target: "content" + dialog_transition: "slide"
# sheet.content also renders overlay internally with ui__dialog_target: "overlay"

# Dialog family
# parent Dialog => controller: "ui--dialog" + ui__dialog_open_value default
# dialog.trigger => action: "click->ui--dialog#open"
# dialog.content => ui__dialog_target: "content"
# dialog.content also renders overlay internally with ui__dialog_target: "overlay"

# AlertDialog family
# parent AlertDialog => controller: "ui--dialog" + ui__dialog_open_value default
# alert_dialog.trigger => action: "click->ui--dialog#open"
# alert_dialog.content => ui__dialog_target: "content"
# alert_dialog.content also renders overlay internally with ui__dialog_target: "overlay"
# alert_dialog.cancel / alert_dialog.action => action: "click->ui--dialog#close"
```

### Checklist for New Compound Components

- [ ] Parent class has `initialize(**attrs)` storing to `@attrs`
- [ ] Parent's `view_template` yields `self if block`
- [ ] Each child type has a helper method on parent (e.g., `def item(**attrs, &block)`)
- [ ] Each child is a nested class inheriting `Components::Base`
- [ ] Each nested child class has `initialize(**attrs)` and stores to `@attrs`
- [ ] Each nested child has proper `classes` private method
- [ ] Legacy aliases provided at end of parent class (e.g., `ItemAlias = Item`)
- [ ] Default Stimulus controller injected in parent's `initialize` (if interactive)
- [ ] Design system examples in `app/views/design_system/index.rb` use new yielding pattern
- [ ] All child types documented in design system with variants

```ruby
# app/components/ui/button.rb (Radix UI compliant)
module Components
  module Ui
    class Button < Components::Base
      def initialize(variant: :default, size: :default, **attrs)
        @variant = variant
        @size = size
        @attrs = attrs
      end

      def view_template(&block)
        button(class: classes, **@attrs, &block)
      end

      private

      def classes
        [base_classes, variant_classes[@variant], size_classes[@size]].compact.join(" ")
      end

      def base_classes
        [
          # Layout & interaction
          "inline-flex items-center justify-center whitespace-nowrap",
          "transition-all focus-visible:ring-3",
          "disabled:pointer-events-none disabled:opacity-50",
          # Styling (Radix UI standards)
          "rounded-lg border border-transparent bg-clip-padding",
          "text-sm font-medium outline-none select-none",
          # SVG handling
          "[&_svg:not([class*='size-'])]:size-4 [&_svg]:pointer-events-none shrink-0 [&_svg]:shrink-0",
          # ARIA states
          "aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40",
          "aria-invalid:border-destructive dark:aria-invalid:border-destructive/50"
        ].join(" ")
      end

      def variant_classes
        {
          # Semantic tokens with opacity modifiers
          default: "bg-primary text-primary-foreground hover:bg-primary/90 focus-visible:ring-primary/20 dark:focus-visible:ring-primary/40",
          destructive: "bg-destructive/10 hover:bg-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 text-destructive focus-visible:ring-destructive/20",
          outline: "border-border bg-background text-foreground hover:bg-muted hover:text-foreground dark:border-input dark:hover:bg-muted",
          secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80 dark:bg-secondary dark:hover:bg-secondary/80",
          ghost: "text-foreground hover:bg-muted dark:hover:bg-muted",
          link: "text-foreground underline-offset-4 hover:underline dark:text-foreground"
        }
      end

      def size_classes
        {
          default: "h-8 gap-1.5 px-2.5", # Radix: h-8 (32px)
          xs: "h-6 gap-1 px-2 text-xs",
          sm: "h-8 gap-1.5 px-3",
          lg: "h-10 gap-2 px-4",
          icon: "h-8 w-8"
        }
      end
    end
  end
end
```

## Component Conversion Process

**ALWAYS use this process when converting shadcn components:**

1. **Inspect actual rendered HTML** from https://ui.shadcn.com
   - Open browser DevTools on the live component
   - Copy the rendered HTML and class names (not just the React source)
   - This reveals the ACTUAL implementation with semantic tokens

2. **Extract class patterns** into logical groups:
   - Base classes (layout, transitions, focus states, SVG handlers)
   - Variant classes (default, destructive, outline, etc.)
   - Size classes (xs, sm, default, lg, icon)
   - State classes (disabled, aria-invalid, hover, focus)

3. **Map to Ruby hash structure**:
   - `base_classes` = Array or string of shared classes
   - `variant_classes` = Hash mapping symbols to class strings
   - `size_classes` = Hash mapping symbols to class strings

4. **Preserve ALL shadcn features**:
   - ✅ SVG handling: `[&_svg]:size-4`, `[&_svg]:pointer-events-none`
   - ✅ ARIA states: `aria-invalid:ring-3`, `aria-invalid:border-destructive`
   - ✅ Icon spacing: `has-data-[icon=inline-end]:pr-2`
   - ✅ Opacity modifiers: `/10`, `/20`, `/40` for subtle backgrounds
   - ✅ Dark mode: `dark:` prefixes for theme support

5. **Verify Radix UI specifics**:
   - Button height: `h-8` (32px) NOT `h-10` (40px - that's Base UI)
   - Border radius: `rounded-lg` (8px) NOT `rounded-md` (6px)
   - Focus ring: `ring-3` NOT `ring-2`
   - Transition: `transition-all` NOT `transition-colors`

6. **Set up CSS variables** (if not already done):
   - See [references/css-variables-guide.md](references/css-variables-guide.md)
   - Use OKLCH format from official shadcn documentation
   - Define both light and dark mode values

7. **Test visual match**:
   - Compare rendered output side-by-side with shadcn
   - Check height, padding, border-radius, colors, focus states
   - Test all variants (default, destructive, outline, etc.)
   - Test dark mode

**Detailed conversion guide:** [references/shadcn-conversion-guide.md](references/shadcn-conversion-guide.md)

## Variant System

All UI components inherit class merging helpers from `Components::Base`:

```ruby
# Standard parameters for variants & sizing:
def initialize(variant: :default, size: :default, disabled: false, **attrs)
  @variant = variant
  @size = size
  @disabled = disabled
  @attrs = attrs  # Includes data-controller, data-action, class, etc.
end

# Components inherit these from Components::Base (don't redefine):
# - merged_classes   = combines component classes + custom classes
# - attrs_without_class = passes attrs except :class to prevent duplication

def view_template(&block)
  button(class: merged_classes, **attrs_without_class, &block)
end

private

def classes
  "inline-flex items-center justify-center rounded-lg"
end
```

**Base class implementation handles:**
- ✅ Merging component base classes with custom classes
- ✅ Custom classes take precedence (shadcn behavior)
- ✅ No duplicate class attributes
- ✅ DRY principle - shared across all components

## Common Pitfalls (Avoid These)

❌ **`<p>` tags inside `TableCell`**
Block-level `<p>` elements disrupt `TableCell`'s built-in `align-middle`. Never wrap cell content in a paragraph element.
```ruby
# WRONG — p creates a block box that fights align-middle
render Components::Ui::TableCell.new { p(class: "font-medium") { item.name } }

# CORRECT — class on the cell itself, plain text inside
render Components::Ui::TableCell.new(class: "font-medium") { item.name }

# CORRECT — span.block for truncated multi-line content
render Components::Ui::TableCell.new { span(class: "block line-clamp-2 max-w-[36ch]") { item.excerpt } }
```

❌ **Overriding `align-middle` on `TableCell`**
`align-middle` is the shadcn default. Do NOT add `align-top` unless there is an explicit design reason.

❌ **Separate header div outside the Card**
The standard shadcn pattern puts the page title, description, and primary action button all inside `CardHeader`, not in a standalone div above the card.

❌ **Nested Card for empty state**
The empty state should render inside the same `CardContent` as the table — not as a second Card.


```ruby
# WRONG - Don't do this, it's inherited from Components::Base
def merged_classes
  [classes, @attrs[:class]].compact.join(" ")
end

def attrs_without_class
  @attrs.except(:class)
end

# CORRECT - Just use them (inherited)
def view_template(&block)
  button(class: merged_classes, **attrs_without_class, &block)
end
```

❌ **Restoring focus on initial connect for closed overlays**
- This can scroll the page to a trigger on load and cause a jumpy layout
- Guard close handlers so they do not restore focus unless the component has actually opened
- Use a `hasInitialized` or `hasOpened` flag in Stimulus controllers

❌ **Hardcoded colors instead of semantic tokens**
```ruby
"bg-slate-900 text-white"  # WRONG
"bg-primary text-primary-foreground"  # CORRECT
```

❌ **Wrong sizing (Base UI instead of Radix UI)**
```ruby
"h-10 rounded-md"  # Base UI - WRONG for Radix
"h-8 rounded-lg"   # Radix UI - CORRECT
```

❌ **Missing opacity modifiers for subtle backgrounds**
```ruby
"bg-red-500 text-white"  # Harsh, wrong
"bg-destructive/10 text-destructive"  # Subtle, correct
```

❌ **Incomplete feature preservation**
```ruby
# Missing SVG handling, ARIA states, icon spacing
"inline-flex items-center"  # INCOMPLETE

# Complete with all features
[
  "inline-flex items-center justify-center",
  "[&_svg:not([class*='size-'])]:size-4",
  "aria-invalid:ring-3 aria-invalid:ring-destructive/20",
  "has-data-[icon=inline-end]:pr-2"
].join(" ")  # CORRECT
```

❌ **CSS colors defined in @theme instead of :root**
```css
/* WRONG - Defining fixed values in @theme */
@theme {
  --color-primary: oklch(0.205 0 0);
  --color-card: oklch(1 0 0);
}

/* CORRECT - Uses base tokens + wrapped tokens + html.dark overrides */
:root {
  --primary: 0.205 0 0;
  --card: 1 0 0;

  --color-primary: oklch(var(--primary));
  --color-card: oklch(var(--card));
  --tw-shadow-color: oklch(0 0 0 / 10%);
}

@theme {
  --color-primary: var(--color-primary);
  --color-card: var(--color-card);
}

html.dark {
  --primary: 0.922 0 0;
  --card: 0.205 0 0;

  --color-primary: oklch(var(--primary));
  --color-card: oklch(var(--card));
  --tw-shadow-color: oklch(0 0 0 / 30%);
}
```

## Reference Files

**Load these as needed during conversion:**

- **[references/design-system.md](references/design-system.md)** - Complete shadcn → Phlex examples (button, card, **table**, badge, etc.) — includes Table anatomy, cell rules, dropdown-per-row pattern, and the Card+Table page layout
- **[references/shadcn-conversion-guide.md](references/shadcn-conversion-guide.md)** - Step-by-step conversion process with troubleshooting
- **[references/css-variables-guide.md](references/css-variables-guide.md)** - OKLCH color setup for Tailwind v4

**When to load each reference:**
- Converting a new component? → Load `shadcn-conversion-guide.md` first
- Need an example? → Load `design-system.md`
- Setting up colors/theming? → Load `css-variables-guide.md`

## File Organization

```
app/components/ui/
  button.rb
  card.rb
  input.rb
  badge.rb
  avatar.rb
  dialog.rb
  dropdown.rb
  separator.rb
  label.rb
```

## Usage in Domain Components

```ruby
# app/components/game/player_card.rb
module Components
  module Game
    class PlayerCard < Phlex::HTML
      def initialize(player:)
        @player = player
      end

      def view_template
        render Components::Ui::Card.new do
          div(class: "flex items-center gap-4") do
            render Components::Ui::Avatar.new(
              src: @player.avatar_url,
              alt: @player.name
            )
            
            div(class: "flex-1") do
              h3(class: "font-semibold") { @player.name }
              p(class: "text-sm text-slate-500") { "Level #{@player.level}" }
            end
            
            render Components::Ui::Button.new(
              variant: :outline,
              size: :sm
            ) { "View" }
          end
        end
      end
    end
  end
end
```

## Interactive Components (Switch, Tabs, Accordion, Dropdown, Tooltip, Dialog)

For components that require JavaScript interactivity (state management, keyboard navigation, positioning), use the **Stimulus controller pattern**. See [references/stimulus-interactive-components.md](references/stimulus-interactive-components.md) for the complete guide.

### Pattern Summary
1. **Phlex Component** — Pure markup + semantic tokens, receives `data-*` attributes via `**attrs`
2. **Stimulus Controller** — Manages state, targets, actions, keyboard nav, and positioning
3. **Design System Examples** — Fully wired interactive examples in `app/views/design_system/index.rb`

### Quick Checklist
- ✅ Component passes `**attrs` including `data-controller`, `data-action`, `data-targets`
- ✅ Controller has `static values`, `static targets`, `connect()`, and expected actions
- ✅ Controller updates `data-state` for CSS styling (not class mutations)
- ✅ ARIA attributes updated: `aria-selected`, `aria-expanded`, `aria-checked`, etc.
- ✅ Keyboard navigation: Arrow keys (Tabs/Accordion), Escape (modals), Tab focus management
- ✅ Custom events dispatched for loose coupling: `ui:switch:changed`, `ui:dialog:closed`, etc.
- ✅ Importmap configured for Floating UI (`@floating-ui/dom`) if needed
- ✅ Base controller pinned explicitly: `pin "controllers/ui/base_controller"`
- ✅ Design system view has interactive examples (copy-paste ready)

### Currently Implemented
- **Switch** — Toggle on/off with click or Space/Enter, form integration
- **Tabs** — Tab switching with arrow key navigation, ARIA updates
- **Accordion** — Expand/collapse with arrow key navigation, smooth height transitions
- **Dropdown** — Menu with keyboard navigation, Floating UI positioning, click-outside
- **Tooltip** — Hover/focus trigger with delay, Floating UI margin-aware positioning
- **Dialog** — Modal with focus trap, scroll lock, overlay click to close, ESC key
- **Theme** (`ui--theme`) — Dark/light toggle: applies class on `<html>`, persists to localStorage, falls back to OS preference
  
  - Controller now keeps logic tiny: showElement/unhide then flip `data-state` in `requestAnimationFrame`,
    `hideElement` waits on `animationend` and never touches opacity or transforms directly.  Tailwind utilities
    handle all animation durations (`data-[state=open]:duration-500`, `:animate-in`, etc.).

  - Duration helpers have been added to the Ruby components so closing/opening is
    visibly animated; avoid timeouts or manual styling in JS.

  - The pattern is now generic and can be copied to other overlay-like controllers (sheet, alert-dialog, etc.).

All controllers use shared utilities from `base_controller.js` (focus management, state helpers, event dispatching).

## Conversion Process (Example)

1. Find shadcn component (button, card, input, etc.)
2. Extract variants from TypeScript/className
3. Map to Phlex using hash-based variant system
4. Add size variants (sm, default, lg)
5. Support disabled/states via boolean flags
6. Pass through attrs for Stimulus integration
7. For interactive components: Create Stimulus controller with state, targets, keyboard handling
8. Test with design system examples — copy from `app/views/design_system/index.rb`

## Testing UI Components

### Design System Page (http://localhost:3030/design-system)
After implementing a new UI component or Stimulus controller:

1. **Add to design system:**
   - Edit `app/views/design_system/index.rb`
   - Add example under appropriate section (Buttons, Forms, Interactive, etc.)
   - Wire Stimulus `data-*` attributes: `data-controller="ui--{name}"`, `data-ui__{name}_{prop}_value`

2. **Verify browser console** (`Cmd+F12` or `Cmd+Opt+J`):
   - ✅ No JavaScript errors
   - ✅ No "Failed to register controller" messages

3. **Test component behavior:**
   - Click interactions work
   - Keyboard navigation works (Arrow keys, Tab, Escape, Space/Enter)
   - ARIA attributes update (`aria-expanded`, `aria-selected`, `aria-checked`)
   - States visible (hover, focus, active, disabled)
   - Dark mode switches automatically (if using semantic tokens)

4. **Troubleshooting:**
   - **"Failed to register controller: ui--{name}"** → Check JavaScript for syntax errors (no escaped newlines in comments)
   - **Controller not connecting** → Verify `data-controller` attribute matches filename, check import map
   - **Component renders but no interaction** → Verify all `static targets` and `values` listed in JavaScript
   - **ArgumentError on page load** → Check the component file has `initialize(**attrs)` method on ALL classes
   - **Styling issues** → Use semantic tokens (`bg-primary`), not hardcoded colors (`bg-slate-900`)

### Critical Checks Before Committing
- ✅ All UI component classes have `initialize(**attrs)` method
- ✅ Stimulus controller file has ZERO syntax errors (multiline comments use real newlines, not `\n`)
- ✅ Component wired in design system with correct `data-controller` and `data-*-value` attributes
- ✅ Browser console shows 0 JavaScript errors and connection logs for new controller
- ✅ All keyboard navigation works as per Radix UI spec
- ✅ ARIA attributes properly set and updated

## References

- [shadcn-conversion-guide.md](references/shadcn-conversion-guide.md) — Complete step-by-step guide for converting React shadcn components to Phlex
- [stimulus-interactive-components.md](references/stimulus-interactive-components.md) — Pattern for building interactive components with Stimulus (Switch, Tabs, Accordion, etc.)
- [css-variables-guide.md](references/css-variables-guide.md) — Tailwind CSS v4 OKLCH color space and semantic tokens
- [design-system.md](references/design-system.md) — Design system principles and component organization

## Examples

- [interactive-components-examples.md](examples/interactive-components-examples.md) — Copy-paste ready code for all 6 implemented interactive components (Switch, Tabs, Accordion, Dropdown, Tooltip, Dialog)

## Checklist Reference

Rules live in the checklist:
- [Frontend](../../VERIFICATION_CHECKLIST.md)
