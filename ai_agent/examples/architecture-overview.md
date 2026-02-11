# Architecture Overview

**For complete guidelines, see: [ai_agent/VERIFICATION_CHECKLIST.md](../VERIFICATION_CHECKLIST.md)**

This page provides design philosophy and practical examples. All rules and requirements are documented in the checklist.

## Design Philosophy

1. **Clean Architecture**: Complete separation of business logic from framework
2. **Immutability**: Prefer immutable objects, avoid side effects
3. **Explicit Flow**: No hidden magic or callbacks
4. **Real-time First**: WebSockets for real-time features
5. **Rails 8 Native**: Embrace Rails 8 defaults (Solid Queue, Solid Cache, SQLite)

## Architecture Layers

Each layer has specific responsibilities. See the checklists for detailed requirements:

- **Controllers**: Request handling, thin logic
- **Operations**: Business logic (Trailblazer)
- **Contracts**: Validation (dry-validation)
- **Models**: Persistence only
- **Query Objects**: Complex reads
- **Services**: Domain logic
- **Channels**: Real-time communication
- **Background Jobs**: Async work (Solid Queue)

## Implementation Clarifications

Rules live in the checklist. See:
- [Task and issue requirements](../VERIFICATION_CHECKLIST.md#taskissue-requirements)
- [Queries](../VERIFICATION_CHECKLIST.md#queries-read-model)
- [Views](../VERIFICATION_CHECKLIST.md#views)
- [Components](../VERIFICATION_CHECKLIST.md#components)
- [Turbo Frames](../VERIFICATION_CHECKLIST.md#-turbo-frames)

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
