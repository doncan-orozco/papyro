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
- Scoped keys in views: `t(".title")`
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
For shadcn UI components requiring interactivity (Switch, Tabs, Accordion, Dropdown, Tooltip, Dialog), use the standardized pattern:

**Files:**
- Phlex component (static) → receives `data-*` attributes via `**attrs`
- Stimulus controller → manages state, keyboard nav, positioning
- Design system examples → test with interactive demo

**Reference:** See [design-system/references/stimulus-interactive-components.md](../design-system/references/stimulus-interactive-components.md)

**Example Integration:**
```ruby
# Component passes Stimulus bindings
render Components::Ui::Switch.new(
  data: {
    controller: "ui--switch",
    ui__switch_checked_value: false,
    action: "click->ui--switch#toggle"
  }
)

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

## Styling
- Tailwind utility classes are the common baseline

> **For verification checklists, see [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md#-frontend)**

