# Architecture Skill (Clean Architecture + Trailblazer 2.1)

**Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md#-architecture--organization)**

This skill provides deep-dive implementation details. For guidelines and requirements, see the checklist.

## Dependencies
- trailblazer-operation
- trailblazer-rails
- dry-monads
- dry-validation

## File Structure (Hybrid: Trailblazer Concepts + Rails Conventions)
```
app/
  concepts/
    game/
      operation/
        move_player.rb
      contract/
        move_player.rb
    player/
      operation/
        create.rb
      contract/
        create.rb
  
  components/        ← Reusable UI components (Phlex)
    game/
      player_card.rb
    ui/
      button.rb
  
  views/             ← Page-level views (Phlex)
    games/
      index.rb
      show.rb
    players/
      index.rb
  
  controllers/       ← Thin controllers
  channels/          ← WebSocket channels
  models/            ← ActiveRecord (persistence only)
  queries/           ← Query objects
  services/          ← Domain services
```

## Core Rules
- Controllers are thin: accept request, call Operation, pattern-match result, return response.
- All writes live in `app/concepts/{domain}/operation/` (Railway flow with `step`).
- Each concept owns its domain: operations, contracts, business logic.
- Use dry-monads Result (`Success`/`Failure`).
- Broadcasting happens inside Operations, not controllers.
- **Custom collection actions are allowed for Turbo Frames** (e.g., `articles#featured`) when they represent a domain concept subset.


## Operations Flow (typical)
1. `Model` step (load record from `app/models/`)
2. `Contract::Build` (from `app/concepts/{domain}/contract/`)
3. `Contract::Validate`
4. Domain/service steps
5. `Contract::Persist`
6. Broadcast step

## Models
- Persistence only: associations, scopes, simple queries.
- No validations, no callbacks, no business logic.
- Shared across concepts in `app/models/`.

## Contracts
- Live in `app/concepts/{domain}/contract/`.
- All validations here, none in models.

## Query Objects
- Complex reads live under `app/queries/`.
- Return relations when possible.

## Services
- Single responsibility, stateless when possible.
- Accept explicit args; return Result or raise specific exceptions.
- Live in `app/services/` or injected into Operations.


## For Verification & Requirements
> See [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md#-architecture--organization) for complete requirements and [SELF_REVIEW_CHECKLIST.md](../../SELF_REVIEW_CHECKLIST.md) for quick reference.
