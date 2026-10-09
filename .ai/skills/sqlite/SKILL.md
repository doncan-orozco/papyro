---
name: sqlite
description: "SQLite and Rails 8 stack: safe migrations (strong_migrations), database_consistency, Solid Queue/Cache/Cable, Propshaft, Kamal. Use when creating or editing files in `db/migrate/` or `db/*schema*`, changing columns/indexes/constraints, backfilling data, or configuring Solid services."
---

# Database (SQLite + Rails 8)

## Quick Rules

Cite as `sqlite R<n>`. Detail and examples follow below / in references/.

R1. **Run database_consistency.** `bundle exec database_consistency` runs after every migration, locally and in CI. → detail: Required: After Migrations
R2. **No direct remove_column.** Removing a column is a 3-deploy sequence: add `ignored_columns`, then remove with `safety_assured`, then delete the `ignored_columns` line. → detail: references/safe-migration-patterns.md
R3. **safety_assured only with ignored_columns.** `safety_assured` is used only when the app already ignores the column and that code is deployed; never as a shortcut. → detail: safety_assured Pattern
R4. **No in-place type change.** Changing a column type uses new column, double-write, batched backfill, read switch, stop old writes, drop old in a separate migration. → detail: references/migration-anti-patterns.md
R5. **No direct rename.** Renaming a column follows the same multi-step copy pattern as a type change, never `rename_column` directly. → detail: references/migration-anti-patterns.md
R6. **Batched backfills.** Backfills use `disable_ddl_transaction!`, `in_batches(of: 10000)` and `sleep(0.01)`; never `update_all` in a transaction or alongside `add_column` in `change`. → detail: references/safe-migration-patterns.md
R7. **NOT NULL on existing columns.** Use a non-validating check constraint, validate it in a separate migration, then `change_column_null` and remove the constraint; never bare `change_column_null`. → detail: references/safe-migration-patterns.md
R8. **Foreign keys unvalidated first.** `add_foreign_key` uses `validate: false`, with `validate_foreign_key` in a separate migration. → detail: references/migration-anti-patterns.md
R9. **Check constraints validate separately.** New check constraints use `validate: false` and are validated in a later migration. → detail: references/safe-migration-patterns.md
R10. **Unique index plus DB constraint.** Uniqueness is enforced at the DB level (unique index with constraint), not only by model validation. → detail: references/migration-anti-patterns.md
R11. **DB check constraints for invariants.** Value rules like `price > 0` are backed by `add_check_constraint`, not app validations alone. → detail: references/migration-anti-patterns.md
R12. **Timeouts configured.** `config/initializers/strong_migrations.rb` sets `lock_timeout` and `statement_timeout`. → detail: migration Timeouts
R13. **New columns declare nullability.** `add_column` with a default specifies `null: false` where the value is required. → detail: references/safe-migration-patterns.md
R14. **Rails 8 Solid stack.** Background jobs, cache and cable use Solid Queue/Cache/Cable on SQLite; assets use Propshaft; deploys use Kamal. → detail: references/rails8-stack.md

## Dependencies
- strong_migrations - Prevents unsafe migrations
- database_consistency - Audits database integrity

## Core Principle

**Comment from strong_migrations docs:**
> "You probably don't need this gem for smaller projects, as operations that are unsafe at scale can be perfectly safe on smaller, low-traffic tables."

For Papyro: **SQLite scales to millions of rows**. Treat migrations with Postgres/MySQL rigor to avoid downtime and data corruption.

## Reference Map

- **[references/database.md](references/database.md)**
  Use for the full SQLite-safe migration playbook, backfill patterns, constraint changes, and maintenance guidance.

## ⚠️ Required: After Migrations

**MANDATORY:** Run after every migration (local + CI):
```bash
bundle exec database_consistency
```

This audits:
- Null constraint violations
- Missing foreign keys
- Orphaned indexes
- Counter cache errors

Catches data drift before deployment.

> **Safe Migration Patterns (strong_migrations):** add/remove/rename/backfill/constraints → [references/safe-migration-patterns.md](references/safe-migration-patterns.md)

## migration Timeouts

Configure in `config/initializers/strong_migrations.rb`:

```ruby
StrongMigrations.lock_timeout = 10.seconds
StrongMigrations.statement_timeout = 1.hour
```

This prevents long-running migrations from blocking other queries.

## Data Consistency Audits

Run after every migration:
```bash
bundle exec database_consistency
```

Checks:
- ✅ Null constraints match schema
- ✅ Foreign keys valid
- ✅ Indexes exist for foreign keys
- ✅ Counter caches match reality
- ✅ Enum values match database

Add to CI to catch drift before production.

## safety_assured Pattern

Use ONLY when you're 100% certain the operation is safe:

```ruby
class RemoveDeprecatedColumn < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :articles, :deprecated_field }
  end
end
```

Requires both:
1. App already ignores column: `self.ignored_columns += ["deprecated_field"]`
2. Code deployed and running

NEVER use `safety_assured` as a shortcut - it disables all safety checks.

> **Gem Setup and CI Task:** strong_migrations, database_consistency initializers → [references/setup.md](references/setup.md)

