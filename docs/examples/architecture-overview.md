# Architecture Overview

Complete architecture guide for Papyro (web publishing app).

## Design Philosophy

1. **Clean Architecture**: Complete separation of business logic from framework
2. **Immutability**: Prefer immutable objects, avoid side effects
3. **Explicit Flow**: No hidden magic or callbacks
4. **Real-time First**: WebSockets for game mechanics
5. **Rails 8 Native**: Embrace Rails 8 defaults (Solid Queue, Solid Cache, SQLite)

## Architecture Layers

### Controllers (Rails Layer)
- Thin - no business logic, validations, or Strong Params
- Only receive requests and call Operations
- Use pattern matching for Success/Failure results
- Return appropriate HTTP responses

### Operations (Business Logic)
- All write operations in Trailblazer Operations
- Use `step` for Railway Oriented Programming
- Inject dependencies
- Return dry-monads Result objects (Success/Failure)
- Broadcast real-time updates within operations

### Contracts (Validation)
- All validations in dry-validation contracts
- NO validations in ActiveRecord models
- Define strict schemas
- Validate types, presence, and business rules

### Models (Persistence)
- Associations, scopes, simple queries only
- NO business logic, validations, or callbacks
- Use Rails 8 features: normalizes, generates_token_for

### Query Objects
- Complex reads in isolated classes
- Return ActiveRecord relations (chainable)
- No business logic - just data retrieval

### Services (Domain Logic)
- Single Responsibility Principle
- Stateless when possible
- Injected into Operations
- Return Result objects

### Channels (Real-time)
- WebSocket connections via Action Cable
- One channel per game/room
- Keep minimal - delegate to Operations
- Broadcast inside Operations after persistence

### Background Jobs
- Use Solid Queue (Rails 8 native)
- All jobs must be idempotent
- Pass IDs, not objects
- Handle failures gracefully

## Data Flow

### Write Flow
1. Request → Controller
2. Controller → Operation
3. Operation → Contract (validation)
4. Operation → Service (domain logic)
5. Operation → Model (persistence)
6. Operation → Channel (broadcast)
7. Controller ← Operation (Result)
8. Response ← Controller

### Read Flow
1. Request → Controller
2. Controller → Query Object
3. Query Object → Model
4. Controller ← Query Object (data)
5. Response ← Controller

### Real-time Flow
1. Client → WebSocket Channel
2. Channel → Operation
3. Operation → (validation, logic, persistence)
4. Operation → Channel.broadcast_to
5. All Clients ← Broadcast

## Prohibited Practices

❌ **NEVER:**
- Use callbacks in models (before_save, after_create, etc.)
- Put business logic in models or controllers
- Use Strong Params (filtering in Contracts)
- Use validations in ActiveRecord models
- Use Redis when Solid Cache/Queue works
- Poll when WebSockets available
- Mix game logic with Rails framework code

## Rails 8 Features to Embrace

✅ **USE:**
- Solid Queue for background jobs
- Solid Cache for caching
- SQLite in production
- Kamal 2 for deployment
- Propshaft for assets
- normalizes for data normalization
- generates_token_for for secure tokens

## File Structure

```
app/
  concepts/
    game/
      operation/
        move_player.rb
        attack_enemy.rb
      contract/
        move_player.rb
    player/
      operation/
        create.rb
        update.rb
      contract/
        create.rb
    enemy/
      operation/
        spawn.rb
      contract/
        spawn.rb
  
  components/
    game/
      player_card.rb
      move_button.rb
    ui/
      button.rb
      card.rb
    shared/
      navbar.rb
  
  views/
    games/
      index.rb
      show.rb
    players/
      index.rb
      new.rb
      edit.rb
  
  controllers/
    game/
      moves_controller.rb
    players/
      players_controller.rb
  
  javascript/
    application.js
    controllers/
      application.js
      index.js
      game/
        connection_controller.js
        player_controller.js
      ui/
        modal_controller.js
  
  channels/
    game_channel.rb
  
  models/
    player.rb
    enemy.rb
  
  queries/
    game/
      nearby_players_query.rb
  
  services/
    game/
      collision_detector.rb

config/
  locales/
    en/
      app.yml
      components.yml
      models.yml
    es/
      app.yml
      components.yml
      models.yml

test/
  concepts/
    game/
      operation/
        move_player_test.rb
      contract/
        move_player_test.rb
    player/
      operation/
        create_test.rb
  channels/
    game_channel_test.rb
  fixtures/
```

## Testing Strategy

- Operation tests: Test business logic and result handling
- Channel tests: Test WebSocket authorization and broadcasts
- Controller tests: Test HTTP responses and status codes
- Model tests: Test associations and scopes only
- System tests: Full-stack browser tests
- Use fixtures for test data
- Test both success and failure paths
