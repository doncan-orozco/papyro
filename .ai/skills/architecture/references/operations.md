# Operation Examples

**For complete guidelines, see: [copilot-instructions.md](/.github/copilot-instructions.md)**

Operations orchestrate write flows using `ApplicationOperation` and `Dry::Monads::Result`. Keep authorization in controllers, structural validation in contracts, and state validation in models.

## Quick Refactor Pattern (Before / After)

```ruby
# BEFORE
def call(params:)
  validated_attributes = step validate_input(params)
  user = step build_user(validated_attributes)
  persisted_user = step persist_user(user)
  { model: persisted_user }
end

def build_user(attributes)
  user = User.new
  user.assign_attributes(attributes)
  Success(user)
end

def validate_input(params)
  result = Users::Contract::Create.new.call(params)
  return Success(result.to_h) if result.success?

  user = User.new(params.slice(:email_address, :profile_attributes))
  fail_with_model!(inject_errors!(user, result.errors.to_h))
end

# AFTER
def call(params:)
  validated_attributes = step validate_input(params)
  persisted_user = step persist_user(validated_attributes)
  { model: persisted_user }
end

def validate_input(params)
  result = Users::Contract::Create.new.call(params)
  return Success(result.to_h) if result.success?

  # Keep typed fields for re-render, but do not repopulate passwords.
  user = User.new(params.except(:password, :password_confirmation))
  fail_with_model!(inject_errors!(user, result.errors.to_h))
end

def persist_user(attributes)
  user = User.new(attributes)
  return Success(user) if user.save

  fail_with_model!(user)
end
```

Key points:
- In `Dry::Operation`, `call` returns a plain payload hash (`{ model: ... }`).
- Remove pass-through steps that do not enforce domain rules.
- Prefer model-driven nested assignment (`assign_attributes`) when nested attributes are configured.
- Preserve non-sensitive typed input for re-render; exclude password fields.

## State Command Split Pattern

```ruby
# BEFORE (single operation with action flag)
result = Articles::Operation::Publish.new.call(model: article, params: { action: "publish" })

# AFTER (one operation per domain intent)
publish_result = Articles::Operation::Publish.new.call(model: article)
unpublish_result = Articles::Operation::Unpublish.new.call(model: article)
```

Key points:
- Avoid `if action == ...` branching for distinct business commands.
- Keep controller action -> operation mapping 1-to-1 (`create` -> `Publish`, `destroy` -> `Unpublish`).
- Keep each operation linear and intent-specific.

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
