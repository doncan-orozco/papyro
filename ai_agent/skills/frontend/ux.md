# UX/UI Skill (Papyro)

## Dependencies
- phlex
- phlex-rails
- tailwindcss-rails

## Source of Truth
Use [docs/ui-ux-brief.md](docs/ui-ux-brief.md) as the design brief.

## Rules
- Generate views only after the brief is filled.
- Keep layouts editorial, calm, and content‑first.
- Prefer whitespace and typography over decorative UI.
- Use shadcn/ui‑style components via `app/components/ui/`.
- All copy must use i18n keys.

## View Generation Checklist
- Hero: clear headline + short supporting line
- Primary CTA: single, focused action
- Typography: consistent type scale
- Grid: simple, readable structure
- Components: use `Components::Ui::*`
- Accessibility: proper headings, labels, and focus states

## Required Inputs
- Brand adjectives + mission
- Type scale + colors
- Page archetypes
- 2–3 reference links
- Sample copy
