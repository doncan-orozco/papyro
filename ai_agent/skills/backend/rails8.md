# Rails 8 Stack Skill

**Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md)**

This skill covers Rails 8 specifics. For complete project guidelines, see the verification checklist.

## Dependencies
- rails
- solid_queue
- solid_cache
- propshaft
- kamal

## Stack Snapshot
- Ruby 4.0.0+, Rails 8.0+
- Solid Queue
- Solid Cache
- SQLite with production optimizations (WAL, busy_timeout)
- Propshaft
- Kamal 2

## Conventions (Examples)
- Prefer Rails 8 defaults when they fit
- Use `normalizes` and `generates_token_for` when helpful
- Use transactions for multi-step writes
