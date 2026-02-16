# Service Examples

**For complete guidelines, see: [VERIFICATION_CHECKLIST.md](../VERIFICATION_CHECKLIST.md#services)**

Services contain domain logic following Single Responsibility Principle.

## Basic Service

```ruby
# app/services/game/collision_detector.rb
module Game
  class CollisionDetector
    def initialize(player:, direction:)
      @player = player
      @direction = direction
    end
    
    def collides?
      target_position = calculate_target_position
      obstacle_at?(target_position) || player_at?(target_position)
    end
    
    private
    
    def calculate_target_position
      case @direction
      when "move_up" then [@player.x, @player.y + 1]
      when "move_down" then [@player.x, @player.y - 1]
      when "move_left" then [@player.x - 1, @player.y]
      when "move_right" then [@player.x + 1, @player.y]
      end
    end
    
    def obstacle_at?(position)
      Obstacle.exists?(x: position[0], y: position[1], game_id: @player.game_id)
    end
    
    def player_at?(position)
      Player.exists?(x: position[0], y: position[1], game_id: @player.game_id)
    end
  end
end
```

## Rules

Rules live in the checklist:
- [Services](../VERIFICATION_CHECKLIST.md#services)
