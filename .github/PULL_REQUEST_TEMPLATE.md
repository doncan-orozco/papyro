# Checklist

## Required
- [ ] `bin/rubocop` (use `bin/rubocop --fix-layout` first if needed)
- [ ] `rake test`
- [ ] `bin/brakeman --no-pager`
- [ ] `bin/bundler-audit`
- [ ] `bin/importmap audit`
- [ ] No hardcoded user-visible text (i18n keys used)
- [ ] English + Spanish translations added
- [ ] Controllers are thin; business logic in Operations
- [ ] Views/Components inherit from Base classes and are properly namespaced

## Optional (if applicable)
- [ ] Turbo Frames: matching IDs, dedicated action, named route
- [ ] Migrations: constraints added and rollback tested
- [ ] Stimulus: controller naming and `**attrs` support

## References
- [ai_agent/VERIFICATION_CHECKLIST.md](../ai_agent/VERIFICATION_CHECKLIST.md) - Complete checklist
- [ai_agent/skills/backend/anti-patterns.md](../ai_agent/skills/backend/anti-patterns.md) - What NOT to do
- [ai_agent/skills/backend/error-handling.md](../ai_agent/skills/backend/error-handling.md) - Error patterns
