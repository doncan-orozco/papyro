# Interactive Component Examples (Copy-Paste Ready)

Complete working examples for all implemented Stimulus-powered UI components.

## 1. Switch Component

### Phlex Component
```ruby
# app/components/ui/switch.rb
module Components
  module Ui
    class Switch < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        button(
          type: :button,
          role: :switch,
          class: merged_classes,
          **attrs_without_class
        ) { yield if block_given? }
      end

      private

      def classes
        [
          "peer inline-flex h-5 w-9 shrink-0 cursor-pointer",
          "items-center rounded-full border-2 border-transparent shadow-sm",
          "transition-colors focus-visible:outline-none focus-visible:ring-2",
          "focus-visible:ring-ring focus-visible:ring-offset-2",
          "focus-visible:ring-offset-background disabled:cursor-not-allowed",
          "disabled:opacity-50 data-[state=checked]:bg-primary",
          "data-[state=unchecked]:bg-input"
        ].join(" ")
      end
    end
  end
end

class SwitchThumb < Components::Base
  def initialize(**attrs)
    @attrs = attrs
  end

  def view_template
    span(
      class: "pointer-events-none block h-4 w-4 rounded-full bg-background",
      **attrs_without_class
    )
  end
end
```

### Stimulus Controller
```javascript
// app/javascript/controllers/ui/switch_controller.js
import BaseController from "controllers/ui/base_controller"

export default class extends BaseController {
  static values = {
    checked: { type: Boolean, default: false },
    disabled: { type: Boolean, default: false }
  }
  static targets = ["thumb", "input"]

  connect() {
    console.log('🔘 Switch toggle clicked')
  }

  toggle(event) {
    event?.preventDefault()
    if (this.disabledValue) return
    this.checkedValue = !this.checkedValue
  }

  checkedValueChanged() {
    const state = this.checkedValue ? 'checked' : 'unchecked'
    this.element.dataset.state = state
    this.element.setAttribute('aria-checked', this.checkedValue)
    
    if (this.hasThumbTarget) {
      this.thumbTarget.dataset.state = state
    }
    
    if (this.hasInputTarget) {
      this.inputTarget.checked = this.checkedValue
    }
  }
}
```

### Usage in Design System
```ruby
# app/views/design_system/index.rb
render Components::Ui::Switch.new(
  data: {
    controller: "ui--switch",
    ui__switch_checked_value: false,
    action: "click->ui--switch#toggle"
  }
) do
  render Components::Ui::SwitchThumb.new(
    data: { "ui--switch-target": "thumb" }
  )
end
```

---

## 2. Tabs Component

### Phlex Components
```ruby
# app/components/ui/tabs.rb
class Tabs < Components::Base
  def initialize(**attrs)
    @attrs = attrs
  end

  def view_template
    div(class: "w-full", **attrs_without_class) { yield }
  end
end

class TabsList < Components::Base
  def view_template
    div(
      role: :tablist,
      class: "inline-flex h-9 items-center justify-center rounded-lg bg-muted p-1 text-muted-foreground"
    ) { yield }
  end
end

class TabsTrigger < Components::Base
  def view_template
    button(
      type: :button,
      role: :tab,
      class: "inline-flex items-center justify-center whitespace-nowrap rounded-md px-3 py-1 " +
             "text-sm font-medium ring-offset-background transition-all focus-visible:outline-none " +
             "focus-visible:ring-3 focus-visible:ring-ring/20 disabled:pointer-events-none " +
             "disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground " +
             "data-[state=active]:shadow",
      **attrs_without_class
    ) { yield }
  end
end

class TabsContent < Components::Base
  def view_template
    div(
      role: :tabpanel,
      class: "mt-2 ring-offset-background focus-visible:outline-none focus-visible:ring-2 " +
             "focus-visible:ring-ring focus-visible:ring-offset-2",
      **attrs_without_class
    ) { yield }
  end
end
```

