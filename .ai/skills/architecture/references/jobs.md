# Background Job Examples (Solid Queue)

**For complete guidelines, see: [VERIFICATION_CHECKLIST.md](../../../VERIFICATION_CHECKLIST.md#background-jobs-solid-queue)**

Examples assume Solid Queue for background jobs.

## Basic Job

```ruby
# app/jobs/game/regenerate_health_job.rb
class Game::RegenerateHealthJob < ApplicationJob
  queue_as :game_mechanics
  
  # Rails 8 Solid Queue: Limit concurrent execution
  limits_concurrency to: 10, key: -> { "game_#{arguments.first}" }
  
  # Don't retry for specific errors
  discard_on ActiveRecord::RecordNotFound
  
  # Retry with exponential backoff (Rails 8 default)
  retry_on StandardError, wait: :exponentially_longer, attempts: 5
  
  def perform(player_id)
    result = Game::Operation::RegenerateHealth.new.call(player_id: player_id)
    
    case result
    in Dry::Monads::Success(player:)
      logger.info "Regenerated health for player #{player_id}"
      
      # Broadcast health update via WebSocket
      Game::BroadcastChannel.broadcast_to(
        player.game,
        {
          type: 'health_updated',
          player_id: player.id,
          health: player.health,
          max_health: player.max_health
        }
      )
    in Dry::Monads::Failure[:player_not_found]
      logger.warn "Player #{player_id} not found, skipping regeneration"
    in Dry::Monads::Failure[:player_dead]
      # Don't retry for dead players
      return
    end
  end
end
```

## Recurring Job

```ruby
# app/jobs/game/tick_job.rb
class Game::TickJob < ApplicationJob
  queue_as :game_tick
  
  def perform
    Game.active.find_each do |game|
      game.players.active.find_each do |player|
        Game::RegenerateHealthJob.perform_later(player.id)
        Game::RegenerateEnergyJob.perform_later(player.id)
      end
    end
    
    # Schedule next tick (60 seconds)
    self.class.set(wait: 1.minute).perform_later
  end
end
```

## Rules

Rules live in the checklist:
- [Background jobs](../../../VERIFICATION_CHECKLIST.md#background-jobs-solid-queue)
