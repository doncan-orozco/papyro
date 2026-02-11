# Testing Skill (Minitest + Trailblazer 2.1)

**Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md)**

This skill provides testing strategies and patterns. For project guidelines, see the verification checklist.

## Dependencies
- minitest
- trailblazer-operation
- trailblazer-rails
- dry-monads
- dry-validation

## File Structure
```
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

## Coverage Examples
- Operations in isolation (happy + failure paths)
- Contracts for validation
- Channels for WebSocket authorization
- Broadcast assertions for realtime features
- Fixtures for test data
- Small, explicit tests

## Suggestions
- Framework: Minitest (Rails-native, fast, minimal)
- Test data: fixtures by default; add FactoryBot if fixtures become unmanageable
- System tests: Playwright (more reliable than Selenium) with Capybara driver

## UI Components (Phlex)
- Render components and assert HTML output.
- Verify variant/size classes and data attributes.
- Keep assertions semantic (avoid brittle class-level expectations when possible).

## Views
- Treat views as integration units: render and assert key sections.
- Avoid snapshot noise; assert only critical content.

