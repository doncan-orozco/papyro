---
name: design-system
description: shadcn/ui design patterns translated to Phlex components for consistent UI development. Use when creating or modifying UI components in app/components/ui/. Covers button, card, badge, input, label, and other base component patterns with variants and composition. Includes guidance for pixel-perfect shadcn Radix UI conversion with semantic tokens.
---

# Design System (shadcn/ui + Phlex)

## Dependencies
- phlex
- phlex-rails
- tailwindcss-rails (v4 with OKLCH color space support)

## Overview
Use shadcn/ui **Radix UI** design patterns translated to Phlex components. All base UI components live in `app/components/ui/`.

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
  --color-primary: oklch(0.205 0 0);  /* Light mode */
  --tw-shadow-color: oklch(0 0 0 / 10%);
}

@theme {
  --color-primary: var(--color-primary);  /* Reference, not define */
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-primary: oklch(0.922 0 0);  /* Dark mode override */
    --tw-shadow-color: oklch(0 0 0 / 30%);
  }
}
```
This pattern enables automatic dark mode switching without `dark:` prefixes.

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

### 6. Dark Mode Automatic Switching
No `dark:` classes needed! The system uses `@media (prefers-color-scheme: dark)`:
- User toggles dark mode in OS settings
- Browser applies media query automatically
- `:root` variables override automatically
- All semantic colors change instantly
- Works across all components

Example: `bg-card` shows white in light mode, dark gray in dark mode — same class!

### 7. Radix UI Sizing Standards
- Button default height: `h-8` (32px) - more compact than Base UI
- Border radius: `rounded-lg` (8px)
- Focus ring: `ring-3` (thicker) with opacity modifiers
- Transitions: `transition-all` for smooth animations

## Base Component Pattern

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

❌ **Redefining merged_classes in every component**
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
/* WRONG - Dark mode won't switch colors */
@theme {
  --color-primary: oklch(0.205 0 0);
  --color-card: oklch(1 0 0);
}

/* CORRECT - Uses :root + override in @media */
:root {
  --color-primary: oklch(0.205 0 0);
  --color-card: oklch(1 0 0);
  --tw-shadow-color: oklch(0 0 0 / 10%);
}

@theme {
  --color-primary: var(--color-primary);
  --color-card: var(--color-card);
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-primary: oklch(0.922 0 0);
    --color-card: oklch(0.205 0 0);
    --tw-shadow-color: oklch(0 0 0 / 30%);
  }
}
```

## Reference Files

**Load these as needed during conversion:**

- **[references/design-system.md](references/design-system.md)** - Complete shadcn → Phlex examples (button, card, input, badge, etc.)
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

## Conversion Process (Example)

1. Find shadcn component (button, card, input, etc.)
2. Extract variants from TypeScript/className
3. Map to Phlex using hash-based variant system
4. Add size variants (sm, default, lg)
5. Support disabled/states via boolean flags
6. Pass through attrs for Stimulus integration
7. Test with a domain component to validate composability

## Checklist Reference

Rules live in the checklist:
- [Frontend](../../VERIFICATION_CHECKLIST.md#-frontend)
