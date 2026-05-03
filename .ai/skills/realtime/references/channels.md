# Channel Examples (Action Cable)

**For complete guidelines, see: [copilot-instructions.md](/.github/copilot-instructions.md#channels-action-cable)**

Channels handle real-time WebSocket connections. Keep them minimal and delegate to Operations in `app/concepts/`.

## Channel with Operations

```ruby
# app/channels/game_channel.rb
class GameChannel < ApplicationCable::Channel
  def subscribed
    game = ::Game.find_by(id: params[:game_id])
    
    reject and return unless game
    reject and return unless current_user.player&.game_id == game.id
    
    stream_for game
    
    # Send initial game state
    transmit({
      type: 'game_state',
      players: game.players.active.map(&:as_json_for_broadcast),
      timestamp: Time.current.iso8601
    })
  end
  
  def unsubscribed
    # Cleanup when disconnected
  end
  
  # Handle client-initiated actions
  def move(data)
    result = Game::Operation::MovePlayer.new.call(
      params: data.merge(game_id: params[:game_id]),
      current_user: current_user
    )
    
    case result
    in Dry::Monads::Failure[:invalid_move, error:]
      transmit({ type: 'error', message: error })
    in Dry::Monads::Failure[*, **]
      transmit({ type: 'error', message: 'Action failed' })
    else
      # Success - broadcast already sent by operation
    end
  end
end
```

## Connection Authentication

```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user
    
    def connect
      self.current_user = find_verified_user
    end
    
    private
    
    def find_verified_user
      if verified_user = User.find_by(id: cookies.encrypted[:user_id])
        verified_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
```

## Broadcasting from Operations

```ruby
# Inside an Operation helper
def broadcast_movement(model)
  Game::BroadcastChannel.broadcast_to(
    model.game,
    {
      type: 'player_moved',
      player_id: model.id,
      x: model.x,
      y: model.y,
      direction: model.last_direction,
      timestamp: Time.current.to_i
    }
  )
  Success(model: model)
end
```

## Rules

Rules live in the checklist:
- [Channels](/.github/copilot-instructions.md#channels-action-cable)
