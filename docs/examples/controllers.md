# Controller Examples

**For complete guidelines, see: [ai_agent/VERIFICATION_CHECKLIST.md](../../ai_agent/VERIFICATION_CHECKLIST.md#controllers)**

Controllers are thin - they only receive requests, call Operations, and return responses using pattern matching. Code examples below.

## Task Requirements
- When creating a controller, tasks/issues must specify the **routes and helpers** (HTTP verb + path + helper name).

## Basic CRUD Controller

```ruby
# app/controllers/game/moves_controller.rb
class Game::MovesController < ApplicationController
  def create
    result = Game::Operation::MovePlayer.call(
      params: params.to_unsafe_h,
      current_user: current_user
    )

    case result
    in Dry::Monads::Success(player:, **) 
      # Broadcast happens inside the Operation
      head :ok
    in Dry::Monads::Failure[:invalid_move, error:]
      render json: { error: error }, status: :unprocessable_entity
    in Dry::Monads::Failure[:unauthorized]
      head :forbidden
    end
  end
end
```

See [VERIFICATION_CHECKLIST.md](../../ai_agent/VERIFICATION_CHECKLIST.md#controllers) for complete controller guidelines.
