# Operation Examples

**For complete guidelines, see: [VERIFICATION_CHECKLIST.md](../../../VERIFICATION_CHECKLIST.md#operations)**

Operations encapsulate all write business logic using `Dry::Operation` and `Dry::Monads::Result`. Code examples below.

## Complete Operation Example

```ruby
# app/concepts/game/operation/move_player.rb
module Game
  module Operation
    class MovePlayer < Dry::Operation
      include Dry::Monads[:result]

      def call(params:, current_user:)
        player = step find_player(current_user)
        validated_params = step validate_input(params)
        step check_collision(player:, direction: validated_params[:direction])
        moved_player = step update_position(player:, direction: validated_params[:direction])
        step broadcast_movement(moved_player)
      end

      private
      
      def find_player(current_user)
        player = ::Player.find_by(id: current_user.player_id)
        return Failure(errors: { base: ["player_not_found"] }) unless player

        Success(player)
      end

      def validate_input(params)
        result = Game::Contract::Move.new.call(params)
        return Failure(errors: result.errors.to_h) if result.failure?

        Success(result.to_h)
      end

      def check_collision(player:, direction:)
        collision_detector = Game::Service::CollisionDetector.new(
          player: player,
          direction: direction
        )

        return Failure(errors: { base: ["Cannot move there - obstacle detected"] }) if collision_detector.collides?

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

See [VERIFICATION_CHECKLIST.md](../../../VERIFICATION_CHECKLIST.md#operations) for complete operation guidelines.
