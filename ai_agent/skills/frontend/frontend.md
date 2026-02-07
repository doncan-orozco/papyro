# Frontend Skill (Hotwire + Phlex + Tailwind)

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

## Components
- Use Phlex for all reusable UI.
- Live in `app/components/` organized by domain.
- Pass data via arguments (no implicit instance vars).
- Keep components pure (no side effects).
- Compose larger components from smaller ones.

## Views
- Use Phlex for page-level views in `app/views/`.
- Rendered by controllers, receive data from controller.
- Compose views using components from `app/components/`.
- One view per action (index, show, new, edit, create).

## I18n (English + Spanish)
- Use scoped keys in views: `t(".title")`.
- Components read from `components.*` keys.
- Model attributes/enums come from `activerecord.*` keys.
- Use domain-based locale files in `config/locales/en/` and `config/locales/es/`.

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

## Stimulus Rules
- One controller per feature.
- Use `static targets`, `values`, `outlets`.
- Dispatch custom events for loose coupling.
- Organize by domain (`game/`, `ui/`).
- Name controllers as `domain--feature` (e.g., `data-controller="game--player"`).
- Register controllers in `index.js` or use auto-registration.

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
- Tailwind utility classes only (no custom CSS unless required).

