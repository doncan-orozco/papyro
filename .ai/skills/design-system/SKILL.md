---
name: design-system
description: "Papyro design system built on the shadcn/ui port: `Chadcn` from the chadcn gem (doncan-orozco/chadcn, `lib/chadcn/*`) with 1:1 React API (`Dialog`, `Dialog::Trigger`, `Dialog::Content`), semantic tokens, shadcn-format theme variables and the `chadcn--` Stimulus controllers. Use when composing chadcn components in views, or touching theme tokens."
---

# Design System (shadcn/ui port: `Chadcn`)

The design system is a **1:1 Phlex port of shadcn/ui (new-york-v4, Radix)**. How a component is ported, verified and kept faithful is owned by `shadcn-port` (API, classes, themes, gates) and `radix-stimulus` (behavior). This skill is the day-to-day contract for **writing and using** chadcn components.

> The gem, its port tooling (`/shadcn-*`) and the skills `shadcn-port`, `radix-stimulus` and `ruby-gem-conventions` live in **doncan-orozco/chadcn** (sibling checkout `../chadcn`). Paths below such as `lib/chadcn/` are inside that repository; component changes are made, audited and released there. In Papyro this skill governs using the components and the theme.

## Applies to
- when: `app/components/ui/**/*`
- when: `app/{views,components}/**/*.rb` matching `/Chadcn::/`
- when: `app/assets/tailwind/**/*`
- system-review: never
- note: The port itself (`shadcn-port`, `radix-stimulus`, `/shadcn-audit`) lives in doncan-orozco/chadcn; here the skill governs composing `Chadcn::*` and the theme files.

## Quick Rules

Cite as `design-system R<n>`.

R1. **Semantic tokens only.** `bg-primary`, `text-muted-foreground`, `border-input`...; no palette classes, hex or rgb. The only color classes allowed are the ones the shadcn source itself uses (`text-white`, `bg-black/50`). → `shadcn-port` R9
R2. **Namespace and location.** Components live in `chadcn: lib/chadcn/` as `Chadcn::<Name>`, every part inherits `Chadcn::Base` (cn, attribute merging, `render_as_child`); Stimulus identifiers are `chadcn--<name>`, controllers in `chadcn: app/javascript/controllers/chadcn/`. → `shadcn-port` R15
R3. **Same API as React.** One Ruby class per React export: `Dialog` -> `Chadcn::Dialog`, `DialogContent` -> `Chadcn::Dialog::Content`, `DropdownMenuCheckboxItem` -> `DropdownMenu::CheckboxItem`. Props are snake_case kwargs; `className` -> `class:`; children -> block. → `shadcn-port` references/api-mapping.md
R4. **Two equivalent ways to compose parts; the classes are canonical, the helpers are sugar.** (a) Explicit: `render Chadcn::Dialog::Content.new(...) { }`, one class per React export (used by scenarios, tests, the harness, and always valid). (b) DX helpers: the root yields itself and `Chadcn::Base` GENERATES one helper per nested part, so `render Chadcn::Table.new do |table| table.header { table.row { table.head { "Name" } } } end` reads like the JSX tree. A helper is exactly `render Root::Part.new(**attrs), &block`: never hand-written, never adds behavior. Mixing both in one view is fine. → references/compound-components.md
R5. **`**attrs` everywhere.** Every class (root and each part) takes `**attrs`, passes them through, merges `class` via `cn` (caller wins) and deep-merges `data:`/`aria:` with the component's required attributes.
R6. **Strings and symbols.** Variant-like options accept both (`variant: "outline"`, `variant: :outline`, `size: "icon-sm"`, `size: :icon_sm`); defaults equal the React `defaultVariants`.
R7. **`data-slot` on every part,** exactly the shadcn value, plus `data-variant`/`data-size` where the React source emits them.
R8. **No button inside a trigger part.** `Dialog::Trigger` renders its own `<button>`; never nest `Chadcn::Button` as its content. To render the trigger as a Button use React's own mechanism: `Dialog::Trigger.new(as_child: Chadcn::Button.new(variant: "outline"))`.
R9. **Behavior through Stimulus + shared primitives only.** No inline JS, no per-component copies of focus/dismiss/positioning logic. → `radix-stimulus`
R10. **Theme in shadcn format, one file.** Colors live only in `app/assets/tailwind/theme/theme.css` as `--primary: oklch(...)` in `:root`/`.dark`; `tokens.css` maps them to utilities and is never edited. Change the look with `bin/rails theme:use[preset]`, `theme:import[...]`, `theme:check`; a theme pasted from ui.shadcn.com works unchanged. Never put colors in components or other stylesheets. → `shadcn-port` references/theme-contract.md
R11. **Catalog.** Every chadcn component appears in the design-system catalog (`/design-system`), generated from the scenario files (no hand-written demos that can drift). Catalog copy is localized in `config/locales/{en,es}/design_system.yml`.
R12. **Generic UI only.** `Chadcn::*` has no domain knowledge. Domain composition belongs in `app/components/{public,shared,...}` following `phlex-view-pattern`.
R13. **Localized defaults.** Default strings shipped by shadcn (e.g. the sr-only "Close") are kwargs whose default equals the React string; app code passes `t(...)` through the kwarg. Components never call `t` themselves.
R14. **Verified, not eyeballed.** A chadcn component is correct only if `/shadcn-audit <name>` passes (G1-G4) in doncan-orozco/chadcn. In Papyro never patch a `Chadcn::*` look locally; change it upstream and bump the lock (`bundle update chadcn`).

