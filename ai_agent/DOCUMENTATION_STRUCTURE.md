# Documentation Structure & Hierarchy (Papyro)

**DRY Principle: Single Source of Truth for All Guidelines**

This document defines how Papyro documentation is organized and maintained. Follow this structure for all future documentation and skill files.

## Documentation Hierarchy

```
ai_agent/
├── VERIFICATION_CHECKLIST.md      ← ⭐ SINGLE SOURCE OF TRUTH (pure checklist)
│   └── Complete rules & requirements for all code review
│   └── References skill files for patterns and examples
│
├── CI_VERIFICATION.md             ← CI checks and troubleshooting
│   └── What CI runs, how to fix failures locally
│
├── entrypoint.md                  ← Entry point & orientation
│   └── Overview, skill index, quick rules
│
├── UI_UX_BRIEF.md                 ← Design system & UX guidelines
│   └── Product voice, visual system, page archetypes
│
├── DOCUMENTATION_STRUCTURE.md     ← This file
│   └── How to organize and maintain documentation
│
├── examples/                      ← Code examples & tutorials
│   ├── architecture-overview.md   → References VERIFICATION_CHECKLIST
│   ├── lint-and-tests.md          → References VERIFICATION_CHECKLIST
│   ├── components.md              → References VERIFICATION_CHECKLIST
│   ├── contracts.md               → References VERIFICATION_CHECKLIST
│   ├── controllers.md             → References VERIFICATION_CHECKLIST
│   ├── models.md                  → References VERIFICATION_CHECKLIST
│   ├── operations.md              → References VERIFICATION_CHECKLIST
│   ├── stimulus.md                → References VERIFICATION_CHECKLIST
│   ├── views.md                   → References VERIFICATION_CHECKLIST
│   └── i18n.md                    → References VERIFICATION_CHECKLIST
│
└── skills/                        ← Deep-dive implementation details
    ├── backend/
    │   ├── architecture.md        → References VERIFICATION_CHECKLIST
    │   ├── anti-patterns.md       → ❌ DO NOT / ✅ DO patterns (10 categories)
    │   ├── error-handling.md      → Error handling & authorization patterns
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
├── README.md                      ← Pointer to ai_agent/entrypoint.md
└── RAILS_MCP_SETUP.md             ← Infrastructure setup only

.github/
├── copilot-instructions.md        ← Tells GitHub Copilot to use checklists
└── PULL_REQUEST_TEMPLATE.md       ← Pre-commit checklist for PRs
```

## File Purposes

### 1. VERIFICATION_CHECKLIST.md (Source of Truth)
- **Purpose**: Pure verification checklist (DRY + Single Responsibility)
- **Content**:
  - Architecture patterns (Controllers, Operations, Models, Contracts)
  - Frontend guidelines (Views, Components, Stimulus, Styling)
  - I18n requirements (English + Spanish)
  - Turbo Frames patterns
  - References to skill files for detailed patterns
  - Pre-commit verification items
- **Usage**: Referenced by all other files; updated when guidelines change
- **Principle**: Checklist verifies, skills teach
- **Audience**: Code reviewers, developers, GitHub Copilot

### 2. skills/backend/anti-patterns.md (What NOT to Do)
- **Purpose**: Comprehensive ❌ WRONG / ✅ CORRECT examples
- **Content**: 10 anti-pattern categories with code examples
  - Model anti-patterns (business logic, validations, callbacks, scopes)
  - Operation anti-patterns (hardcoded messages, passing AR objects)
  - Service anti-patterns (implicit dependencies)
  - Controller anti-patterns (accessing internal ctx keys)
  - View anti-patterns (missing turbo frames, hardcoded strings)
  - Component anti-patterns (missing **attrs)
  - Testing anti-patterns (testing implementation details)
  - Security anti-patterns (authorization in Operations)
- **Usage**: Referenced from VERIFICATION_CHECKLIST
- **Audience**: Developers, Copilot

### 3. skills/backend/error-handling.md (Error & Auth Patterns)
- **Purpose**: Authorization and error handling patterns
- **Content**:
  - Authorization patterns (controller before_action)
  - Error handling patterns for controllers (pattern matching)
  - Error handling patterns for channels (transmit errors)
  - Error handling patterns for jobs (discard_on, retry)
  - Result extraction patterns (ctx[:model], ctx[:errors])
  - Context guidelines (required vs internal keys)
- **Usage**: Referenced from VERIFICATION_CHECKLIST
- **Audience**: Developers, Copilot

### 4. CI_VERIFICATION.md (CI Explanation)
- **Purpose**: Explains CI checks and troubleshooting
- **Content**: CI jobs, commands, fixes, expectations
- **Usage**: When CI fails or before pushing
- **Audience**: Developers and agents

