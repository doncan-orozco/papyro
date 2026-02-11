# Quick Reference: Adding New Skills/Documentation

**TL;DR for creating new documentation while maintaining DRY principles.**

## When to Create What

| Situation | Create | Location | Format |
|-----------|--------|----------|--------|
| Found a new rule/requirement | Add to VERIFICATION_CHECKLIST.md | `ai_agent/VERIFICATION_CHECKLIST.md` | Checklist item |
| Feature-specific implementation details | New skill file | `ai_agent/skills/{category}/{name}.md` | Implementation details |
| Working code examples | Example file | `ai_agent/examples/{name}.md` | Code + explanation |
| Troubleshooting/deep-dive | Update relevant skill | `ai_agent/skills/{category}/*.md` | Add section |

## Template: New Skill File

```markdown
# {Topic} Skill

**Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md#{anchor})**

This skill provides {description}. For complete guidelines, see the verification checklist.

## Dependencies
- library1
- library2

## {Section 1}
[Implementation patterns]

## {Section 2}
[More patterns]
```

## Template: New Example File

```markdown
# {Feature} Example

**For complete guidelines, see: [VERIFICATION_CHECKLIST.md](../VERIFICATION_CHECKLIST.md#{anchor})**

[Brief description]

## Code Example

[Code here]

## Explanation

[How it works]
```

## Before You Add Documentation

Ask these questions:

1. **Is this a rule/requirement?**
   - YES → Add to VERIFICATION_CHECKLIST.md
   - NO → Continue

2. **Does this rule already exist somewhere?**
   - YES → Don't duplicate! Just reference it
   - NO → Add to VERIFICATION_CHECKLIST.md

3. **Is this implementation details?**
   - YES → Create skill file or update existing
   - NO → Continue

4. **Is this a code example?**
   - YES → Create in ai_agent/examples/
   - NO → Continue

5. **Is this a new concept/area not covered?**
   - YES → Create new skill file
   - NO → Add to existing skill file

## Checklist: Adding a New Skill

- [ ] Skill file created in `ai_agent/skills/{category}/{name}.md`
- [ ] Header includes checklist reference
- [ ] No rules duplicated from VERIFICATION_CHECKLIST.md
- [ ] File links to relevant checklist sections
- [ ] `entrypoint.md` updated with skill index entry
- [ ] DOCUMENTATION_STRUCTURE.md anchor list updated (if new area)
- [ ] File is 50-150 lines (if >150, consider splitting)

## Checklist: Updating Rules

- [ ] Rule added/updated in VERIFICATION_CHECKLIST.md
- [ ] Relevant skill file updated (anti-patterns.md, error-handling.md, etc.) with patterns/examples
- [ ] entrypoint.md quick rules updated (if critical)
- [ ] All skills that reference this rule checked for accuracy
- [ ] All examples that reference this rule checked for accuracy
- [ ] No duplication of rules across files
- [ ] Separation maintained: Checklist verifies, skills teach

## Example: Adding a New Skill

**Scenario:** Need to document "Caching Strategy with Solid Cache"

**Steps:**

1. Add rules to VERIFICATION_CHECKLIST.md:
   ```markdown
   ## Caching (Solid Cache)
   - [ ] Use Solid Cache (Rails 8 native)
   - [ ] Cache keys should be domain-based
   - [ ] Invalidate on write in Operations
   ```

2. Create skill file:
   ```
   ai_agent/skills/backend/caching.md
   ```
   ```markdown
   # Caching Skill (Solid Cache)

   **Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md#caching-solid-cache)**

   This skill provides Solid Cache patterns for Rails 8.
   
   [Implementation details]
   ```

3. Update entrypoint.md:
   ```markdown
   - Backend caching (Solid Cache): skills/backend/caching.md
   ```

4. Create example file if needed:
   ```
   ai_agent/examples/caching.md
   ```

That's it! No other files need updating.

## Common Mistakes to Avoid

❌ **DON'T:**
- Duplicate rules from VERIFICATION_CHECKLIST.md in skills
- Create new documentation without referencing the checklist
- Add rules to skill files instead of the checklist
- Forget to update entrypoint.md skill index
- Create example files without checklist references

✅ **DO:**
- Reference VERIFICATION_CHECKLIST.md from all other files
- Keep skill files focused on implementation details
- Put all rules in VERIFICATION_CHECKLIST.md only
- Link back to checklists
- Update entrypoint.md when adding skills

## File Organization Quick Reference

```
ai_agent/
├── VERIFICATION_CHECKLIST.md      ← Pure checklist (verifies)
├── entrypoint.md                  ← Entry point
├── UI_UX_BRIEF.md                 ← Design system
├── DOCUMENTATION_STRUCTURE.md     ← This hierarchy
├── examples/                      ← Code examples
│   └── (Code examples only, reference checklists)
├── skills/
│   ├── backend/
│   │   ├── anti-patterns.md       ← What NOT to do
│   │   ├── error-handling.md      ← Error & auth patterns
│   │   └── (other backend skills)
│   ├── frontend/
│   ├── testing/
│   └── database/
└── (Skills teach, checklist verifies)

docs/
├── README.md                      ← Pointer to ai_agent/
└── RAILS_MCP_SETUP.md             ← Infrastructure only

.github/
└── copilot-instructions.md        ← Points to checklists
```

## Questions?

Refer to [DOCUMENTATION_STRUCTURE.md](DOCUMENTATION_STRUCTURE.md) for complete details.
