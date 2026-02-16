# Controller Examples

**For complete guidelines, see: [VERIFICATION_CHECKLIST.md](../VERIFICATION_CHECKLIST.md#controllers)**

Controllers are thin - they only receive requests, call Operations, and return responses. Trailblazer Operations return `Trailblazer::Operation::Result` objects (use `result.success?` / `result.failure?`).

## Task Requirements

Task requirements live in the checklist:
- [Task and issue requirements](../VERIFICATION_CHECKLIST.md#taskissue-requirements)

## Basic CRUD Controller

```ruby
# app/controllers/game/moves_controller.rb
class Game::MovesController < ApplicationController
  def create
    result = Game::Operation::MovePlayer.call(
      params: params.to_unsafe_h,
      current_user: current_user
    )

    if result.success?
      # Broadcast happens inside the Operation
      head :ok
    else
      error_key = result[:error_key]
      case error_key
      when :invalid_move
        render json: { error: result[:error] }, status: :unprocessable_entity
      when :unauthorized
        head :forbidden
      else
        head :internal_server_error
      end
    end
  end
end
```

See [VERIFICATION_CHECKLIST.md](../VERIFICATION_CHECKLIST.md#controllers) for complete controller guidelines.
