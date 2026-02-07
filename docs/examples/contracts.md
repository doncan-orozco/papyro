# Contract Examples

Contracts handle all validation using dry-validation. No validations in models.

## Basic Contract

```ruby
# app/concepts/game/contract/move.rb
module Game
  class Contract
    class Move < Trailblazer::Contract::Reform
      property :direction
      property :game_id
      
      validation do
        params do
          required(:direction).filled(:string, included_in?: %w[move_up move_down move_left move_right])
          required(:game_id).filled(:integer)
        end
        
        rule(:direction, :game_id) do
          key.failure("player not in game") unless ::Game.find_by(id: values[:game_id])&.active?
        end
      end
    end
  end
end
```

## Rules
- NO validations in ActiveRecord models
- Define strict schemas with dry-validation
- Validate types, presence, and business rules
- Use custom predicates for game-specific validations
