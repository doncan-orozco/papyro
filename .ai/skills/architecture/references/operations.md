# Operation Examples

**For complete guidelines, see: [copilot-instructions.md](/.github/copilot-instructions.md)**

Operations orchestrate write flows using `ApplicationOperation` and `Dry::Monads::Result`. Keep authorization in controllers, structural validation in contracts, and state validation in models.

## Complete Operation Example

```ruby
# app/operations/game/operation/move_player.rb
module Game
  module Operation
    class MovePlayer < ApplicationOperation

      def call(model:, params:)
        player = step find_player(model)
        validated_params = step validate_input(params)
        step check_collision(player:, direction: validated_params[:direction])
        moved_player = step update_position(player:, direction: validated_params[:direction])
        step broadcast_movement(moved_player)
      end

      private
      
      def find_player(model)
        return Failure(model: model) unless model

        Success(model)
      end

      def validate_input(params)
        result = Game::Contract::Move.new.call(params)

        if result.failure?
          player = Player.new
          invalid_player = inject_errors!(player, result.errors.to_h)
          return Failure(model: invalid_player)
        end

        Success(result.to_h)
      end

      def check_collision(player:, direction:)
        collision_detector = Game::Service::CollisionDetector.new(
          player: player,
          direction: direction
        )

        if collision_detector.collides?
          player.errors.add(:base, "Cannot move there - obstacle detected")
          return Failure(model: player)
        end

        Success(true)
      end
      
      def update_position(player:, direction:)
        player.move!(direction)
        Success(player)
      end
      
      def broadcast_movement(player)
        # Broadcast to all players in the game via WebSocket
        GameChannel.broadcast_to(
          player.game,
          {
            type: "player_moved",
            player_id: player.id,
            x: player.x,
            y: player.y,
            direction: player.last_direction
          }
        )

        Success(player: player)
      end
    end
  end
end
```

See [copilot-instructions.md](/.github/copilot-instructions.md) for complete operation guidelines.
