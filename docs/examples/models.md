# Model Examples

Models are for persistence only - associations, scopes, and simple queries.

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

## Rules
- NO business logic
- NO validations (use contracts instead)
- NO callbacks (before_save, after_create, etc.)
- Only associations, scopes, and simple query methods
- Database constraints are allowed
- Use Rails 8 features: normalizes, generates_token_for
