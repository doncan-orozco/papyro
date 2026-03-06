---
name: copilot-instructions
description: 'Project‑wide Copilot instructions and review guidelines for Papyro'
argument-hint: What aspect of Papyro standards are you enforcing?
agent: agent
---

# Copilot Instructions (Papyro)

**Code Review & Development Guidelines**

## 🔴 MANDATORY: Review Against Papyro Standards

When reviewing pull requests or responding to development requests, you MUST verify against:

1. **[.ai/VERIFICATION_CHECKLIST.md](.ai/VERIFICATION_CHECKLIST.md)** - Comprehensive code review checklist
2. **[.ai/skills/backend-anti-patterns/SKILL.md](.ai/skills/backend-anti-patterns/SKILL.md)** - What NOT to do
3. **[.ai/skills/error-handling/SKILL.md](.ai/skills/error-handling/SKILL.md)** - Error & auth patterns
4. **[.ai/entrypoint.md](.ai/entrypoint.md)** - Project overview & skill index

## How to Use This

When reviewing code:
1. Check the [.ai/VERIFICATION_CHECKLIST.md](.ai/VERIFICATION_CHECKLIST.md) against all changes
2. Review [anti-patterns](.ai/skills/backend-anti-patterns/SKILL.md) to catch common mistakes
3. Verify error handling follows [error-handling.md](.ai/skills/error-handling/SKILL.md) patterns
4. Load relevant skill files from [.ai/entrypoint.md](.ai/entrypoint.md) as needed
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
- **Verification & Checklists** → `.ai/` root (VERIFICATION_CHECKLIST.md, entrypoint.md)

## Important Notes

- All guidelines are centralized in `.ai/` directory
- Do NOT duplicate rules in this file
- Always cite the checklist when flagging issues
- Keep reviews focused on Papyro standards compliance

### Reviewing Skills & References

This repository has a rich set of skills under `.ai/skills/`.  Each skill contains a `SKILL.md` with patterns, examples, and sometimes a `references/` subfolder with concrete code snippets.  Before starting work, you should:

1. Open **.ai/entrypoint.md** – it lists every available skill along with when to load it.
2. For a given task, load the relevant `SKILL.md` (e.g. architecture, frontend, testing).  The entrypoint can be used as a quick index.
3. Browse the `references/` folder for that skill if you need sample implementations or deeper guidance.

New skills or updated patterns should be added following the existing directory conventions; update this instructions file or the entrypoint when you introduce a new skill.

No additional high‑level instructions are currently required – the current setup already covers the full set of topics.  Supplementary rules can be added later as the codebase evolves.
