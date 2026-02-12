# Database Anti-Patterns (What NOT to Do)

**Reference: [sqlite.md](sqlite.md) | [strong_migrations](https://github.com/ankane/strong_migrations)**

Database operations that look simple but cause locks, data corruption, or runtime errors. Every pattern violates strong_migrations safety checks for good reason.

## Migration Anti-Patterns

### ❌ DON'T: Remove Columns Directly

Causes runtime errors when app restarts - app tries to read cached column that no longer exists.

**See [sqlite.md - Remove Column Directly](sqlite.md#-dont-remove-column-directly) for the safe 3-step pattern:**
1. Ignore column in app code
2. Remove in migration with `safety_assured`
3. Clean up ignored_columns line

### ❌ DON'T: Change Column Type in Single Step

Entire table rewritten and locked during change - risks downtime and data corruption.

**See [sqlite.md - Change Column Type](sqlite.md#-dont-change-column-type) for the safe 6-step pattern:**
1. Create new column
2. Double-write (app writes to both)
3. Backfill with batches + sleep
4. Update reads to new column
5. Stop writing old column
6. Drop old column in separate migration

### ❌ DON'T: Backfill Data in Transactions

One massive `update_all` within a transaction locks the entire table for the duration - blocks all reads and writes.

**See [sqlite.md - Backfilling Data](sqlite.md#-backfilling-data-large-tables) for safe pattern:**
- Use `in_batches(of: 10000)` with `disable_ddl_transaction!`
- Add `sleep(0.01)` between batches to prevent lock starvation
- Never backfill in change block with column addition

### ❌ DON'T: Set NOT NULL on Existing Column

`change_column_null` checks ALL rows and locks entire table - data consistency issue if violations exist.

**See [sqlite.md - Set NOT NULL](sqlite.md#-dont-set-not-null-on-existing-column) for safe pattern:**
1. Add check constraint with `validate: false`
2. Validate constraint in separate migration
3. Then apply `change_column_null` + remove constraint

### ❌ DON'T: Add Foreign Key Without validate: false

Locks both tables while validating all existing rows - prevents all operations during validation.

**See [sqlite.md - Add Foreign Key](sqlite.md#-dont-add-foreign-key-without-validate-false) for safe pattern:**
1. Add foreign key with `validate: false`
2. Validate in separate migration with `validate_foreign_key`

### ❌ DON'T: Rename Column Directly

App code conflicts with renamed column - causes runtime errors on active code reading old name.

**See [sqlite.md - Rename Column](sqlite.md#-dont-rename-column-directly) for safe pattern (same as type change):**
1. Create new column with new name
2. Write to both columns in app
3. Backfill data
4. Read from new column
5. Stop writing old column
6. Drop old column

## Data Consistency Anti-Patterns

### ❌ DON'T: Skip `database_consistency` Check

Deploy without auditing after migrations - data inconsistencies slip through to production.

**Safe process:**
```bash
bundle exec rails db:migrate
bundle exec database_consistency  # Required step!
git push
```

Catches:
- ✅ Null constraint mismatches
- ✅ Missing foreign key constraints
- ✅ Orphaned indexes
- ✅ Counter cache errors
- ✅ Enum value mismatches

### ❌ DON'T: Misuse `safety_assured`

`safety_assured { remove_column ... }` without proper context - this disables all safety checks.

**Only use when BOTH conditions are met:**
1. App already deployed with `ignored_columns += ["field_name"]`
2. No production traffic will encounter old code reading the column

**See [sqlite.md - safety_assured Pattern](sqlite.md#safety_assured-pattern) for details.**

## Schema Constraint Anti-Patterns

### ❌ DON'T: Add Unique Index Without Constraint

Index exists but no constraint - index can be dropped accidentally, uniqueness no longer enforced.

**Safe pattern:**
```ruby
class AddUniqueSlug < ActiveRecord::Migration[8.1]
  def change
    add_index :articles, :slug, unique: true
    add_unique_constraint :articles, :slug  # Enforced at DB level
  end
end
```

### ❌ DON'T: Skip Check Constraints

Validation only at app level - direct SQL inserts or app bugs can bypass validation.

**Safe pattern:**
```ruby
class AddPrice < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :price, :decimal, null: false
    add_check_constraint :products, "price > 0", name: "products_price_positive"
  end
end
```

Protects against:
- ✅ App bugs bypassing validations
- ✅ Direct SQL inserts
- ✅ Data corruption during migrations
- ✅ Cross-service integrity issues
