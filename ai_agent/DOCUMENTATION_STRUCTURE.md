# Documentation Structure & Hierarchy (Papyro)

**DRY Principle: Single Source of Truth for All Guidelines**

This document defines how Papyro documentation is organized and maintained. Follow this structure for all future documentation and skill files.

## Documentation Hierarchy

```
ai_agent/
├── VERIFICATION_CHECKLIST.md      ← ⭐ SINGLE SOURCE OF TRUTH
│   └── Complete rules & requirements for all code review
│
├── SELF_REVIEW_CHECKLIST.md       ← Quick reference (mirrors verification)
│   └── Condensed checklist for developers before submitting code
│
├── entrypoint.md                  ← Entry point & orientation
│   └── Overview, skill index, quick rules
│
├── DOCUMENTATION_STRUCTURE.md     ← This file
│   └── How to organize and maintain documentation
│
└── skills/                        ← Deep-dive implementation details
    ├── backend/
    │   ├── architecture.md        → References VERIFICATION_CHECKLIST
    │   ├── prohibited.md          → References VERIFICATION_CHECKLIST
    │   ├── rails8.md              → References VERIFICATION_CHECKLIST
    │   ├── turbo.md               → References VERIFICATION_CHECKLIST
    │   └── realtime.md            → References VERIFICATION_CHECKLIST
    ├── frontend/
    │   ├── frontend.md            → References VERIFICATION_CHECKLIST
    │   ├── design-system.md       → References VERIFICATION_CHECKLIST
    │   ├── i18n.md                → References VERIFICATION_CHECKLIST
    │   └── ux.md                  → References VERIFICATION_CHECKLIST
    ├── testing/
    │   ├── testing.md             → References VERIFICATION_CHECKLIST
    │   └── linting.md             → References VERIFICATION_CHECKLIST
    └── database/
        └── sqlite.md              → References VERIFICATION_CHECKLIST

docs/
└── examples/                      ← Code examples & tutorials
    ├── architecture-overview.md   → References checklists
    ├── components.md              → References checklists
    ├── contracts.md               → References checklists
    ├── controllers.md             → References checklists
    ├── models.md                  → References checklists
    ├── operations.md              → References checklists
    ├── stimulus.md                → References checklists
    ├── views.md                   → References checklists
    └── i18n.md                    → References checklists

.github/
└── copilot-instructions.md        ← Tells GitHub Copilot to use checklists
```

## File Purposes

### 1. VERIFICATION_CHECKLIST.md (Source of Truth)
- **Purpose**: Complete list of all rules, requirements, and guidelines
- **Content**:
  - Architecture patterns (Controllers, Operations, Models, Contracts)
  - Frontend guidelines (Views, Components, Stimulus, Styling)
  - I18n requirements (English + Spanish)
  - Turbo Frames patterns
  - Pre-commit verification items
- **Usage**: Referenced by all other files; updated when guidelines change
- **Audience**: Code reviewers, developers, GitHub Copilot

### 2. SELF_REVIEW_CHECKLIST.md (Quick Reference)
- **Purpose**: Condensed version for developers before submitting code
- **Content**: Critical issues only (quick scan before PR)
- **Usage**: Developers use before committing
- **Relation**: Mirrors VERIFICATION_CHECKLIST in condensed form

### 3. entrypoint.md (Orientation)
- **Purpose**: Starting point for new team members
- **Content**:
  - Quick rules summary
  - Skill index (what file to read for each topic)
  - Self-review checklist pointer
  - How to use the documentation
- **Usage**: First document to read
- **Audience**: New team members, anyone onboarding

### 4. skills/*.md (Deep-dive Implementation)
- **Purpose**: Detailed implementation patterns and examples
- **Content**: Code patterns, file structures, dependencies, conventions
- **Usage**: When implementing a feature in that area
- **Pattern**: Each skill file starts with:
  ```markdown
  # {Topic} Skill ({Framework/Library})

  **Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md#{anchor})**

  This skill provides implementation details. For complete guidelines, see the verification checklist.
  ```
- **Audience**: Developers implementing features, Copilot

### 5. docs/examples/*.md (Code Examples)
- **Purpose**: Working code examples and tutorials
- **Content**: Real code samples, patterns, how-to guides
- **Usage**: Learning by example, reference for implementation
- **Pattern**: Each example starts with:
  ```markdown
  # {Feature} Example

  **For complete guidelines, see: [ai_agent/VERIFICATION_CHECKLIST.md](../../ai_agent/VERIFICATION_CHECKLIST.md#{anchor})**

  [Description and code examples]
  ```
- **Audience**: Developers learning, reference material

