# Design System Skill (shadcn/ui + Phlex)

## Dependencies
- phlex
- phlex-rails
- tailwindcss-rails

## Overview
Use shadcn/ui design patterns translated to Phlex components. All base UI components live in `app/components/ui/`.

## Base Component Pattern

```ruby
# app/components/ui/button.rb
module Components
  module Ui
    class Button < Phlex::HTML
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
        [
          base_classes,
          variant_classes[@variant],
          size_classes[@size]
        ].compact.join(" ")
      end

      def base_classes
        "inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50"
      end

      def variant_classes
        {
          default: "bg-slate-900 text-slate-50 hover:bg-slate-900/90",
          destructive: "bg-red-500 text-slate-50 hover:bg-red-500/90",
          outline: "border border-slate-200 bg-white hover:bg-slate-100 hover:text-slate-900",
          secondary: "bg-slate-100 text-slate-900 hover:bg-slate-100/80",
          ghost: "hover:bg-slate-100 hover:text-slate-900",
          link: "text-slate-900 underline-offset-4 hover:underline"
        }
      end

      def size_classes
        {
          default: "h-10 px-4 py-2",
          sm: "h-9 rounded-md px-3",
          lg: "h-11 rounded-md px-8",
          icon: "h-10 w-10"
        }
      end
    end
  end
end
```

## Component Generation Rules

1. **Analyze shadcn source** - Extract variants, sizes, states
2. **Map Tailwind classes** - Group by: base, variant, size, state
3. **Parameterize** - Use keyword args for customization
4. **Compose** - Base components compose into domain components
5. **Data attributes** - Support Stimulus via `**attrs`

## Variant System

```ruby
# Always support these parameters:
def initialize(variant: :default, size: :default, disabled: false, **attrs)
  @variant = variant
  @size = size
  @disabled = disabled
  @attrs = attrs
end

# Pass through data attributes for Stimulus:
button(
  class: classes,
  disabled: @disabled,
  **@attrs  # Includes data-controller, data-action, etc.
)
```

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

## Conversion Process

1. **Find shadcn component** (button, card, input, etc.)
2. **Extract variants** from TypeScript/className
3. **Map to Phlex** using hash-based variant system
4. **Add size variants** (sm, default, lg)
5. **Support disabled/states** via boolean flags
6. **Pass through attrs** for Stimulus integration
7. **Test with domain component** to validate composability

## Rules

- All UI components in `app/components/ui/`
- Use keyword args for variants/sizes
- Always support `**attrs` for Stimulus
- Keep components pure (no side effects)
- Document available variants in comments
- Compose UI components into domain components
