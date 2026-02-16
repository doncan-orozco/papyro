# Design System Examples (shadcn/ui → Phlex)

Complete examples converting shadcn/ui components to Phlex.

## Button Component

### shadcn/ui Source (React)

```tsx
const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-white transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-950 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-slate-900 text-slate-50 hover:bg-slate-900/90",
        destructive: "bg-red-500 text-slate-50 hover:bg-red-500/90",
        outline: "border border-slate-200 bg-white hover:bg-slate-100",
        secondary: "bg-slate-100 text-slate-900 hover:bg-slate-100/80",
        ghost: "hover:bg-slate-100 hover:text-slate-900",
        link: "text-slate-900 underline-offset-4 hover:underline",
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-9 rounded-md px-3",
        lg: "h-11 rounded-md px-8",
        icon: "h-10 w-10",
      },
    },
  }
)
```

### Phlex Translation

```ruby
# app/components/ui/button.rb
module Components
  module Ui
    class Button < Phlex::HTML
      def initialize(variant: :default, size: :default, disabled: false, type: :button, **attrs)
        @variant = variant
        @size = size
        @disabled = disabled
        @type = type
        @attrs = attrs
      end

      def view_template(&block)
        button(
          type: @type,
          class: classes,
          disabled: @disabled,
          **@attrs,
          &block
        )
      end

      private

      def classes
        [base_classes, variant_classes[@variant], size_classes[@size]].compact.join(" ")
      end

      def base_classes
        "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-white transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-950 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50"
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

### Usage

```ruby
# In a view or component
render Components::Ui::Button.new(variant: :default, size: :default) { "Click me" }
render Components::Ui::Button.new(variant: :destructive) { "Delete" }
render Components::Ui::Button.new(variant: :outline, size: :sm) { "Cancel" }

# With Stimulus
render Components::Ui::Button.new(
  variant: :default,
  data: { action: "click->game--player#attack" }
) { "Attack" }
```

## Card Component

### shadcn/ui Source

```tsx
const Card = ({ className, ...props }) => (
  <div className={cn("rounded-lg border bg-card text-card-foreground shadow-sm", className)} {...props} />
)

const CardHeader = ({ className, ...props }) => (
  <div className={cn("flex flex-col space-y-1.5 p-6", className)} {...props} />
)

const CardTitle = ({ className, ...props }) => (
  <h3 className={cn("text-2xl font-semibold leading-none tracking-tight", className)} {...props} />
)

const CardContent = ({ className, ...props }) => (
  <div className={cn("p-6 pt-0", className)} {...props} />
)
```

### Phlex Translation

```ruby
# app/components/ui/card.rb
module Components
  module Ui
    class Card < Phlex::HTML
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          class: "rounded-lg border bg-card text-card-foreground shadow-sm",
          **@attrs,
          &block
        )
      end
    end

    class CardHeader < Phlex::HTML
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: "flex flex-col space-y-1.5 p-6", **@attrs, &block)
      end
    end

    class CardTitle < Phlex::HTML
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        h3(
          class: "text-2xl font-semibold leading-none tracking-tight",
          **@attrs,
          &block
        )
      end
    end

    class CardContent < Phlex::HTML
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: "p-6 pt-0", **@attrs, &block)
      end
    end
  end
end
```

### Usage

```ruby
render Components::Ui::Card.new do
  render Components::Ui::CardHeader.new do
    render Components::Ui::CardTitle.new { "Player Stats" }
  end
  
  render Components::Ui::CardContent.new do
    p { "Level 42" }
    p { "HP: 1000" }
  end
end
```

## Input Component

### shadcn/ui Source

```tsx
const Input = ({ className, type, ...props }) => {
  return (
    <input
      type={type}
      className={cn(
        "flex h-10 w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm ring-offset-white file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-slate-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-950 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50",
        className
      )}
      {...props}
    />
  )
}
```

### Phlex Translation

```ruby
# app/components/ui/input.rb
module Components
  module Ui
    class Input < Phlex::HTML
      def initialize(type: :text, disabled: false, **attrs)
        @type = type
        @disabled = disabled
        @attrs = attrs
      end

      def view_template
        input(
          type: @type,
          class: classes,
          disabled: @disabled,
          **@attrs
        )
      end

      private

      def classes
        "flex h-10 w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm ring-offset-white file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-slate-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-950 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
      end
    end
  end
