# AI Agent Entrypoint (Papyro)

**🔴 MANDATORY: Read this file FIRST at every session start**

Use this as the single source of truth. Load only the skill files needed for the task to minimize tokens.

## Documentation Structure

See [DOCUMENTATION_STRUCTURE.md](DOCUMENTATION_STRUCTURE.md) for the complete documentation hierarchy and how to maintain DRY principles.

**Complete documentation map:**
- **[VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md)** = All rules & requirements (single source of truth)
  - Architecture, I18n, Lint, Tests, Security
  - References skill files for patterns and examples
- **[CI_VERIFICATION.md](CI_VERIFICATION.md)** = What CI checks, troubleshooting failures
- **[.github/PULL_REQUEST_TEMPLATE.md](../.github/PULL_REQUEST_TEMPLATE.md)** = Pre-commit checklist
- `skills/` = Implementation patterns, anti-patterns, error handling
- `examples/` = Code examples (reference the checklist)
  - [examples/lint-and-tests.md](examples/lint-and-tests.md) = Lint/test examples

**To add new skills/docs:** See [ADD_NEW_SKILLS.md](ADD_NEW_SKILLS.md)

## Quick rules (always)
- Keep responses concise, actionable, and code-first.
- Preserve existing style; avoid unrelated refactors.
- Comment WHY, not WHAT - Ruby is self-documenting.
- No business logic in controllers or models.
- All write logic in Trailblazer Operations.
- All validations in dry-validation contracts.
- No ActiveRecord callbacks or model validations.

## Simplified Flow (per task)
1. Read [VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md) for rules.
2. Load relevant [skills/](skills/) for patterns ([anti-patterns](skills/backend/anti-patterns.md), [error-handling](skills/backend/error-handling.md), etc.)
3. Use [examples/lint-and-tests.md](examples/lint-and-tests.md) for lint/test patterns.
4. Use [.github/PULL_REQUEST_TEMPLATE.md](../.github/PULL_REQUEST_TEMPLATE.md) for pre-commit checks.

## 🔴 MANDATORY: Self-Review Before Providing Code

Before responding with code changes, verify against [VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md):
- ✅ Views inherit from `Views::Base` (NOT `Phlex::HTML`)
- ✅ Components inherit from `Components::Base` (NOT `Phlex::HTML`)
- ✅ Proper namespaces: `Views::{Domain}`, `Components::{Domain}`
- ✅ All user-facing text has i18n keys (no hardcoded strings)
- ✅ Both English AND Spanish translations provided
- ✅ Domain-based locale files: `config/locales/{en,es}/{domain}.yml`
- ✅ Components include `**attrs` for Stimulus support
- ✅ Views/Components organized by domain in correct directories
- ✅ Controllers are thin (no business logic)
- ✅ Controllers handle Operation results with pattern matching
- ✅ Authorization checks BEFORE Operations (not inside Operations)
- ✅ Error handling: all Failures properly formatted and transmitted
- ✅ NO anti-patterns (see checklist for full list)
- ✅ Turbo Frames have matching IDs and domain concepts
- ✅ Routes are named with route helpers
- ✅ No implicit dependencies or hidden magic

**If I find issues, I MUST fix them before providing code.**

## 🧹 MANDATORY: Lint & Test Verification

Before responding with code changes, ensure all code WILL PASS checks:

**For architectural rules:** Use [VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md)  
**For anti-patterns:** See [skills/backend/anti-patterns.md](skills/backend/anti-patterns.md)  
**For error handling:** See [skills/backend/error-handling.md](skills/backend/error-handling.md)  
**For lint/test details:** See [examples/lint-and-tests.md](examples/lint-and-tests.md)  
**For pre-commit checklist:** See [.github/PULL_REQUEST_TEMPLATE.md](../.github/PULL_REQUEST_TEMPLATE.md)

Agents should verify:
- ✅ Code follows RuboCop style (see examples in [examples/lint-and-tests.md](examples/lint-and-tests.md))
- ✅ New features have tests (see patterns in [examples/lint-and-tests.md](examples/lint-and-tests.md))
- ✅ No hardcoded text, proper i18n usage
- ✅ Proper file organization and namespacing
- ✅ No console.log/puts statements left behind
- ✅ No commented-out code

See [examples/lint-and-tests.md](examples/lint-and-tests.md) for examples of fixes and test patterns.

## Pre-ImplVERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md) - complete rules (architecture + lint + tests)
2. Review [skills/backend/anti-patterns.md](skills/backend/anti-patterns.md) - what NOT to do
3. Review [examples/lint-and-tests.md](examples/lint-and-tests.md) - common errors and test patterns
4. Load relevant skill files (see Skill index below)
5. **Self-review every file BEFORE providing it** - use checklist + anti-patternsmon errors and test patterns
4. Load relevant skill files (see Skill index below)
5. **Self-review every file BEFORE providing it** - use checklists above

## Skill index (load on demand)
- Backend architecture: skills/backend/architecture.md
- Backend Rails 8 stack: skills/backend/rails8.md
- Backend Turbo Frames: skills/backend/turbo.md
- Frontend (Hotwire/Stimulus/Phlex/Tailwind): skills/frontend/frontend.md
- Frontend design system (shadcn/ui + Phlex): skills/frontend/design-system.md
- Frontend I18n (English + Spanish): skills/frontend/i18n.md
- Frontend UX/UI brief: skills/frontend/ux.md
- Backend realtime (Action Cable): skills/backend/realtime.md
- Testing (Minitest): skills/testing/testing.md
- Testing (Linting/RuboCop): skills/testing/linting.md
- Database (SQLite): skills/database/sqlite.md
