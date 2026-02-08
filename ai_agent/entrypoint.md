# AI Agent Entrypoint (Papyro)

**🔴 MANDATORY: Read this file FIRST at every session start**

Use this as the single source of truth. Load only the skill files needed for the task to minimize tokens.

## Documentation Structure

See [DOCUMENTATION_STRUCTURE.md](DOCUMENTATION_STRUCTURE.md) for the complete documentation hierarchy and how to maintain DRY principles.

**Quick summary:**
- [VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md) = Rules & Requirements (single source of truth)
- [SELF_REVIEW_CHECKLIST.md](SELF_REVIEW_CHECKLIST.md) = Quick reference for developers
- `skills/` = Implementation details (reference checklist)
- `docs/examples/` = Code examples (reference checklist)

**To add new skills/docs:** See [ADD_NEW_SKILLS.md](ADD_NEW_SKILLS.md)

## Quick rules (always)
- Keep responses concise, actionable, and code-first.
- Preserve existing style; avoid unrelated refactors.
- No business logic in controllers or models.
- All write logic in Trailblazer Operations.
- All validations in dry-validation contracts.
- No ActiveRecord callbacks or model validations.

## 🔴 MANDATORY: Self-Review Before Providing Code

Before responding with code changes, I MUST use [SELF_REVIEW_CHECKLIST.md](SELF_REVIEW_CHECKLIST.md) to verify:
- ✅ Views inherit from `Views::Base` (NOT `Phlex::HTML`)
- ✅ Components inherit from `Components::Base` (NOT `Phlex::HTML`)
- ✅ Proper namespaces: `Views::{Domain}`, `Components::{Domain}`
- ✅ All user-facing text has i18n keys (no hardcoded strings)
- ✅ Both English AND Spanish translations provided
- ✅ Domain-based locale files: `config/locales/{en,es}/{domain}.yml`
- ✅ Components include `**attrs` for Stimulus support
- ✅ Views/Components organized by domain in correct directories
- ✅ Controllers are thin (no business logic)
- ✅ Turbo Frames have matching IDs and domain concepts
- ✅ Routes are named with route helpers
- ✅ No implicit dependencies or hidden magic

**If I find issues, I MUST fix them before providing code.**

## Pre-Implementation Checklist
**When starting a task:**
1. Review [SELF_REVIEW_CHECKLIST.md](SELF_REVIEW_CHECKLIST.md) - AI quick reference
2. Review [VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md) - detailed guidelines
3. Load relevant skill files (see Skill index below)
4. Check prohibited patterns in skills/backend/prohibited.md
5. **Self-review every file BEFORE providing it**

## Skill index (load on demand)
- Backend architecture: skills/backend/architecture.md
- Backend Rails 8 stack: skills/backend/rails8.md
- Backend prohibited practices: skills/backend/prohibited.md
- Backend Turbo Frames: skills/backend/turbo.md
- Frontend (Hotwire/Stimulus/Phlex/Tailwind): skills/frontend/frontend.md
- Frontend design system (shadcn/ui + Phlex): skills/frontend/design-system.md
- Frontend I18n (English + Spanish): skills/frontend/i18n.md
- Frontend UX/UI brief: skills/frontend/ux.md
- Backend realtime (Action Cable): skills/backend/realtime.md
- Testing (Minitest): skills/testing/testing.md
- Testing (Linting/RuboCop): skills/testing/linting.md
- Database (SQLite): skills/database/sqlite.md
