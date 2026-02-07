# AI Agent Entrypoint (Papyro)

Use this as the single source of truth. Load only the skill files needed for the task to minimize tokens.

## Quick rules (always)
- Keep responses concise, actionable, and code-first.
- Preserve existing style; avoid unrelated refactors.
- No business logic in controllers or models.
- All write logic in Trailblazer Operations.
- All validations in dry-validation contracts.
- No ActiveRecord callbacks or model validations.

## Skill index (load on demand)
- Backend architecture: skills/backend/architecture.md
- Backend Rails 8 stack: skills/backend/rails8.md
- Backend prohibited practices: skills/backend/prohibited.md
- Frontend (Hotwire/Stimulus/Phlex/Tailwind): skills/frontend/frontend.md
- Frontend design system (shadcn/ui + Phlex): skills/frontend/design-system.md
- Frontend I18n (English + Spanish): skills/frontend/i18n.md
- Frontend UX/UI brief: skills/frontend/ux.md
- Backend realtime (Action Cable): skills/backend/realtime.md
- Testing (Minitest): skills/testing/testing.md
- Testing (Linting/RuboCop): skills/testing/linting.md
- Database (SQLite): skills/database/sqlite.md
