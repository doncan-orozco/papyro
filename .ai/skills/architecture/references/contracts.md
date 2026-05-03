# Contract Examples

**For complete guidelines, see: [copilot-instructions.md](/.github/copilot-instructions.md)**

Contracts handle all validation using dry-validation. Code examples below.

## Basic Contract

```ruby
# app/contracts/game/contract/move.rb
module Game
  class Contract
    class Move < Dry::Validation::Contract
      params do
        required(:direction).filled(:string, included_in?: %w[move_up move_down move_left move_right])
        required(:game_id).filled(:integer)
      end

      rule(:direction, :game_id) do
        key.failure("player not in game") if value == "move_up" && values[:game_id].to_i <= 0
      end
    end
  end
end
```

See [copilot-instructions.md](/.github/copilot-instructions.md) for complete contract guidelines.
