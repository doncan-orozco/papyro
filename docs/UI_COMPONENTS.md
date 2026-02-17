# shadcn UI Components - Usage Guide

## Overview

This project now includes a complete set of shadcn UI components built with Phlex and Tailwind CSS. All components follow the shadcn Radix UI design system and are fully compatible with the semantic token system.

## Component List

### Form Components
- **Input** - Text input fields
- **Label** - Form labels
- **Textarea** - Multi-line text input
- **Select** - Dropdown select
- **Checkbox** - Checkbox input
- **Radio** - Radio button input
- **Switch** - Toggle switch

### Layout Components
- **Card** - Card container with header, content, and footer
- **Separator** - Horizontal/vertical divider
- **Tabs** - Tabbed navigation
- **Accordion** - Collapsible sections
- **Dialog** - Modal dialogs

### Display Components
- **Button** - Buttons with multiple variants
- **Badge** - Status badges
- **Avatar** - User avatars
- **Alert** - Alert messages
- **Progress** - Progress bars
- **Skeleton** - Loading skeletons
- **Tooltip** - Tooltips

### Navigation Components
- **Dropdown Menu** - Dropdown menus
- **Tabs** - Tab navigation

### Data Display
- **Table** - Data tables

## Basic Usage

### Button

```ruby
# Basic button
render Components::Ui::Button.new { "Click me" }

# With variant
render Components::Ui::Button.new(variant: :destructive) { "Delete" }

# With size
render Components::Ui::Button.new(size: :lg) { "Large Button" }

# With Stimulus
render Components::Ui::Button.new(
  variant: :default,
  data: { action: "click->controller#action" }
) { "Interactive" }
```

**Variants:** `:default`, `:secondary`, `:outline`, `:ghost`, `:destructive`, `:link`  
**Sizes:** `:xs`, `:sm`, `:default`, `:lg`, `:icon`, `:icon-xs`, `:icon-sm`, `:icon-lg`

### Card

```ruby
render Components::Ui::Card.new do
  render Components::Ui::CardHeader.new do
    render Components::Ui::CardTitle.new { "Card Title" }
    render Components::Ui::CardDescription.new { "Description text" }
  end

  render Components::Ui::CardContent.new do
    p { "Main content goes here" }
  end

  render Components::Ui::CardFooter.new do
    render Components::Ui::Button.new { "Action" }
  end
end
```

### Form Components

```ruby
# Input
div(class: "space-y-2") do
  render Components::Ui::Label.new(for: "email") { "Email" }
  render Components::Ui::Input.new(
    id: "email",
    type: :email,
    placeholder: "Enter your email"
  )
end

# Textarea
div(class: "space-y-2") do
  render Components::Ui::Label.new(for: "message") { "Message" }
  render Components::Ui::Textarea.new(
    id: "message",
    placeholder: "Type your message"
  )
end

# Select
div(class: "space-y-2") do
  render Components::Ui::Label.new(for: "role") { "Role" }
  render Components::Ui::Select.new(id: "role") do
    option(value: "admin") { "Admin" }
    option(value: "user") { "User" }
  end
end

# Checkbox
div(class: "flex items-center space-x-2") do
  render Components::Ui::Checkbox.new(id: "terms")
  render Components::Ui::Label.new(for: "terms") { "I agree" }
end

# Radio
div(class: "flex items-center space-x-2") do
  render Components::Ui::Radio.new(id: "option1", name: "choice", value: "1")
  render Components::Ui::Label.new(for: "option1") { "Option 1" }
end

# Switch
div(class: "flex items-center space-x-2") do
  render Components::Ui::Switch.new(
    id: "notifications",
    data: { state: "unchecked" }
  ) do
    render Components::Ui::SwitchThumb.new(data: { state: "unchecked" })
  end
  render Components::Ui::Label.new(for: "notifications") { "Notifications" }
end
```

### Badge

```ruby
render Components::Ui::Badge.new(variant: :default) { "Active" }
render Components::Ui::Badge.new(variant: :secondary) { "Pending" }
render Components::Ui::Badge.new(variant: :destructive) { "Error" }
render Components::Ui::Badge.new(variant: :outline) { "Draft" }
```

