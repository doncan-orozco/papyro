# Query Object Examples

**For complete guidelines, see: [copilot-instructions.md](/.github/copilot-instructions.md#queries-read-model)**

Complex queries live in isolated classes under `app/queries/`.

## Basic Query

```ruby
# app/queries/game/nearby_players_query.rb
module Game
  class NearbyPlayersQuery
    def initialize(player:, radius: 10)
      @player = player
      @radius = radius
    end
    
    def call
      Player
        .where("x BETWEEN ? AND ?", @player.x - @radius, @player.x + @radius)
        .where("y BETWEEN ? AND ?", @player.y - @radius, @player.y + @radius)
        .where.not(id: @player.id)
        .where(active: true)
        .select(:id, :username, :x, :y, :avatar_url, :health, :max_health)
    end
  end
end
```

## Rules

Rules live in the checklist:
- [Queries](/.github/copilot-instructions.md#queries-read-model)
