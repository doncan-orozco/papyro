---
name: ux
description: UX investigation, synthesis, and review patterns for Papyro interfaces. Use when creating UX briefs, translating UX research artifacts into actionable guidance, reviewing UI/UX quality, or defining page-level experience principles before implementation. Follows editorial, calm, content-first design principles with accessibility-first heuristics.
---

# UX/UI (Papyro)

Use this skill to define intent and review experience quality before or alongside implementation. Keep the SKILL body as the routing layer and load the references for the actual brief, synthesis, or review artifact.

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
- Pair this skill with **[../frontend/SKILL.md](../frontend/SKILL.md)** and **[../design-system/SKILL.md](../design-system/SKILL.md)** once UX intent is fixed.
- Use **[../frontend-design/SKILL.md](../frontend-design/SKILL.md)** when the work also needs strong visual direction.

See [Frontend rules](/.github/copilot-instructions.md#-frontend) and [I18n rules](/.github/copilot-instructions.md#-internationalization-i18n).
