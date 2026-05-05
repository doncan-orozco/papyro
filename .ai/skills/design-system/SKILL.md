---
name: design-system
description: shadcn/ui design patterns translated to Phlex components for consistent UI development. Use when creating or modifying UI components in app/components/ui/. Covers button, card, badge, input, label, and other base component patterns with variants and composition. Includes guidance for pixel-perfect shadcn Radix UI conversion with semantic tokens, class-based dark mode via ui--theme Stimulus controller, and SHADCN_VERSION tracking.
---

# Design System (shadcn/ui + Phlex)

Use this skill for UI work in `app/components/ui/`. Keep the main body focused on non-negotiable rules and load the reference files for detailed examples.

## Non-Negotiable Rules

- Use semantic tokens such as `bg-primary`, `text-destructive`, and `bg-card`; do not hardcode palette classes.
- Keep the design system catalog updated in `app/views/design_system/index.rb` whenever a new component or variant is added.
- Add English and Spanish strings in `config/locales/{en,es}/design_system.yml` for catalog examples.
- Every component class that accepts keyword attributes must implement `initialize(**attrs)` and preserve caller attributes.
- Multi-part UI components must use the compound-component helper pattern; views should call helper methods like `card.header` or `dropdown.trigger`, not child `.new` calls.
- Interactive components must merge required Stimulus `data-*` defaults with caller data instead of overwriting it.
- Trigger helpers already render interactive elements; never nest `Components::Ui::Button` inside a compound trigger block.
- Use class-based dark mode through the `ui--theme` controller and semantic CSS tokens.
- Verify shadcn behavior against the real Radix UI source before translating it.

## Practical Workflow

1. Start with the target shadcn component and confirm the rendered structure.
2. Choose the right reference file below based on the component type.
3. Implement the Phlex component with semantic tokens and `**attrs` support.
4. If the component is interactive, wire the Stimulus defaults through the component helpers.
5. Add or update the design-system catalog demo and translations.
6. Validate behavior in the browser and against [../../copilot-instructions.md](/.github/copilot-instructions.md#-frontend).

## Reference Map

- **[references/shadcn-conversion-guide.md](references/shadcn-conversion-guide.md)**
  Use for the full conversion workflow, Radix verification, and common shadcn parity issues.
- **[references/compound-components.md](references/compound-components.md)**
  Use for the parent-yields-self helper pattern, nested child classes, migration examples, and the full compound-component checklist.
- **[references/stimulus-interactive-components.md](references/stimulus-interactive-components.md)**
  Use for Switch, Tabs, Accordion, Dropdown, Select, Tooltip, Dialog, and the Stimulus controller integration pattern.
- **[references/css-variables-guide.md](references/css-variables-guide.md)**
  Use for OKLCH tokens, `:root` / `html.dark` setup, shadow color behavior, and semantic color expansion.
- **[references/design-system.md](references/design-system.md)**
  Use for concrete component translations and usage examples for common base components.
- **[references/toast-notifications.md](references/toast-notifications.md)**
  Use for global flash toast notifications, Stimulus auto-dismiss behavior, and component composition.

## Examples

- **[examples/interactive-components-examples.md](examples/interactive-components-examples.md)**
  Copy-paste-ready examples for the currently implemented interactive component set.

## Component Selection Hints

- Load `compound-components.md` before building any component with child parts.
- Load `stimulus-interactive-components.md` before adding targets, actions, values, or keyboard behavior.
- Load `css-variables-guide.md` before introducing or changing color tokens.
- Load `shadcn-conversion-guide.md` when pixel parity with the source library matters.

## Quick Commit Check

- Catalog updated
- Locale files updated in both languages
- No hardcoded palette classes
- No missing `initialize(**attrs)` methods
- No nested button-inside-trigger invalid HTML

Rules live in the checklist: [../../copilot-instructions.md](/.github/copilot-instructions.md#-frontend)
