---
name: rails8
description: Rails 8 stack specifics including Solid Queue, Solid Cache, SQLite optimizations, Propshaft, and Kamal 2. Use when working with Rails 8 features, configuring the stack, or understanding Rails 8 conventions and defaults.
---

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
