---
name: frontend
description: Frontend development with Hotwire, Phlex, and Tailwind CSS. Use when creating views, components, or implementing frontend features. Covers Phlex file structure, component patterns, view patterns, Stimulus controllers, and Turbo integration.
---

# Frontend (Hotwire + Phlex + Tailwind)

Use this skill for application-facing frontend work. Keep the SKILL body focused on the rules that must hold across all views and components, then load the references for concrete implementation details.

## Non-Negotiable Rules

- Development runs on port `3030` via `bin/dev`.
- Views live in `app/views/`, inherit from `Views::Base`, and use fully-qualified i18n keys.
- Components live in `app/components/`, inherit from `Components::Base`, and accept `**attrs` when they render DOM elements.
- Multi-part UI components use the compound helper pattern; views call parent helpers, not child `.new` calls.
- Stimulus defaults for interactive compound components belong in component helper methods, not repeated across views.
- Interactive overlays should use stable fixed positioning and avoid animating `top`/`left`.
- Use `link_to` for navigation instead of raw anchor tags.
- Keep Tailwind usage semantic and aligned with the design system.

## Practical Workflow

1. Decide whether the work belongs in a view, reusable component, or Stimulus controller.
2. Load the matching reference file below.
3. Implement with explicit data flow from controller to view/component.
4. If the feature is interactive, wire `data-*` defaults through the component and keep behavior in Stimulus.
5. Recheck against [../../copilot-instructions.md](/.github/copilot-instructions.md).

## Reference Map

- **[references/views.md](references/views.md)**
  Use for view namespaces, controller-to-view integration, and page composition patterns.
- **[references/components.md](references/components.md)**
  Use for component conventions, `initialize(**attrs)`, and compound-component usage.
- **[references/stimulus.md](references/stimulus.md)**
  Use for Stimulus structure, registration, targets, values, and behavior patterns.
- **[references/form-snapshot.md](references/form-snapshot.md)**
  Use when working on complex forms and preserving existing UI/form structure during refactors.

## Companion Skills

- **[../design-system/SKILL.md](../design-system/SKILL.md)** for base UI components and semantic tokens
- **[../frontend-design/SKILL.md](../frontend-design/SKILL.md)** for visual direction and higher-polish interface work
- **[../turbo/SKILL.md](../turbo/SKILL.md)** for frame decomposition and Turbo interaction patterns
- **[../i18n/SKILL.md](../i18n/SKILL.md)** for translation structure and key rules

## Fast Review Heuristics

- If a controller is shaping UI state instead of passing explicit data, the frontend boundary is probably wrong.
- If a view repeats the same DOM pattern in multiple places, it probably wants a component.
- If a component owns behavior but not markup defaults, the Stimulus integration is probably leaking into the view layer.
- If a link is written as raw `<a>`, it is probably missing Rails/Turbo behavior.

For verification checklists, see [../../copilot-instructions.md](/.github/copilot-instructions.md).