end
```

### Usage

```ruby
render Components::Ui::Input.new(
  type: :text,
  placeholder: "Enter player name",
  name: "player[name]"
)

# With Stimulus
render Components::Ui::Input.new(
  type: :text,
  data: {
    controller: "game--player",
    action: "input->game--player#updateName"
  }
)
```

## Alert Component

### shadcn/ui Source (summary)

```tsx
const alertVariants = cva(
  "relative w-full rounded-lg border p-4",
  { variants: { variant: { default: "bg-background", destructive: "border-red-500/50 text-red-600" } } }
)
```

### Phlex Translation

```ruby
# app/components/ui/alert.rb
module Components
  module Ui
    class Alert < Phlex::HTML
      def initialize(variant: :default, **attrs)
        @variant = variant
        @attrs = attrs
      end

      def view_template(&block)
        div(class: classes, role: "alert", **@attrs, &block)
      end

      private

      def classes
        [base_classes, variant_classes[@variant]].compact.join(" ")
      end

      def base_classes
        "relative w-full rounded-lg border p-4"
      end

      def variant_classes
        {
          default: "bg-background text-foreground",
          destructive: "border-red-500/50 text-red-600 dark:border-red-500/50"
        }
      end
    end

    class AlertTitle < Phlex::HTML
      def view_template(&block)
        h5(class: "mb-1 font-medium leading-none tracking-tight", &block)
      end
    end

    class AlertDescription < Phlex::HTML
      def view_template(&block)
        div(class: "text-sm text-muted-foreground", &block)
      end
    end
  end
end
```

### Usage

```ruby
render Components::Ui::Alert.new do
  render Components::Ui::AlertTitle.new { "Heads up!" }
  render Components::Ui::AlertDescription.new { "Your session will expire soon." }
end

render Components::Ui::Alert.new(variant: :destructive) do
  render Components::Ui::AlertTitle.new { "Error" }
  render Components::Ui::AlertDescription.new { "Payment failed. Try again." }
end
```

## Dropdown Component

### shadcn/ui Source (summary)

```tsx
<DropdownMenu>
  <DropdownMenuTrigger>Open</DropdownMenuTrigger>
  <DropdownMenuContent>
    <DropdownMenuItem>Profile</DropdownMenuItem>
    <DropdownMenuSeparator />
    <DropdownMenuItem>Log out</DropdownMenuItem>
  </DropdownMenuContent>
</DropdownMenu>
```

### Phlex Translation

```ruby
# app/components/ui/dropdown.rb
module Components
  module Ui
    class Dropdown < Phlex::HTML
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: "relative inline-block text-left", **@attrs, &block)
      end
    end

    class DropdownTrigger < Phlex::HTML
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        button(
          type: :button,
          class: "inline-flex items-center",
          **@attrs,
          &block
        )
      end
    end

    class DropdownContent < Phlex::HTML
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          class: "absolute right-0 z-10 mt-2 w-56 rounded-md border bg-background shadow-md",
          **@attrs,
          &block
        )
      end
    end

    class DropdownItem < Phlex::HTML
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          class: "flex cursor-pointer items-center px-3 py-2 text-sm hover:bg-muted",
          **@attrs,
          &block
        )
      end
    end

    class DropdownSeparator < Phlex::HTML
      def view_template
        div(class: "my-1 h-px bg-border")
      end
    end
  end
end
```

### Usage (with Stimulus)

```ruby
render Components::Ui::Dropdown.new(data: { controller: "ui--dropdown" }) do
  render Components::Ui::DropdownTrigger.new(
    data: { action: "click->ui--dropdown#toggle" }
  ) { "Options" }

  render Components::Ui::DropdownContent.new(
    data: { ui__dropdown_target: "content" },
    class: "hidden"
  ) do
    render Components::Ui::DropdownItem.new { "Profile" }
    render Components::Ui::DropdownSeparator.new
    render Components::Ui::DropdownItem.new { "Log out" }
  end
