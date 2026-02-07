# Controller Examples

Controllers are thin - they only receive requests, call Operations, and return responses using pattern matching.

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

## Rules
- No business logic
- No validations
- No Strong Params filtering (done in Contracts)
- Use pattern matching for result handling
- Return appropriate HTTP status codes
- Broadcasting happens in Operations, not controllers
