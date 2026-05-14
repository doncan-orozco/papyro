---
name: copilot-instructions
description: 'Project‑wide Copilot instructions and review guidelines for Papyro'
argument-hint: What aspect of Papyro standards are you enforcing?
agent: agent
---

# Copilot Instructions (Papyro)

**Code Review & Development Guidelines**

## 🔴 MANDATORY: Review Against Papyro Standards

This file is now the primary Copilot guidance source for the Papyro workspace. It replaces the deprecated entrypoint and verification checklist documents.

When reviewing pull requests or responding to development requests, you MUST verify against:

1. **This file** - Comprehensive code review checklist and skill guidance
2. **[.ai/skills/controller/SKILL.md](.ai/skills/controller/SKILL.md)** - Golden controller archetype: REST, locale separation, operation dispatch, Pundit, Turbo Stream
3. **[.ai/skills/operation-pattern/SKILL.md](.ai/skills/operation-pattern/SKILL.md)** - Golden operation archetype: mutation intent, transactions, explicit dependencies, routeable failure codes
4. **[.ai/skills/backend-anti-patterns/SKILL.md](.ai/skills/backend-anti-patterns/SKILL.md)** - What NOT to do
5. **[.ai/skills/error-handling/SKILL.md](.ai/skills/error-handling/SKILL.md)** - Error & auth patterns
6. **[.ai/skills/architecture/SKILL.md](.ai/skills/architecture/SKILL.md)** - Project overview & skill index
7. **[.ai/skills/models/SKILL.md](.ai/skills/models/SKILL.md)** - ActiveRecord models: strict layout, state predicates, N+1 prevention
8. **[.ai/skills/presenter-pattern/SKILL.md](.ai/skills/presenter-pattern/SKILL.md)** - Golden presenter archetype: SimpleDelegator, collection wrapping, view-agnostic display logic, no CSS/HTML. Load for ALL `app/presenters/` work and display transformation logic.
9. **[.ai/skills/frontend-style-ddd/SKILL.md](.ai/skills/frontend-style-ddd/SKILL.md)** - Domain-driven stylesheet organization rules
10. **[.ai/skills/system-testing/SKILL.md](.ai/skills/system-testing/SKILL.md)** - Rails system test patterns for Hotwire flows
11. **[.ai/skills/phlex-view-pattern/SKILL.md](.ai/skills/phlex-view-pattern/SKILL.md)** - Golden Phlex view archetype: dumb views, presenters, sub-component decomposition, UI vs. domain separation, safe Turbo Frame targeting. Load for ALL `app/views/` and `app/components/` work.

## How to Use This

When reviewing code:
1. Check this file and the relevant skill files against all changes
2. For any controller work, load `.ai/skills/controller/SKILL.md` **first** — it is the single source of truth for all controller patterns
3. For mutation flows in `app/concepts/*/operation/`, load `.ai/skills/operation-pattern/SKILL.md` with `.ai/skills/layered-validation-operation-pattern/SKILL.md` when contract boundaries matter
4. Review [anti-patterns](.ai/skills/backend-anti-patterns/SKILL.md) to catch common mistakes
5. Verify error handling follows [error-handling.md](.ai/skills/error-handling/SKILL.md) patterns
6. Load relevant skill files directly from `.ai/skills/{domain}/SKILL.md`
7. Provide detailed feedback citing the checklist item number
8. When writing or reviewing system tests, load `.ai/skills/system-testing/SKILL.md` in addition to `.ai/skills/testing/SKILL.md`

## Key Review Areas

- ✅ **Architecture**: Controllers, Operations, Models, Contracts
- ✅ **Frontend**: Views, Components, Stimulus, Styling
- ✅ **I18n**: English + Spanish translations required
- ✅ **Organization**: Proper file structure & namespaces
- ✅ **Turbo Frames**: Domain concepts, matching IDs, dedicated actions

### Operation Review Checks (Mutation Flows)

- For operations inheriting from `Dry::Operation`, `call` returns a plain payload hash (for example `{ model: ... }`), not `Success(...)`.
- If an operation performs multiple writes or combines metadata updates with a state transition, the workflow must be transactional so partial updates cannot leak.
- Operations must accept explicit dependencies (`user:`, `locale:`, `settings_params:`) instead of reaching into `Current` or raw HTTP state.
- Avoid redundant pass-through steps in operations when no business rule is enforced between validation and persistence.
- Prefer model-driven nested assignment (`assign_attributes`) when nested attributes are configured on the model.
- Prefer one operation per domain intent (`Publish`, `Unpublish`) over action-flag switching in a single operation.
- On validation failure re-render models, preserve user-entered permitted fields but do not repopulate passwords.

### Controller Boundary Checks

- Controllers must not generate HTML markup directly (`view_context.tag`, `tag`, inline HTML strings).
- Controllers must not own presentation CSS class decisions or translation composition for fragment markup.
- For Turbo Stream fragment updates, render a dedicated Phlex view/component (or template), and keep the controller focused on orchestration.
- When an operation failure returns an invalid `:model`, prefer `render ... status: :unprocessable_entity` over redirect so model errors remain available to the form.

### Form Intent Checks

- Do not mix distinct user intents (for example writing content vs publishing/settings metadata) in a single mode-switched form component.
- Prefer separate Phlex form components per intent (for example `EditorFormComponent`, `SettingsFormComponent`) and compose them in the page view.
- Reserve mode flags/branching inside a single component for minor presentation variants, not divergent interactions (autosave + Stimulus vs standard submit flow).

## File Organization Policy

**🔴 ROOT DIRECTORY RULES:**
- ✅ Only production code files (Gemfile, config.ru, Rakefile, etc.) belong in root
- ✅ Only README.md should document the project in root
- ❌ NO implementation docs, summaries, snapshots, or reference files in root

**Where documentation belongs:**
- **Skill References** → `.ai/skills/{domain}/references/` (e.g., architecture, frontend, etc.)
  - Implementation summaries → `.ai/skills/architecture/references/`
  - Form/Component snapshots → `.ai/skills/frontend/references/`
  - Domain-specific examples → appropriate skill folder
- **Skills & Patterns** → `.ai/skills/{domain}/` (SKILL.md file + references/)
- **Verification & Checklists** → This file serves as the primary checklist and guidance document

## Important Notes

- All guidelines are centralized in `.ai/` directory
- Do NOT duplicate rules in this file
- Always cite the checklist when flagging issues
- Keep reviews focused on Papyro standards compliance

### Reviewing Skills & References

This repository has a rich set of skills under `.ai/skills/`.  Each skill contains a `SKILL.md` with patterns, examples, and sometimes a `references/` subfolder with concrete code snippets.  Before starting work, you should:

1. Open this file and then the relevant `SKILL.md` for the task domain (e.g. architecture, frontend, testing).
2. Browse the `references/` folder for that skill if you need sample implementations or deeper guidance.
3. Load relevant `SKILL.md` files directly from `.ai/skills/{domain}/SKILL.md`.

New skills or updated patterns should be added following the existing directory conventions; update this instructions file or the entrypoint when you introduce a new skill.

No additional high‑level instructions are currently required – the current setup already covers the full set of topics.  Supplementary rules can be added later as the codebase evolves.
