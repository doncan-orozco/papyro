# Gem Setup and CI Task

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