### Stimulus Controller
```javascript
// app/javascript/controllers/ui/tabs_controller.js
import BaseController from "controllers/ui/base_controller"

export default class extends BaseController {
  static values = {
    activeIndex: { type: Number, default: 0 },
    orientation: { type: String, default: 'horizontal' }
  }
  static targets = ["trigger", "content"]

  connect() {
    console.log('📑 Tabs select clicked', {
      triggers: this.triggerTargets.length,
      contents: this.contentTargets.length
    })
    this.updateActive()
  }

  select(event) {
    event?.preventDefault()
    const index = this.triggerTargets.indexOf(event.currentTarget)
    if (index >= 0) this.activeIndexValue = index
  }

  keydown(event) {
    const { ArrowRight, ArrowLeft, Home, End } = {
      ArrowRight: event.key === 'ArrowRight',
      ArrowLeft: event.key === 'ArrowLeft',
      Home: event.key === 'Home',
      End: event.key === 'End'
    }

    if (ArrowRight || ArrowLeft || Home || End) {
      event.preventDefault()
      let newIndex = this.activeIndexValue

      if (ArrowRight) newIndex = (newIndex + 1) % this.triggerTargets.length
      if (ArrowLeft) newIndex = (newIndex - 1 + this.triggerTargets.length) % this.triggerTargets.length
      if (Home) newIndex = 0
      if (End) newIndex = this.triggerTargets.length - 1

      this.activeIndexValue = newIndex
      this.triggerTargets[newIndex]?.focus()
    }
  }

  activeIndexValueChanged() {
    this.updateActive()
  }

  updateActive() {
    this.triggerTargets.forEach((trigger, index) => {
      const isActive = index === this.activeIndexValue
      trigger.dataset.state = isActive ? 'active' : 'inactive'
      trigger.setAttribute('aria-selected', isActive)
      trigger.tabIndex = isActive ? 0 : -1
    })

    this.contentTargets.forEach((content, index) => {
      content.classList.toggle('hidden', index !== this.activeIndexValue)
      content.setAttribute('aria-hidden', index !== this.activeIndexValue)
    })
  }
}
```

### Usage in Design System
```ruby
render Components::Ui::Tabs.new(
  data: {
    controller: "ui--tabs",
    ui__tabs_active_index_value: 0
  }
) do
  render Components::Ui::TabsList.new do
    render Components::Ui::TabsTrigger.new(
      data: {
        "ui--tabs-target": "trigger",
        action: "click->ui--tabs#select keydown->ui--tabs#keydown"
      }
    ) { "Tab 1" }
    
    render Components::Ui::TabsTrigger.new(
      data: {
        "ui--tabs-target": "trigger",
        action: "click->ui--tabs#select keydown->ui--tabs#keydown"
      }
    ) { "Tab 2" }
  end

  render Components::Ui::TabsContent.new(
    data: { "ui--tabs-target": "content" }
  ) { "Content 1" }

  render Components::Ui::TabsContent.new(
    data: { "ui--tabs-target": "content" }
  ) { "Content 2" }
end
```

---

## 3. Dialog (Modal) Component

### Usage in Design System
```ruby
div(
  data: {
    controller: "ui--dialog",
    ui__dialog_open_value: false,
    ui__dialog_close_on_overlay_click_value: true,
    ui__dialog_close_on_esc_value: true
  }
) do
  render Components::Ui::Button.new(
    data: { action: "click->ui--dialog#open" }
  ) { "Open Dialog" }

  render Components::Ui::DialogOverlay.new(
    data: { "ui--dialog-target": "overlay" },
    hidden: true
  )

  render Components::Ui::DialogContent.new(
    data: { "ui--dialog-target": "content" },
    hidden: true
  ) do
    render Components::Ui::DialogHeader.new do
      render Components::Ui::DialogTitle.new { "Confirm Action" }
    end

    render Components::Ui::DialogFooter.new do
      render Components::Ui::Button.new(
        variant: :outline,
        data: { action: "click->ui--dialog#close" }
      ) { "Cancel" }

      render Components::Ui::Button.new(
        data: { action: "click->ui--dialog#close" }
      ) { "Continue" }
    end
  end
end
```

---

## 4. Accordion Component

```ruby
div(
  data: {
    controller: "ui--accordion",
    ui__accordion_allow_multiple_value: false
  }
) do
  # Accordion Item 1
  div(class: "border-b border-border") do
    button(
      type: :button,
      class: "flex flex-1 items-center justify-between py-4 text-sm font-medium hover:underline",
      data: {
        "ui--accordion-target": "trigger",
        action: "click->ui--accordion#toggle keydown->ui--accordion#keydown"
      }
    ) do
      text "Is it interactive?"
      # Add SVG chevron here
    end

    div(
      class: "overflow-hidden text-sm transition-all duration-200",
      data: { "ui--accordion-target": "content" },
      style: "max-height: 0"
    ) do
      div(class: "pb-4 pt-0") { "Yes! Click to toggle." }
    end
  end
end
```

