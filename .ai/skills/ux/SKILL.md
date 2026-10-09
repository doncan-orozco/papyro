---
name: ux
description: "UX investigation, synthesis, and review patterns for Papyro interfaces. Use when creating UX briefs, translating UX research artifacts into actionable guidance, reviewing UI/UX quality, or defining page-level experience principles before implementation. Follows editorial, calm, content-first design principles with accessibility-first heuristics."
---

# UX/UI (Papyro)

Use this skill to define intent and review experience quality before or alongside implementation. Keep the SKILL body as the routing layer and load the references for the actual brief, synthesis, or review artifact.

## Quick Rules

Cite as `ux R<n>`. Detail and examples follow below / in references/.

R1. **Brief first.** Page work starts from a design brief stating user goal, page purpose, success criteria and interaction principles. → detail: references/design-brief-template.md
R2. **Clear primary action.** Page purpose and the primary action are identifiable at a glance, with hierarchy matching task priority. → detail: references/ux-review-checklist.md (1. Intent and Clarity)
R3. **Non-happy paths defined.** Empty, loading, error and partial-success states are designed, and risky actions are reversible or carry consequence cues. → detail: references/ux-review-checklist.md (2. Task Flow Quality)
R4. **Feedback and keyboard.** Async actions show progress and completion, errors are specific and actionable, and keyboard paths are complete. → detail: references/ux-review-checklist.md (4. Interaction and Feedback)
R5. **Accessibility baseline.** Semantic structure, visible focus, WCAG AA contrast and screen-reader labels are present; accessibility scores no zero. → detail: references/ux-review-checklist.md (5. Accessibility)
R6. **No hardcoded strings.** User-facing text uses translation keys defined in both English and Spanish. → detail: references/ux-review-checklist.md (6. Language and Localization)
R7. **Reuse patterns.** Existing UI patterns and design-system semantics are reused; new patterns state rationale and reuse criteria. → detail: references/ux-review-checklist.md (7. Pattern Consistency)
R8. **Release threshold.** Review scores at least 12/16 with UX debt documented and brief acceptance criteria met. → detail: references/ux-review-checklist.md (8. Release Readiness / Quick Scoring)

## Core Role

This skill defines:
- page-level experience goals
- information clarity and interaction expectations
- review criteria before delivery

This skill does not define:
- low-level component implementation
- visual token choices for the design system
- code-level frontend structure

## Workflow

1. Start with the brief template.
2. Validate assumptions against the research synthesis.
3. Hand implementation work to the frontend/design-system skills once intent is explicit.
4. Run the UX review checklist before delivery.

## Reference Map

- **[references/design-brief-template.md](references/design-brief-template.md)**
  Use to define user goal, page purpose, success criteria, and interaction principles before implementation.
- **[references/ux-investigation-synthesis.md](references/ux-investigation-synthesis.md)**
  Use to ground decisions in existing repository research and product artifacts.
- **[references/ux-review-checklist.md](references/ux-review-checklist.md)**
  Use for final UX review and acceptance checks.

## Source of Truth

- `docs/Papyro UX.pdf` remains the primary artifact for product-direction decisions.
- Pair this skill with **[../phlex-view-pattern/references/frontend-overview.md](../phlex-view-pattern/references/frontend-overview.md)** and **[../design-system/SKILL.md](../design-system/SKILL.md)** once UX intent is fixed.

See [Frontend rules](/.github/copilot-instructions.md#-frontend) and [I18n rules](/.github/copilot-instructions.md#-internationalization-i18n).
