# Query Object Examples

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
        .in_area(@player.x, @player.y, @radius)
        .where.not(id: @player.id)
        .active
        .select(:id, :username, :x, :y, :avatar_url, :health, :max_health)
    end
  end
end
```

## Rules
- Complex queries in isolated classes
- Use composition over inheritance
- Return ActiveRecord relations (chainable) or arrays
- No business logic - just data retrieval
- Leverage SQLite's JSON support for complex queries
