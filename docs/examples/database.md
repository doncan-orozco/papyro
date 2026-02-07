# Database Examples (SQLite - Rails 8)

SQLite is production-ready in Rails 8 with proper configuration.

## Database Configuration

```ruby
# config/database.yml
production:
  adapter: sqlite3
  database: storage/production.sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
  # Rails 8: Production optimizations
  pragmas:
    journal_mode: :wal
    synchronous: :normal
    mmap_size: 134217728  # 128MB
    journal_size_limit: 67108864  # 64MB
    cache_size: 2000
    busy_timeout: 5000
```

## Migration with Indexes

```ruby
# db/migrate/20250101000000_create_players.rb
class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.string :username, null: false
      t.integer :x, null: false, default: 0
      t.integer :y, null: false, default: 0
      t.integer :health, null: false, default: 100
      t.integer :max_health, null: false, default: 100
      t.string :status, null: false, default: 'active'
      
      t.timestamps
    end
    
    # Composite index for spatial queries
    add_index :players, [:game_id, :x, :y]
    add_index :players, [:game_id, :status]
    add_index :players, :username, unique: true
  end
end
```

## Caching Example

```ruby
# app/models/player.rb
class Player < ApplicationRecord
  # Cache player data for 5 minutes
  def cached_stats
    Rails.cache.fetch("player_stats_#{id}", expires_in: 5.minutes) do
      {
        health: health,
        max_health: max_health,
        energy: energy,
        level: level,
        experience: experience
      }
    end
  end
  
  # Invalidate cache after update
  after_commit :clear_cache, on: [:update, :destroy]
  
  private
  
  def clear_cache
    Rails.cache.delete("player_stats_#{id}")
  end
end
```

## Rules
- Use SQLite with production optimizations (WAL, busy_timeout)
- Add indexes for spatial or frequent queries
- Use database constraints for integrity
- Use transactions for multi-step operations
- Use Solid Cache for all caching (no Redis)