---

## 5. Dropdown Menu Component

```ruby
div(
  data: {
    controller: "ui--dropdown",
    ui__dropdown_open_value: false,
    ui__dropdown_placement_value: "bottom-start"
  }
) do
  render Components::Ui::Button.new(
    data: {
      "ui--dropdown-target": "trigger",
      action: "click->ui--dropdown#toggle"
    }
  ) { "Menu" }

  div(
    role: :menu,
    class: "z-50 rounded-lg border border-border bg-popover p-1 text-popover-foreground " +
           "shadow-md transition-all duration-200",
    data: {
      "ui--dropdown-target": "content",
      "ui--dropdown-placement-value": "bottom-start"
    }
  ) do
    div(class: "px-2 py-1.5 text-sm font-semibold") { "Actions" }

    div(role: :separator, class: "-mx-1 my-1 h-px bg-border")

    button(
      type: :button,
      role: :menuitem,
      class: "w-full rounded-md px-2 py-1.5 text-sm text-left font-medium " +
             "transition-colors hover:bg-accent hover:text-accent-foreground " +
             "focus-visible:bg-accent focus-visible:text-accent-foreground",
      data: {
        "ui--dropdown-target": "item",
        action: "click->ui--dropdown#select keydown->ui--dropdown#itemKeydown"
      }
    ) { "Option 1" }

    button(
      type: :button,
      role: :menuitem,
      class: "w-full rounded-md px-2 py-1.5 text-sm text-left font-medium " +
             "transition-colors hover:bg-accent hover:text-accent-foreground " +
             "focus-visible:bg-accent focus-visible:text-accent-foreground",
      data: {
        "ui--dropdown-target": "item",
        action: "click->ui--dropdown#select keydown->ui--dropdown#itemKeydown"
      }
    ) { "Option 2" }
  end
end
```

---

## 6. Tooltip Component

```ruby
div(
  data: {
    controller: "ui--tooltip",
    ui__tooltip_delay_value: 200,
    ui__tooltip_placement_value: "top"
  }
) do
  div(
    class: "inline-block",
    data: {
      "ui--tooltip-target": "trigger",
      action: "mouseenter->ui--tooltip#show mouseleave->ui--tooltip#hide " +
              "focus->ui--tooltip#show blur->ui--tooltip#hide"
    }
  ) do
    render Components::Ui::Button.new(
      variant: :outline
    ) { "Hover for tooltip" }
  end

  div(
    role: :tooltip,
    class: "z-50 rounded-lg border border-border bg-popover px-3 py-1.5 " +
           "text-sm text-popover-foreground shadow-md transition-all duration-200",
    data: { "ui--tooltip-target": "content" },
    hidden: true
  ) { "This is a tooltip" }
end
```

---

## Importmap Configuration

```ruby
# config/importmap.rb

# Base Stimulus controller (explicit pin because it doesn't follow *_controller.js naming)
pin "controllers/ui/base_controller", to: "controllers/ui/base_controller.js"

# Floating UI for smart positioning (Tooltip, Dropdown)
pin "@floating-ui/core"
pin "@floating-ui/dom"

# Component controllers auto-registered via stimulus/webpack convention
```

---

## Testing Checklist

✅ **Browser Console**
- [ ] See emoji-prefixed logs: 🔘 Switch, 📑 Tabs, 📂 Accordion, 💬 Tooltip, 📋 Dropdown, 🗨️ Dialog
- [ ] No 404 errors for module imports
- [ ] No "Failed to register controller" errors

✅ **DOM Updates**
- [ ] `data-state` changes on interaction (inspect element)
- [ ] `aria-selected`, `aria-expanded`, `aria-checked` update correctly
- [ ] Classes update via `data-[state=X]:` selectors in Tailwind

✅ **Keyboard Navigation**
- [ ] Tabs: Arrow keys switch tabs
- [ ] Accordion: Arrow keys expand/collapse
- [ ] Dialog: ESC closes modal
- [ ] Dropdown: Arrow keys navigate items, ESC closes

✅ **Focus Management**
- [ ] Tab key cycles through focusable elements
- [ ] Dialog: Focus trapped inside modal
- [ ] Focus restored when modal closes
