# UX/UI Skill (Papyro)

**Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md#-frontend) and [UI_UX_BRIEF.md](../../UI_UX_BRIEF.md)**

This skill provides UX/UI patterns. For complete project guidelines, see the verification checklist.

## Dependencies
- phlex
- phlex-rails
- tailwindcss-rails

## Source of Truth
Use [UI_UX_BRIEF.md](../../UI_UX_BRIEF.md) as the design brief.

## Guidance (Examples)
- Generate views after the brief is filled
- Keep layouts editorial, calm, and content-first
- Prefer whitespace and typography over decorative UI
- Use shadcn/ui-style components via `app/components/ui/`
- Ensure copy uses i18n keys (see checklist)

## View Generation Checklist (Example)
- Hero: clear headline + short supporting line
- Primary CTA: single, focused action
- Typography: consistent type scale
- Grid: simple, readable structure
- Components: use `Components::Ui::*`
- Accessibility: proper headings, labels, and focus states

See [Frontend rules](../../VERIFICATION_CHECKLIST.md#-frontend) and [I18n rules](../../VERIFICATION_CHECKLIST.md#-internationalization-i18n).

## Required Inputs
- Brand adjectives + mission
- Type scale + colors
- Page archetypes
- 2–3 reference links
- Sample copy