## Using chadcn components (what a view looks like)

```ruby
render Chadcn::Dialog.new do
  render Chadcn::Dialog::Trigger.new(as_child: Chadcn::Button.new(variant: "outline")) { "Edit profile" }
  render Chadcn::Dialog::Content.new(class: "sm:max-w-[425px]") do
    render Chadcn::Dialog::Header.new do
      render Chadcn::Dialog::Title.new { "Edit profile" }
      render Chadcn::Dialog::Description.new { "Make changes to your profile here." }
    end
    render Chadcn::Dialog::Footer.new do
      render Chadcn::Button.new(type: "submit") { "Save changes" }
    end
  end
end
```
This mirrors the JSX tree one to one. The same tree with the generated helpers (the root yields itself; `Chadcn::Base` defines `trigger`, `content`, `header`, `title`, `description`, `footer`, `close`... from the nested classes):

```ruby
render Chadcn::Dialog.new do |dialog|
  dialog.trigger(as_child: Chadcn::Button.new(variant: "outline")) { "Edit profile" }
  dialog.content(class: "sm:max-w-[425px]") do
    dialog.header do
      dialog.title { "Edit profile" }
      dialog.description { "Make changes to your profile here." }
    end
    dialog.footer { render Chadcn::Button.new(type: "submit") { "Save changes" } }
  end
end
```
Components that are not compound parts (`Button`, `Input`...) are always rendered by their class. Each spec lists its helpers in the derived "DX helpers" section (`chadcn: .claude/scripts/shadcn/spec_helpers.rb`).

## Companion skills

- `shadcn-port` (chadcn repo): the port contract, gates, scenarios, theme.
- `radix-stimulus` (chadcn repo): behavior spec and shared primitives.
- `stimulus`: controller lifecycle, targets/values, Turbo.
- `phlex-view-pattern`: dumb views, presenters, domain components.
- `accessibility`: WCAG checks beyond Radix parity.

## Quick commit check

- Gem changes: `/shadcn-audit changed` green in doncan-orozco/chadcn and the host lock bumped; host views: `bin/rails test test/integration/chadcn_engine_test.rb test/integration/design_system_brand_test.rb` green
- `ruby .claude/scripts/ui/legacy_ui_refs.rb` prints nothing (bin/ci runs it)
- Catalog regenerated, locale keys present in both languages
