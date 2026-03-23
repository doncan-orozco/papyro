---
name: sqlite
description: SQLite-specific migration patterns and database maintenance for Rails 8 applications. Use when creating migrations, modifying database schema, or performing database maintenance. Covers safe migration patterns, column operations, constraint management, index creation, and data migration strategies.
---

# Database (SQLite + Rails 8)

## Dependencies
- strong_migrations - Prevents unsafe migrations
- database_consistency - Audits database integrity

## Core Principle

**Comment from strong_migrations docs:**
> "You probably don't need this gem for smaller projects, as operations that are unsafe at scale can be perfectly safe on smaller, low-traffic tables."

For Papyro: **SQLite scales to millions of rows**. Treat migrations with Postgres/MySQL rigor to avoid downtime and data corruption.

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

## Safe Migration Patterns (strong_migrations)

### ✅ Adding a Column (Simplest Case)

**Good Pattern:**

```ruby
# app/db/migrate/xxx_add_status_to_articles.rb
class AddStatusToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :status, :string, default: "draft", null: false
  end
end
```

### ❌ DON'T: Remove Column Directly

```ruby
# UNSAFE - will cause errors on app restart
class RemoveStatusFromArticles < ActiveRecord::Migration[8.1]
  def change
    remove_column :articles, :status
  end
end
```

**Safe Pattern (3 Deploy Strategy):**

**Deploy 1: Ignore Column**
```ruby
# app/models/article.rb
class Article < ApplicationRecord
  self.ignored_columns += ["status"]
end
```

**Deploy 2: Remove Column**
```ruby
class RemoveStatusFromArticles < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :articles, :status }
  end
end
```

**Deploy 3: Clean Up Code**
Remove `ignored_columns` line from model.

### ❌ DON'T: Change Column Type

```ruby
# UNSAFE - rewrites entire table, locks reads/writes
class ChangeAmountTypeToDecimal < ActiveRecord::Migration[8.1]
  def change
    change_column :transactions, :amount, :decimal, precision: 10, scale: 2
  end
end
```

**Safe Pattern (6 Step):**
1. Create new column (e.g., `amount_decimal`)
2. Backfill data (see backfilling section)
3. Update app to write to both columns
4. Update app to read from new column
5. Stop writing to old column
6. Drop old column (separate migration)

### ❌ DON'T: Rename Column Directly

Same as type change - causes runtime errors in app.

**Safe Pattern:**
1. Duplicate column with new name
2. Backfill
3. Update reads to new column
4. Stop writes to old column
5. Drop old column

### ✅ Add Foreign Key (Safe by Default with strong_migrations)

```ruby
class AddUserIdToArticles < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :articles, :users, validate: false
    # strong_migrations now validates in separate step automatically
  end
end
```

Without `validate: false`, foreign key blocks writes while validating all rows.

### ✅ Add Unique Index (Safe with Algorithm)

```ruby
class AddUniqueSlugIndex < ActiveRecord::Migration[8.1]
  def change
    add_index :articles, :slug, unique: true
  end
end
```

For SQLite this is safe. For Postgres production, use:
```ruby
disable_ddl_transaction!

def up
  add_index :articles, :slug, unique: true, algorithm: :concurrently
  add_unique_constraint :articles, using_index: "index_articles_on_slug"
end
```

### ✅ Backfilling Data (Large Tables)

**✅ DO: Batch + Sleep (prevents locks)**

```ruby
class BackfillStatus < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!
  
  def up
    Article.unscoped.in_batches(of: 10000) do |relation|
      relation.where(status: nil).update_all status: "draft"
      sleep(0.01)  # Throttle - gives other queries a chance
    end
  end
  
  def down
    Article.update_all status: nil
  end
end
```

**❌ DON'T: Update All in Transaction**
```ruby
# UNSAFE - locks entire table during backfill
class BackfillStatus < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :status, :string
    Article.update_all status: "draft"  # One big query = long lock
  end
end
```

### ✅ Add Check Constraint (Without Blocking)

```ruby
class AddPriceCheckConstraint < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :products, "price > 0", name: "products_price_positive", validate: false
  end
end
```

`validate: false` means check applies to new rows only, existing rows can violate it.

Then validate in separate migration:
```ruby
class ValidatePriceConstraint < ActiveRecord::Migration[8.1]
  def up
    validate_check_constraint :products, name: "products_price_positive"
  end
  
  def down
    # No-op - can be skipped on rollback
  end
end
```

### ❌ DON'T: Set NOT NULL on Existing Column

```ruby
# UNSAFE - checks all rows while locked
class SetStatusNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :articles, :status, false
  end
end
```

**Safe Pattern:**
1. Add check constraint (non-validating)
2. Validate constraint in separate migration
3. Then set NOT NULL

```ruby
# Migration 1
class AddStatusNotNullConstraint < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :articles, "status IS NOT NULL", name: "articles_status_not_null", validate: false
  end
end

# Migration 2
class ValidateStatusNotNull < ActiveRecord::Migration[8.1]
  def up
    validate_check_constraint :articles, name: "articles_status_not_null"
    change_column_null :articles, :status, false
    remove_check_constraint :articles, name: "articles_status_not_null"
  end
end
```

### ✅ Add JSON Column

Always use `jsonb` (PostgreSQL), not `json`:
```ruby
class AddMetadataToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :metadata, :jsonb, default: {}, null: false
  end
end
```

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
