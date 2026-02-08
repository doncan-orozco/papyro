# Model Examples

**For complete guidelines, see: [ai_agent/VERIFICATION_CHECKLIST.md](../../ai_agent/VERIFICATION_CHECKLIST.md#models)**

Models are for persistence only - associations, scopes, and simple queries. Code examples below.

## Basic Model

```ruby
# app/models/player.rb
class Player < ApplicationRecord
  belongs_to :user
  belongs_to :game
  has_many :inventory_items
  
  # Rails 8: Normalize data automatically
  normalizes :username, with: -> { _1.strip.downcase }
  
  # Rails 8: Generate secure tokens
  generates_token_for :session
  
  # Simple query methods only
  scope :active, -> { where(status: 'active') }
  scope :in_area, ->(x, y, radius) { 
    where("x BETWEEN ? AND ?", x - radius, x + radius)
      .where("y BETWEEN ? AND ?", y - radius, y + radius) 
  }
  
  def move!(direction)
    case direction
    when "move_up" then update!(y: y + 1, last_direction: direction)
    when "move_down" then update!(y: y - 1, last_direction: direction)
    when "move_left" then update!(x: x - 1, last_direction: direction)
    when "move_right" then update!(x: x + 1, last_direction: direction)
    end
  end
end
```

See [VERIFICATION_CHECKLIST.md](../../ai_agent/VERIFICATION_CHECKLIST.md#models) for complete model guidelines.
