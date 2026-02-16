# Copilot Instructions (Papyro)

**Code Review & Development Guidelines**

## 🔴 MANDATORY: Review Against Papyro Standards

When reviewing pull requests or responding to development requests, you MUST verify against:

1. **[.ai/VERIFICATION_CHECKLIST.md](.ai/VERIFICATION_CHECKLIST.md)** - Comprehensive code review checklist
2. **[.ai/skills/backend-anti-patterns/backend-anti-patterns.md](.ai/skills/backend-anti-patterns/backend-anti-patterns.md)** - What NOT to do
3. **[.ai/skills/error-handling/error-handling.md](.ai/skills/error-handling/error-handling.md)** - Error & auth patterns
4. **[.ai/entrypoint.md](.ai/entrypoint.md)** - Project overview & skill index

## How to Use This

When reviewing code:
1. Check the [.ai/VERIFICATION_CHECKLIST.md](.ai/VERIFICATION_CHECKLIST.md) against all changes
2. Review [anti-patterns](.ai/skills/backend-anti-patterns/backend-anti-patterns.md) to catch common mistakes
3. Verify error handling follows [error-handling.md](.ai/skills/error-handling/error-handling.md) patterns
4. Load relevant skill files from [.ai/entrypoint.md](.ai/entrypoint.md) as needed
5. Provide detailed feedback citing the checklist item number

## Key Review Areas

- ✅ **Architecture**: Controllers, Operations, Models, Contracts
- ✅ **Frontend**: Views, Components, Stimulus, Styling
- ✅ **I18n**: English + Spanish translations required
- ✅ **Organization**: Proper file structure & namespaces
- ✅ **Turbo Frames**: Domain concepts, matching IDs, dedicated actions

## Important Notes

- All guidelines are centralized in `.ai/` directory
- Do NOT duplicate rules in this file
- Always cite the checklist when flagging issues
- Keep reviews focused on Papyro standards compliance
