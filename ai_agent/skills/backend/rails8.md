# Rails 8 Stack Skill

**Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md)**

This skill covers Rails 8 specifics. For complete project guidelines, see the verification checklist.

## Dependencies
- rails
- solid_queue
- solid_cache
- propshaft
- kamal

## Stack
- Ruby 4.0.0+, Rails 8.0+.
- Solid Queue for jobs (no Redis).
- Solid Cache for caching (no Redis).
- SQLite production optimizations (WAL, busy_timeout).
- Propshaft for assets.
- Kamal 2 for deployment.

## Conventions
- Prefer Rails 8 defaults.
- Use `normalizes` and `generates_token_for` when needed.
- Use transactions for multi-step writes.
