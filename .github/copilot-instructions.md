---
name: copilot-instructions
description: 'Project‑wide Copilot instructions and review guidelines for Papyro'
argument-hint: What aspect of Papyro standards are you enforcing?
agent: agent
---

# Copilot Instructions (Papyro)

**Code Review & Development Guidelines**

## 🔴 MANDATORY: Review Against Papyro Standards

This file is now the primary Copilot guidance source for the Papyro workspace. It replaces the deprecated `.ai/entrypoint.md` and `.ai/VERIFICATION_CHECKLIST.md` documents.

When reviewing pull requests or responding to development requests, you MUST verify against:

1. **This file** - Comprehensive code review checklist and skill guidance
2. **[.ai/skills/backend-anti-patterns/SKILL.md](.ai/skills/backend-anti-patterns/SKILL.md)** - What NOT to do
3. **[.ai/skills/error-handling/SKILL.md](.ai/skills/error-handling/SKILL.md)** - Error & auth patterns
4. **[.ai/skills/architecture/SKILL.md](.ai/skills/architecture/SKILL.md)** - Project overview & skill index

## How to Use This

When reviewing code:
1. Check this file and the relevant skill files against all changes
2. Review [anti-patterns](.ai/skills/backend-anti-patterns/SKILL.md) to catch common mistakes
3. Verify error handling follows [error-handling.md](.ai/skills/error-handling/SKILL.md) patterns
4. Load relevant skill files directly from `.ai/skills/{domain}/SKILL.md`
5. Provide detailed feedback citing the checklist item number

## Key Review Areas

- ✅ **Architecture**: Controllers, Operations, Models, Contracts
- ✅ **Frontend**: Views, Components, Stimulus, Styling
- ✅ **I18n**: English + Spanish translations required
- ✅ **Organization**: Proper file structure & namespaces
- ✅ **Turbo Frames**: Domain concepts, matching IDs, dedicated actions

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
