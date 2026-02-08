# Operation Examples

**For complete guidelines, see: [ai_agent/VERIFICATION_CHECKLIST.md](../../ai_agent/VERIFICATION_CHECKLIST.md#operations-trailblazer)**

Operations encapsulate all write business logic using Railway Oriented Programming. Code examples below.

## Complete Operation Example

```ruby
# app/concepts/game/operation/move_player.rb
module Game
  module Operation
    class MovePlayer < Trailblazer::Operation
      step Model(::Player, :find_by), :id_from_current_user
      step Contract::Build(constant: Game::Contract::Move)
      step Contract::Validate()
      step :check_collision
      step :update_position
      step Contract::Persist()
      step :broadcast_movement
      
      def id_from_current_user(ctx, current_user:, **)
        ctx[:id] = current_user.player_id
      end
      
      def check_collision(ctx, model:, params:, **)
        collision_detector = Game::Service::CollisionDetector.new(
          player: model,
          direction: params[:direction]
        )
        
        return true unless collision_detector.collides?
        
        ctx[:error] = "Cannot move there - obstacle detected"
        false
      end
      
      def update_position(ctx, model:, params:, **)
        model.move!(params[:direction])
        true
      end
      
      def broadcast_movement(ctx, model:, **)
        # Broadcast to all players in the game via WebSocket
        GameChannel.broadcast_to(
          model.game,
          {
            type: 'player_moved',
            player_id: model.id,
            x: model.x,
            y: model.y,
            direction: model.last_direction
          }
        )
        true
      end
    end
  end
end
```

See [VERIFICATION_CHECKLIST.md](../../ai_agent/VERIFICATION_CHECKLIST.md#operations-trailblazer) for complete operation guidelines.