**Variants:** `:default`, `:secondary`, `:destructive`, `:outline`

### Alert

```ruby
render Components::Ui::Alert.new(variant: :default) do
  render Components::Ui::AlertTitle.new { "Heads up!" }
  render Components::Ui::AlertDescription.new { "Your message here" }
end

# Destructive alert
render Components::Ui::Alert.new(variant: :destructive) do
  render Components::Ui::AlertTitle.new { "Error" }
  render Components::Ui::AlertDescription.new { "Something went wrong" }
end
```

**Variants:** `:default`, `:destructive`

### Avatar

```ruby
render Components::Ui::Avatar.new do
  render Components::Ui::AvatarImage.new(
    src: "https://example.com/avatar.jpg",
    alt: "User name"
  )
  render Components::Ui::AvatarFallback.new { "JD" }
end
```

### Dialog

```ruby
# Note: Requires Stimulus controller for interactivity
render Components::Ui::DialogOverlay.new(data: { state: "open" })

render Components::Ui::DialogContent.new(data: { state: "open" }) do
  render Components::Ui::DialogHeader.new do
    render Components::Ui::DialogTitle.new { "Are you sure?" }
    render Components::Ui::DialogDescription.new do
      "This action cannot be undone."
    end
  end

  render Components::Ui::DialogFooter.new do
    render Components::Ui::Button.new(variant: :outline) { "Cancel" }
    render Components::Ui::Button.new { "Confirm" }
  end
end
```

### Dropdown Menu

```ruby
# Note: Requires Stimulus controller for interactivity
render Components::Ui::DropdownMenuTrigger.new do
  render Components::Ui::Button.new(variant: :outline) { "Open Menu" }
end

render Components::Ui::DropdownMenuContent.new do
  render Components::Ui::DropdownMenuLabel.new { "My Account" }
  render Components::Ui::DropdownMenuSeparator.new
  render Components::Ui::DropdownMenuItem.new { "Profile" }
  render Components::Ui::DropdownMenuItem.new { "Settings" }
  render Components::Ui::DropdownMenuSeparator.new
  render Components::Ui::DropdownMenuItem.new { "Logout" }
end
```

### Tabs

```ruby
# Note: Requires Stimulus controller for interactivity
render Components::Ui::Tabs.new do
  render Components::Ui::TabsList.new do
    render Components::Ui::TabsTrigger.new(data: { state: "active" }) { "Tab 1" }
    render Components::Ui::TabsTrigger.new { "Tab 2" }
  end

  render Components::Ui::TabsContent.new { "Content for tab 1" }
  render Components::Ui::TabsContent.new { "Content for tab 2" }
end
```

### Accordion

```ruby
# Note: Requires Stimulus controller for interactivity
render Components::Ui::Accordion.new do
  render Components::Ui::AccordionItem.new do
    render Components::Ui::AccordionTrigger.new { "Section 1" }
    render Components::Ui::AccordionContent.new do
      render Components::Ui::AccordionContentInner.new do
        p { "Content for section 1" }
      end
    end
  end

  render Components::Ui::AccordionItem.new do
    render Components::Ui::AccordionTrigger.new { "Section 2" }
    render Components::Ui::AccordionContent.new do
      render Components::Ui::AccordionContentInner.new do
        p { "Content for section 2" }
      end
    end
  end
end
```

### Progress

```ruby
# 33% progress
render Components::Ui::Progress.new(value: 33)

# 66% progress
render Components::Ui::Progress.new(value: 66, max: 100)

# Complete
render Components::Ui::Progress.new(value: 100)
```

### Skeleton

```ruby
# Single skeleton
render Components::Ui::Skeleton.new(class: "h-12 w-12 rounded-full")

# Loading card skeleton
div(class: "space-y-2") do
  render Components::Ui::Skeleton.new(class: "h-4 w-full")
  render Components::Ui::Skeleton.new(class: "h-4 w-3/4")
end
```

### Table

