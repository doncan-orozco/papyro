# frozen_string_literal: true

if defined?(StrongMigrations)
  StrongMigrations.start_after = 0
  StrongMigrations.lock_timeout = 5.seconds
  StrongMigrations.statement_timeout = 30.seconds
end
