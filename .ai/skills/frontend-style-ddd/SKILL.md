---
name: frontend-style-ddd
description: Domain-driven stylesheet organization for Tailwind and CSS in Papyro. Use when adding or refactoring styles to avoid monolithic files and keep style ownership aligned with bounded contexts.
---

# Frontend Style DDD

Use this skill when creating or editing styles in Papyro.

## Non-Negotiable Rules

- Do not add domain styles directly to `app/assets/tailwind/application.css`.
- Keep `app/assets/tailwind/application.css` as an import manifest and shared bootstrap only.
- Place style rules in bounded-context files under `app/assets/tailwind/domains/`.
- Place cross-domain UI primitives under `app/assets/tailwind/components/`.
- Place global theme tokens and base layer rules under `app/assets/tailwind/foundation/`.
- Place shared animation/behavior utilities under `app/assets/tailwind/utilities/`.
- Import files explicitly from the manifest in stable order.

## Required Structure

```text
app/assets/tailwind/
  application.css                   # manifest only
  foundation/
    theme.css                       # :root, @theme, dark mode, @layer base
  components/
    ui-scroll-area.css              # cross-domain component styles
  domains/
    articles/
      reader.css                    # article-specific typography/layout
    studio/
      ...                           # studio-specific styles
    users/
      ...                           # user profile/account styles
  utilities/
    motion.css                      # shared keyframes/state utilities
```

## Placement Decision Tree

1. Is this token/base reset/theme behavior?
   Put it in `foundation/`.
2. Is this reusable across many domains (UI primitive)?
   Put it in `components/`.
3. Is this tied to one bounded context (articles/studio/users)?
   Put it in `domains/<context>/`.
4. Is this a reusable utility animation/state helper?
   Put it in `utilities/`.

## Workflow

1. Identify domain ownership of the style change.
2. Create or update the domain/component file (not the manifest).
3. Add import in `app/assets/tailwind/application.css` if new file.
4. Keep selectors scoped (for example, `.article-prose`, `.studio-dashboard`).
5. Run focused tests and visually verify affected page.

## Anti-Patterns (Forbidden)

- Appending all new CSS to `application.css`.
- Mixing unrelated domains in one file.
- Using global selectors for domain-specific UI.
- Duplicating the same utility rules in multiple domain files.

## Example

- `Articles::Show` typography belongs in `domains/articles/reader.css`.
- Shared custom scrollbar rules belong in `components/ui-scroll-area.css`.
- Theme variables and dark mode belong in `foundation/theme.css`.

## Companion Skills

- **[../phlex-view-pattern/SKILL.md](../phlex-view-pattern/SKILL.md)** — **PRIMARY view structure source**: Golden archetype for all Phlex views and components. Load this first for any work in `app/views/` or `app/components/`. This stylesheet skill defers to the view/component shape defined by phlex-view-pattern.