```ruby
render Components::Ui::TableContainer.new do
  render Components::Ui::Table.new do
    render Components::Ui::TableCaption.new { "A list of users" }

    render Components::Ui::TableHeader.new do
      render Components::Ui::TableRow.new do
        render Components::Ui::TableHead.new { "Name" }
        render Components::Ui::TableHead.new { "Email" }
        render Components::Ui::TableHead.new(class: "text-right") { "Role" }
      end
    end

    render Components::Ui::TableBody.new do
      render Components::Ui::TableRow.new do
        render Components::Ui::TableCell.new(class: "font-medium") { "John Doe" }
        render Components::Ui::TableCell.new { "john@example.com" }
        render Components::Ui::TableCell.new(class: "text-right") { "Admin" }
      end
    end
  end
end
```

### Separator

```ruby
# Horizontal separator
render Components::Ui::Separator.new(orientation: :horizontal)

# Vertical separator
render Components::Ui::Separator.new(orientation: :vertical)

# Non-decorative (for screen readers)
render Components::Ui::Separator.new(decorative: false)
```

### Tooltip

```ruby
# Note: Requires Stimulus controller or JavaScript library for positioning
render Components::Ui::TooltipTrigger.new do
  render Components::Ui::Button.new(variant: :outline) { "Hover me" }
end

render Components::Ui::TooltipContent.new do
  p { "Tooltip text here" }
end
```

## Key Features

### 1. Inherits from Components::Base
All components extend `Components::Base`, which provides:
- Helper method includes (Routes, T, TurboFrameTag, FormWith, LinkTo)
- Class merging utilities (`merged_classes`, `attrs_without_class`)

### 2. Stimulus Support
All components support Stimulus via `**attrs`:

```ruby
render Components::Ui::Button.new(
  data: {
    controller: "my-controller",
    action: "click->my-controller#handleClick",
    my_controller_target: "button"
  }
) { "Click me" }
```

### 3. Semantic Color Tokens
Components use semantic tokens that automatically work with dark mode:
- `bg-primary`, `text-primary-foreground`
- `bg-destructive`, `text-destructive`
- `bg-muted`, `text-muted-foreground`
- `border-border`, `border-input`

### 4. Custom Classes
All components support custom classes via the `class:` parameter:

```ruby
render Components::Ui::Button.new(class: "mt-4 mb-2") { "Button" }
```

Custom classes are merged with component base classes automatically.

## Demo Component

To see all components in action, use the demo component:

```ruby
# In a view or controller
render Components::Ui::ComponentsDemo.new
```

This renders a comprehensive showcase of all available components with examples.

## Notes

### Interactive Components
Some components (Dialog, Dropdown Menu, Tabs, Accordion, Tooltip, Switch) require JavaScript for full interactivity. These components are marked with a note in their implementation. You'll need to:

1. Create Stimulus controllers for interactive behavior
2. Use the `data-state` attributes for styling
3. Handle open/close states

### Accessibility
All components include proper ARIA attributes:
- `role` attributes for semantic HTML
- `aria-*` attributes for screen readers
- Keyboard navigation support (where applicable)

### Customization
Components can be customized by:
1. Passing custom classes via `class:` parameter
2. Overriding variant/size options
3. Adding data attributes for Stimulus
4. Extending component classes for project-specific needs

## Best Practices

1. **Always use semantic tokens** - Don't use hardcoded colors like `bg-blue-500`
2. **Combine with domain components** - Use UI components as building blocks in your domain-specific components
3. **Test with dark mode** - Components automatically support dark mode via CSS variables
4. **Add Stimulus when needed** - For interactive components, create appropriate Stimulus controllers
5. **Keep it accessible** - Use proper labels, ARIA attributes, and keyboard support

## Related Documentation

- `.ai/skills/design-system/SKILL.md` - Design system patterns
- `.ai/skills/design-system/references/design-system.md` - Component examples
- `.ai/skills/design-system/references/shadcn-conversion-guide.md` - Conversion process
- `.ai/skills/design-system/references/css-variables-guide.md` - Color system setup
