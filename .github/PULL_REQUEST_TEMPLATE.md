# Checklist

## Required (All PRs)
- [ ] `bin/rubocop` (use `bin/rubocop --fix-layout` first if needed)
- [ ] `rake test`
- [ ] `bin/brakeman --no-pager`
- [ ] `bin/bundler-audit`
- [ ] `bin/importmap audit`
- [ ] No hardcoded user-visible text (i18n keys used)
- [ ] English + Spanish translations added
- [ ] Controllers are thin; business logic in Operations
- [ ] Views/Components inherit from Base classes and are properly namespaced

## Required (If Changed DB)
- [ ] **`bundle exec database_consistency` passes** - Audits data integrity
- [ ] Migrations follow [strong_migrations patterns](../.ai/skills/database/sqlite.md#safe-migration-patterns-strong_migrations)
- [ ] NO unsafe direct changes (column type → multi-step, column rename → multi-step)
- [ ] Rollback tested locally: `rails db:migrate:down` then `rails db:migrate:up`

## Optional (if applicable)
- [ ] Turbo Frames: matching IDs, dedicated action, named route
- [ ] Stimulus: controller naming and `**attrs` support

## References
- [.ai/VERIFICATION_CHECKLIST.md](../.ai/VERIFICATION_CHECKLIST.md) - Complete checklist
- [.ai/skills/backend/anti-patterns.md](../.ai/skills/backend/anti-patterns.md) - What NOT to do
- [.ai/skills/backend/error-handling.md](../.ai/skills/backend/error-handling.md) - Error patterns
- [.ai/skills/database/sqlite.md](../.ai/skills/database/sqlite.md) - Safe migration patterns
