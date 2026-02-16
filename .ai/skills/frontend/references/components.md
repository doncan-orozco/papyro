# Phlex Component Examples

**For complete guidelines, see: [VERIFICATION_CHECKLIST.md](../VERIFICATION_CHECKLIST.md#-frontend)**

Phlex components are pure, reusable UI elements with Tailwind styling. Code examples below.

## Basic Component

```ruby
# app/components/game/player_card.rb
module Components
  module Game
    class PlayerCard < Components::Base
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
          render Components::UI::HealthBar.new(health: @player.health, max_health: @player.max_health)
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
end
```

## Reusable UI Component

```ruby
# app/components/ui/button.rb
module Components
  module UI
    class Button < Components::Base
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

See [VERIFICATION_CHECKLIST.md](../VERIFICATION_CHECKLIST.md#components) for complete component guidelines.