### 6. .github/copilot-instructions.md
- **Purpose**: Guides GitHub Copilot reviews
- **Content**: Points to verification checklist and references
- **Usage**: Copilot reads this during code reviews
- **Relation**: Tells Copilot to use ai_agent/* as source of truth

## DRY Principle: Rules

1. **One Rule, One Place**: Every rule/requirement lives in VERIFICATION_CHECKLIST.md only
2. **Reference Pattern**: Other files REFERENCE the checklist, never duplicate
3. **Link Format**: Always link with markdown reference:
   ```markdown
   See [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md#{anchor}) for details
   ```
4. **Updates**: When changing a rule:
   - Update VERIFICATION_CHECKLIST.md
   - Update SELF_REVIEW_CHECKLIST.md (if critical)
   - Skills and examples reference automatically (no changes needed)

## How to Add a New Skill

1. Create file: `ai_agent/skills/{category}/{name}.md`
2. Start with template:
   ```markdown
   # {Name} Skill

   **Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md#{anchor})**

   This skill provides {topic} implementation details. For complete guidelines, see the verification checklist.

   ## Dependencies
   [List dependencies]

   ## [Section 1]
   [Implementation details and patterns]

   ## [Section 2]
   [More patterns]
   ```
3. Reference the checklist section relevant to your skill
4. Avoid duplicating any rules - if a rule exists elsewhere, link to it
5. Update `entrypoint.md` skill index to include new skill

## How to Add New Documentation/Examples

1. Start with checklist reference at top:
   ```markdown
   **For complete guidelines, see: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md#{anchor})**
   ```
2. Only provide examples or supplementary content
3. Never duplicate rules from the checklist
4. Link back to checklists for requirements

## How to Update Rules

When you need to change or add a rule:

1. **Update VERIFICATION_CHECKLIST.md** with the new rule
2. **Update SELF_REVIEW_CHECKLIST.md** if it's a critical item
3. **No other files need updating** - they reference the checklists
4. Run through all files to ensure no duplication exists
5. Use GitHub to notify team: "Rule updated in VERIFICATION_CHECKLIST - impacts {skill areas}"

## Checklist Anchor Links

Use these anchors when referencing the verification checklist:

- `#-architecture--organization` - Controllers, Operations, Models, Contracts
- `#-frontend` - Views, Components, Stimulus, Styling
- `#-internationalization-i18n` - I18n guidelines
- `#-turbo-frames` - Turbo Frames patterns
- `#controllers` - Controllers specifically
- `#operations-trailblazer` - Operations specifically
- `#models` - Models specifically
- `#contracts-dry-validation` - Contracts specifically
- `#views` - Views specifically
- `#components` - Components specifically
- `#stimulus` - Stimulus controllers
- `#styling` - CSS/Tailwind

## Maintenance Checklist

Monthly:
- [ ] No duplicate rules across files
- [ ] All skills reference VERIFICATION_CHECKLIST
- [ ] All examples reference checklists
- [ ] Links are valid and point to correct anchors
- [ ] entrypoint.md skill index is complete and up-to-date

Before releasing new version:
- [ ] VERIFICATION_CHECKLIST.md reviewed
- [ ] SELF_REVIEW_CHECKLIST.md aligned
- [ ] GitHub Copilot instructions accurate
- [ ] All skills updated with checklist references
- [ ] No rule duplication across docs/

## File Size Guidelines

- **VERIFICATION_CHECKLIST.md**: ~150 lines (comprehensive but focused)
- **SELF_REVIEW_CHECKLIST.md**: ~30 lines (critical issues only)
- **Skill files**: 50-150 lines each (focused on one topic)
- **Example files**: 100-200 lines (code-heavy)

If any file gets longer, consider splitting it and creating cross-references.

## Questions to Ask When Creating Documentation

1. Does a rule for this already exist in VERIFICATION_CHECKLIST.md?
   - YES → Link to it, don't repeat
   - NO → Add it to VERIFICATION_CHECKLIST.md, then reference it elsewhere

2. Is this implementation details or a requirement?
   - Requirement → Goes in VERIFICATION_CHECKLIST.md
   - Details → Goes in skills/ with reference to checklist

3. Is this a code example?
   - YES → Goes in docs/examples/ with checklist reference

4. Will this need to be checked/verified?
   - YES → Add to VERIFICATION_CHECKLIST.md as a checklist item

## References Used in This Project

- **Papyro**: Web publishing platform
- **Rails 8**: Framework
- **Trailblazer 2.1**: Operations & contracts
- **Hotwire**: Frontend (Turbo + Stimulus)
- **Phlex**: Component framework
- **dry-validation**: Validation library
- **SQLite**: Database with production optimizations
