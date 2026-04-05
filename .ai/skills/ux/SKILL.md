---
name: ux
description: UX investigation, synthesis, and review patterns for Papyro interfaces. Use when creating UX briefs, translating UX research artifacts into actionable guidance, reviewing UI/UX quality, or defining page-level experience principles before implementation. Follows editorial, calm, content-first design principles with accessibility-first heuristics.
---

# UX/UI (Papyro)

## Dependencies
- phlex
- phlex-rails
- tailwindcss-rails

## Source of Truth
- Use `docs/Papyro UX.pdf` as a primary investigation artifact for product-direction decisions.
- Use [design-brief-template.md](references/design-brief-template.md) to define UX intent before implementation.
- Use [ux-investigation-synthesis.md](references/ux-investigation-synthesis.md) to ground decisions in documented artifacts.
- Use [ux-review-checklist.md](references/ux-review-checklist.md) to review UX quality before delivery.

## Workflow
1. Fill the UX brief first using [design-brief-template.md](references/design-brief-template.md).
2. Validate assumptions against [ux-investigation-synthesis.md](references/ux-investigation-synthesis.md).
3. Implement with frontend/design-system skills after UX intent is explicit.
4. Run final UX review with [ux-review-checklist.md](references/ux-review-checklist.md).

## Scope Boundaries
- This skill defines UX intent, information clarity, interaction expectations, and acceptance criteria.
- Component-level implementation belongs to `design-system` and `frontend` skills.
- Visual stylistic direction belongs to `frontend-design` once UX intent is fixed.

See [Frontend rules](../../VERIFICATION_CHECKLIST.md#-frontend) and [I18n rules](../../VERIFICATION_CHECKLIST.md#-internationalization-i18n).