end
```

## Badge Component

### shadcn/ui Source

```tsx
const badgeVariants = cva(
  "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-slate-950 focus:ring-offset-2",
  {
    variants: {
      variant: {
        default: "border-transparent bg-slate-900 text-slate-50 hover:bg-slate-900/80",
        secondary: "border-transparent bg-slate-100 text-slate-900 hover:bg-slate-100/80",
        destructive: "border-transparent bg-red-500 text-slate-50 hover:bg-red-500/80",
        outline: "text-slate-950",
      },
    },
  }
)
```

### Phlex Translation

```ruby
# app/components/ui/badge.rb
module Components
  module Ui
    class Badge < Phlex::HTML
      def initialize(variant: :default, **attrs)
        @variant = variant
        @attrs = attrs
      end

      def view_template(&block)
        div(class: classes, **@attrs, &block)
      end

      private

      def classes
        [base_classes, variant_classes[@variant]].compact.join(" ")
      end

      def base_classes
        "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-slate-950 focus:ring-offset-2"
      end

      def variant_classes
        {
          default: "border-transparent bg-slate-900 text-slate-50 hover:bg-slate-900/80",
          secondary: "border-transparent bg-slate-100 text-slate-900 hover:bg-slate-100/80",
          destructive: "border-transparent bg-red-500 text-slate-50 hover:bg-red-500/80",
          outline: "text-slate-950"
        }
      end
    end
  end
end
```

### Usage

```ruby
render Components::Ui::Badge.new(variant: :default) { "Active" }
render Components::Ui::Badge.new(variant: :destructive) { "Critical" }
render Components::Ui::Badge.new(variant: :outline) { "Level 42" }
```

## Avatar Component

### shadcn/ui Source

```tsx
const Avatar = ({ className, ...props }) => (
  <div className={cn("relative flex h-10 w-10 shrink-0 overflow-hidden rounded-full", className)} {...props} />
)

const AvatarImage = ({ className, ...props }) => (
  <img className={cn("aspect-square h-full w-full", className)} {...props} />
)

const AvatarFallback = ({ className, ...props }) => (
  <div className={cn("flex h-full w-full items-center justify-center rounded-full bg-slate-100", className)} {...props} />
)
```

### Phlex Translation

```ruby
# app/components/ui/avatar.rb
module Components
  module Ui
    class Avatar < Phlex::HTML
      def initialize(src: nil, alt: "", fallback: nil, size: :default, **attrs)
        @src = src
        @alt = alt
        @fallback = fallback
        @size = size
        @attrs = attrs
      end

      def view_template
        div(class: container_classes, **@attrs) do
          if @src
            img(src: @src, alt: @alt, class: "aspect-square h-full w-full object-cover")
          else
            div(class: "flex h-full w-full items-center justify-center rounded-full bg-slate-100 text-slate-600 font-semibold") do
              plain @fallback || @alt[0]&.upcase || "?"
            end
          end
        end
      end

      private

      def container_classes
        [
          "relative flex shrink-0 overflow-hidden rounded-full",
          size_classes[@size]
        ].compact.join(" ")
      end

      def size_classes
        {
          sm: "h-8 w-8",
          default: "h-10 w-10",
          lg: "h-16 w-16",
          xl: "h-24 w-24"
        }
      end
    end
  end
end
```

### Usage

```ruby
render Components::Ui::Avatar.new(
  src: player.avatar_url,
  alt: player.name,
  size: :default
)

render Components::Ui::Avatar.new(
  fallback: "JD",
  size: :lg
)
```

## Conversion Checklist

When converting shadcn component to Phlex:

1. ✅ Extract all variants from `cva()` definition
2. ✅ Map each variant to Ruby hash with Tailwind classes
3. ✅ Add `size` parameter if multiple sizes exist
4. ✅ Support `disabled` state for interactive elements
5. ✅ Always include `**attrs` for Stimulus/data attributes
6. ✅ Use `&block` for component children/content
7. ✅ Keep class composition logic in private methods
8. ✅ Test composition with domain components
