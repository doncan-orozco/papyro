# Phlex Component Examples

Phlex components are pure, reusable UI elements with Tailwind styling. Keep them in `app/components/` organized by domain.

## Basic Component

```ruby
# app/components/game/player_card.rb
module Game
  class PlayerCard < Phlex::HTML
    def initialize(player:, size: :medium)
      @player = player
      @size = size
    end
    
    def template
      div(
        id: dom_id(@player), 
        class: "player-card #{size_classes}",
        data: { 
          player_id: @player.id,
          controller: "game--player",
          game__player_x_value: @player.x,
          game__player_y_value: @player.y
        }
      ) do
        img(src: @player.avatar_url, alt: @player.name, class: "rounded-full")
        span(class: "player-name text-white font-bold") { @player.name }
        render UI::HealthBar.new(health: @player.health, max_health: @player.max_health)
      end
    end
    
    private
    
    def size_classes
      case @size
      when :small then "w-8 h-8"
      when :medium then "w-16 h-16"
      when :large then "w-24 h-24"
      end
    end
  end
end
```

## Reusable UI Component

```ruby
# app/components/ui/button.rb
module UI
  class Button < Phlex::HTML
    def initialize(text:, type: :button, variant: :primary, disabled: false, **attrs)
      @text = text
      @type = type
      @variant = variant
      @disabled = disabled
      @attrs = attrs
    end
    
    def template
      button(
        type: @type,
        class: "btn btn-#{@variant}",
        disabled: @disabled,
        **@attrs
      ) { @text }
    end
  end
end
```

## File Organization

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

## Rules
- Use Phlex for all reusable UI
- Components should be pure (no side effects)
- Pass all data as arguments (no instance variables from views)
- Use Tailwind utility classes
- Keep components small and composable
- Organize by domain: `game/`, `ui/`, `shared/`
- Separate from `app/concepts/` (UI layer vs business logic layer)