### 5. entrypoint.md (Orientation)
- **Purpose**: Starting point for new team members
- **Content**:
  - Quick rules summary
  - Skill index (what file to read for each topic)
  - Verification checklist pointer
  - How to use the documentation
- **Usage**: First document to read
- **Audience**: New team members, anyone onboarding

### 6. skills/*.md (Deep-dive Implementation)
- **Purpose**: Implementation patterns and examples (no rules)
- **Content**: Code patterns, file structures, dependencies, conventions
- **Usage**: When implementing a feature in that area
- **Pattern**: Each skill file starts with:
  ```markdown
  # {Topic} Skill ({Framework/Library})

  **Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md#{anchor})**

  This skill provides implementation details. For complete guidelines, see the verification checklist.
  ```
- **Audience**: Developers implementing features, Copilot

### 7. UI_UX_BRIEF.md (Design System)
- **Purpose**: Design system and UX guidelines template
- **Content**: Brand voice, visual system, page archetypes, content samples
- **Usage**: Reference when implementing UI components and pages
- **References**: Points to VERIFICATION_CHECKLIST for required rules
- **Audience**: Developers, designers, AI agents implementing UI

### 7. examples/*.md (Code Examples)
- **Purpose**: Working code examples and tutorials
- **Content**: Real code samples, patterns, how-to guides
- **Usage**: Learning by example, reference for implementation
- **Pattern**: Each example starts with:
  ```markdown
  # {Feature} Example

  **For complete guidelines, see: [VERIFICATION_CHECKLIST.md](../VERIFICATION_CHECKLIST.md#{anchor})**

  [Description and code examples]
  ```
- **Audience**: Developers learning, reference material

### 8. .github/copilot-instructions.md
- **Purpose**: Guides GitHub Copilot reviews
- **Content**: Points to verification checklist and references
- **Usage**: Copilot reads this during code reviews
- **Relation**: Tells Copilot to use ai_agent/* as source of truth

### 9. .github/PULL_REQUEST_TEMPLATE.md
- **Purpose**: Pre-commit checklist for PR descriptions
- **Content**: Required checks and references
- **Usage**: Copy into PR description and mark as complete
- **Audience**: Humans and agents

## DRY Principle: Rules

1. **One Rule, One Place**: Every rule/requirement lives in VERIFICATION_CHECKLIST.md only
2. **Reference Pattern**: Other files REFERENCE the checklist, never duplicate
3. **Separation of Concerns**: 
   - VERIFICATION_CHECKLIST.md = Pure checklist format with references
   - skills/*.md = Comprehensive patterns and examples
   - Checklist links to skills for deep-dives
4. **Link Format**: Always link with markdown reference:
   ```markdown
   See [skills/backend/anti-patterns.md](skills/backend/anti-patterns.md) for details
   See [skills/backend/error-handling.md](skills/backend/error-handling.md) for patterns
   ```
5. **Updates**: When changing a rule:
   - Update VERIFICATION_CHECKLIST.md (pure checklist)
   - Update relevant skill file with patterns/examples
   - No duplication: checklist verifies, skills teach

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

1. **Update VERIFICATION_CHECKLIST.md** with the new checklist item
2. **Update relevant skill file** (e.g., anti-patterns.md, error-handling.md) with patterns/examples
3. **Maintain separation**: Checklist = verify, Skills = teach
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
- [ ] VERIFICATION_CHECKLIST is scannable (pure checklist format)

Before releasing new version:
- [ ] VERIFICATION_CHECKLIST.md reviewed
- [ ] GitHub Copilot instructions accurate
- [ ] All skills updated with checklist references
- [ ] No rule duplication across docs/
- [ ] Skill files contain all patterns/examples (not in checklist)

## File Size Guidelines
300 lines (scannable pure checklist with references)
- **skills/backend/anti-patterns.md**: ~400 lines (comprehensive ❌/✅ examples)
- **skills/backend/error-handling.md**: ~300 lines (error & auth patterns)
- **Other skill files**: 50-150 lines each (focused on one topic)
- **Example files**: 100-200 lines (code-heavy)

If any file gets longer, consider splitting it and creating cross-references.

**Key Principle**: Checklist should be 2-3 minute read, skill files are deep-div
If any file gets longer, consider splitting it and creating cross-references.

## Questions to Ask When Creating Documentation

1. Does a rule for this already exist in VERIFICATION_CHECKLIST.md?
   - YES → Link to it, don't repeat
   - NO → Add it to VERIFICATION_CHECKLIST.md, then reference it elsewhere

2. Is this implementation details or a requirement?
   - Requirement → Goes in VERIFICATION_CHECKLIST.md
   - Details → Goes in skills/ with reference to checklist

3. Is this a code example?
   - YES → Goes in ai_agent/examples/ with checklist reference

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
