# Rails 8 Stack (Solid Queue/Cache/Cable, Propshaft, Kamal)

> Merged from the former `rails8` skill.

# Rails 8 Stack

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
