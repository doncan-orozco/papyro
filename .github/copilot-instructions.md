# Copilot Instructions (Papyro)

**Code Review & Development Guidelines**

## 🔴 MANDATORY: Review Against Papyro Standards

When reviewing pull requests or responding to development requests, you MUST verify against:

1. **[ai_agent/VERIFICATION_CHECKLIST.md](ai_agent/VERIFICATION_CHECKLIST.md)** - Comprehensive code review checklist
2. **[ai_agent/SELF_REVIEW_CHECKLIST.md](ai_agent/SELF_REVIEW_CHECKLIST.md)** - Quick reference for authors
3. **[ai_agent/entrypoint.md](ai_agent/entrypoint.md)** - Project overview & skill index

## How to Use This

When reviewing code:
1. Check the [ai_agent/VERIFICATION_CHECKLIST.md](ai_agent/VERIFICATION_CHECKLIST.md) against all changes
2. Reference [ai_agent/SELF_REVIEW_CHECKLIST.md](ai_agent/SELF_REVIEW_CHECKLIST.md) for critical issues
3. Load relevant skill files from [ai_agent/entrypoint.md](ai_agent/entrypoint.md) as needed
4. Provide detailed feedback citing the checklist item number

## Key Review Areas

- ✅ **Architecture**: Controllers, Operations, Models, Contracts
- ✅ **Frontend**: Views, Components, Stimulus, Styling
- ✅ **I18n**: English + Spanish translations required
- ✅ **Organization**: Proper file structure & namespaces
- ✅ **Turbo Frames**: Domain concepts, matching IDs, dedicated actions

## Important Notes

- All guidelines are centralized in `ai_agent/` directory
- Do NOT duplicate rules in this file
- Always cite the checklist when flagging issues
- Keep reviews focused on Papyro standards compliance
