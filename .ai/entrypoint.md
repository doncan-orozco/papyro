# AI Agent Entrypoint (Papyro)

**🔴 MANDATORY: Read this file FIRST at every session start**

Use this as the single source of truth. Load only the skill files needed for the task to minimize tokens.

## Documentation Structure

Use `.ai/` as the documentation source of truth. Keep detailed guidance in skill-specific `references/` folders to preserve DRY principles.

**Complete documentation map:**
- **[VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md)** = All rules & requirements (single source of truth)
  - Architecture, I18n, Lint, Tests, Security
  - References skill files for patterns and examples
- **[.github/PULL_REQUEST_TEMPLATE.md](../.github/PULL_REQUEST_TEMPLATE.md)** = Pre-commit checklist
- `skills/` = Implementation patterns, anti-patterns, error handling
  - Each skill folder contains `SKILL.md` + `references/` (implementation examples specific to that skill)
- Some skills also include `examples/` folders for copy-paste-ready snippets

**To add new skills/docs:** Follow the existing `skills/{domain}/SKILL.md` + `skills/{domain}/references/` pattern.

## Quick rules (always)
- Keep responses concise, actionable, and code-first.
- Preserve existing style; avoid unrelated refactors.
- Comment WHY, not WHAT - Ruby is self-documenting.
- No business logic in controllers or models.
- All write logic in dry-rb Operations (Dry::Operation + Dry::Monads).
- All validations in dry-validation contracts.
- No ActiveRecord callbacks or model validations.
- Compound Phlex components must use direct yielded child methods (for example `breadcrumb.list { ... }`), never child `.new` calls.

## Development Environment
- **Port:** 3030 (NOT 3000)
- **Start server:** `bin/dev` from workspace root
- **Design System:** http://localhost:3030/design-system (for testing UI components)

## Simplified Flow (per task)
1. Read [VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md) for rules.
2. Load relevant [skills/](skills/) for patterns ([anti-patterns](skills/backend-anti-patterns/SKILL.md), [error-handling](skills/error-handling/SKILL.md), etc.)
3. Use [skills/linting/references/lint-and-tests.md](skills/linting/references/lint-and-tests.md) for lint/test patterns.
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
- ✅ Controllers handle Operation results with `success?` / `failure?` checks and explicit payload access
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
**For anti-patterns:** See [skills/backend-anti-patterns/SKILL.md](skills/backend-anti-patterns/SKILL.md)  
**For error handling:** See [skills/error-handling/SKILL.md](skills/error-handling/SKILL.md)  
**For lint/test details:** See [skills/linting/references/lint-and-tests.md](skills/linting/references/lint-and-tests.md)  
**For pre-commit checklist:** See [.github/PULL_REQUEST_TEMPLATE.md](../.github/PULL_REQUEST_TEMPLATE.md)

Agents should verify:
- ✅ Code follows RuboCop style (see examples in [skills/linting/references/lint-and-tests.md](skills/linting/references/lint-and-tests.md))
- ✅ New features have tests (see patterns in [skills/linting/references/lint-and-tests.md](skills/linting/references/lint-and-tests.md))
- ✅ No hardcoded text, proper i18n usage
- ✅ Proper file organization and namespacing
- ✅ No console.log/puts statements left behind
- ✅ No commented-out code

See [skills/linting/references/lint-and-tests.md](skills/linting/references/lint-and-tests.md) for examples of fixes and test patterns.

## Pre-Implementation Checklist
1. Read [VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md) - complete rules (architecture + lint + tests)
2. Review [skills/backend-anti-patterns/SKILL.md](skills/backend-anti-patterns/SKILL.md) - what NOT to do
3. Review [skills/linting/references/lint-and-tests.md](skills/linting/references/lint-and-tests.md) - common errors and test patterns
4. Load relevant skill files (see Skill index below)
5. **Self-review every file BEFORE providing it** - use checklists above

## Core skills (ALWAYS load for every task)
- **[skills/backend-anti-patterns/SKILL.md](skills/backend-anti-patterns/SKILL.md)** - What NOT to do
- **[skills/error-handling/SKILL.md](skills/error-handling/SKILL.md)** - Error & auth patterns
- **[skills/playwright-cli/SKILL.md](skills/playwright-cli/SKILL.md)** - Browser automation for web testing, form filling, screenshots, and data extraction

## Specialized skills (load on demand based on task)

### Backend
- **[skills/architecture/SKILL.md](skills/architecture/SKILL.md)** - Controllers, Operations, Models, Contracts
- **[skills/rails8/SKILL.md](skills/rails8/SKILL.md)** - Rails 8 stack features
- **[skills/turbo/SKILL.md](skills/turbo/SKILL.md)** - ⚠️ REQUIRED for all interactive features/forms
- **[skills/realtime/SKILL.md](skills/realtime/SKILL.md)** - Action Cable, live updates

### Frontend
- **[skills/frontend/SKILL.md](skills/frontend/SKILL.md)** - Hotwire, Stimulus, Phlex, Tailwind
- **[skills/frontend-design/SKILL.md](skills/frontend-design/SKILL.md)** - Bold aesthetics, design thinking, avoiding AI slop
- **[../docs/Papyro UX.pdf](../docs/Papyro UX.pdf)** - Primary UX investigation artifact for product-direction decisions
- **[skills/ux/references/design-brief-template.md](skills/ux/references/design-brief-template.md)** - UX design brief template for new UI work
- **[skills/ux/references/ux-investigation-synthesis.md](skills/ux/references/ux-investigation-synthesis.md)** - Synthesized UX findings from repository artifacts
- **[skills/ux/references/ux-review-checklist.md](skills/ux/references/ux-review-checklist.md)** - UX quality checklist for implementation and review
- **[skills/theme-factory/SKILL.md](skills/theme-factory/SKILL.md)** - UI theming with Tailwind CSS, pre-configured themes
- **[skills/web-artifacts/SKILL.md](skills/web-artifacts/SKILL.md)** - Standalone HTML/CSS/JS artifacts, dashboards, embeddable components
- **[skills/i18n/SKILL.md](skills/i18n/SKILL.md)** - ⚠️ REQUIRED for all user-facing text
  - **→ dry-validation + dry-schema messages:** See [skills/i18n/SKILL.md](skills/i18n/SKILL.md)
- **[skills/design-system/SKILL.md](skills/design-system/SKILL.md)** - shadcn/ui + Phlex components
  - **→ Interactive Components:** See [design-system/references/stimulus-interactive-components.md](skills/design-system/references/stimulus-interactive-components.md) for Switch, Tabs, Accordion, Dropdown, Tooltip, Dialog patterns
- **[skills/ux/SKILL.md](skills/ux/SKILL.md)** - UX/UI guidelines

### Database
- **[skills/sqlite/SKILL.md](skills/sqlite/SKILL.md)** - SQLite-specific patterns
- **[skills/database-anti-patterns/SKILL.md](skills/database-anti-patterns/SKILL.md)** - ⚠️ REQUIRED for migrations

### Testing
- **[skills/testing/SKILL.md](skills/testing/SKILL.md)** - Minitest, Playwright system tests, unit & integration patterns
- **[skills/linting/SKILL.md](skills/linting/SKILL.md)** - RuboCop, style guide
