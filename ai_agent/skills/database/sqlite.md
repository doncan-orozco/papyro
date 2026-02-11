# Database Skill (SQLite + Rails 8)

**Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md)**

This skill provides SQLite-specific patterns. For complete project guidelines, see the verification checklist.

## Dependencies
- strong_migrations
- database_consistency

## Patterns
- SQLite in production with WAL mode and busy_timeout
- Indexes for spatial or frequent queries
- Database constraints for integrity
- Transactions for multi-step operations

See [Database rules](../../VERIFICATION_CHECKLIST.md#database-sqlite) for requirements.

## Conventions
- Use composite indexes for game coordinate queries.
- Keep migrations small and explicit.

## Migration Safety (SQLite)
- Use `strong_migrations` for basic safety checks.
- Some checks are limited on SQLite, but still catch risky patterns.
- Prefer safe patterns: add nullable columns first, backfill, then add constraints.
- Use `safety_assured` only when justified and documented.

## Data Consistency Audits
- Use `database_consistency` to audit integrity and data quality.
- Checks: null constraints, foreign keys, missing indexes, counter caches.
- Run in CI to catch drift.

## Recommended Gems
- strong_migrations
- database_consistency


## Setup (initializer examples)

### strong_migrations
Create `config/initializers/strong_migrations.rb`:

```
StrongMigrations.start_after = 0
StrongMigrations.lock_timeout = 5.seconds
StrongMigrations.statement_timeout = 30.seconds
```

### database_consistency
Create `config/initializers/database_consistency.rb`:

```
DatabaseConsistency.configure do |config|
	config.ignore_tables = %w[schema_migrations ar_internal_metadata]
	config.check_missing_foreign_keys = true
	config.check_missing_indexes = true
end
```

## CI Task
Add a CI step to run:

```
bundle exec database_consistency
```
