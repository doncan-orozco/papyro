# UX Review Checklist (Papyro)

Use this checklist for design reviews, implementation reviews, and pre-merge UX verification.

## 1. Intent and Clarity

- Page purpose is clear in one glance.
- User can identify the primary action within 5 seconds.
- Headline and supporting text are concise and non-redundant.
- Information hierarchy matches task priority.

## 2. Task Flow Quality

- Happy path is obvious and low-friction.
- Non-happy paths are defined: empty, loading, error, partial success.
- Critical decisions include context and consequence cues.
- Actions are reversible when risk is non-trivial.
- Guest and registered-user capabilities are clearly separated.

## 3. Readability and Layout

- Scannability is strong (clear headings, spacing rhythm, grouping).
- Typography supports hierarchy and long-form readability.
- Visual density is controlled; no unnecessary decorative noise.
- Layout is responsive without losing task clarity.
- Reading comfort is preserved on mobile long-form content.
- Reading-time or equivalent comprehension aid is present where useful.

## 4. Interaction and Feedback

- Hover, focus, active, disabled states are coherent.
- Async actions provide visible progress and completion feedback.
- Validation and errors are specific and actionable.
- Keyboard interaction paths are complete and logical.
- No intrusive interruption patterns exist in reading contexts.

## 5. Accessibility

- Semantic structure is correct (headings, lists, landmarks).
- Focus indicators are visible and predictable.
- Contrast meets WCAG AA for text and controls.
- Screen reader labels and announcements are adequate.

## 6. Language and Localization

- No hardcoded user-facing strings in implementation.
- Translation keys are defined for both English and Spanish.
- Labels and helper text are plain-language and unambiguous.
- Error copy explains next steps, not just failure.
- AI-assisted content disclosure copy is present when relevant.

## 7. Pattern Consistency

- Existing UI patterns are reused where appropriate.
- New patterns include rationale and reuse criteria.
- Component usage aligns with design-system semantics.
- No contradictory interaction conventions across similar screens.
- Subscription and recommendation patterns avoid spam-like pressure.

## 8. Release Readiness

- UX acceptance criteria from the brief are met.
- Remaining UX debt is documented with impact and priority.
- QA notes include edge cases and accessibility checks.
- Final reviewer can explain why this experience is better for users.

## Quick Scoring

Use a simple score for each section:

- 2 = meets standard
- 1 = partially meets standard
- 0 = does not meet standard

Minimum recommended release threshold: 12/16, with no zero in Accessibility.
