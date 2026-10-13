---
name: shadcn-port
description: "Contract for the 1:1 shadcn/ui -> Phlex port: oracle-first, identical API, verbatim Tailwind classes, data-slot, variants and states, and theme compatibility. Use when creating, editing or auditing `gems/phlex-shadcn/lib/phlex/shadcn/*` as part of the shadcn port, `docs/shadcn-port/**`, or running /shadcn-plan, /shadcn-run, /shadcn-audit."
---

# shadcn -> Phlex port contract

The React shadcn component (registry style `new-york-v4`, Radix base) is the **oracle**. A Phlex component is correct only if it is indistinguishable from it: same API, same DOM, same computed style, same behavior, same theme response. "Looks similar" is a failure.

## Quick Rules

Cite as `shadcn-port R<n>`.

R1. **Oracle first.** Never write a class string, variant, default or prop from memory, and never from the legacy `app/components/ui/*`. Read `docs/shadcn-port/oracle/src/<name>.tsx` and `manifest/<name>.json`. → references/api-mapping.md
R2. **Verbatim classes.** Every Tailwind token of the React source appears unchanged in the port and no other token is added. Variant tables are copied key for key (`"icon-sm"` stays `"icon-sm"`). Deviations are only allowed through `docs/shadcn-port/deviations/<name>.json` with a reason. → references/parity-gates.md (G1)
R3. **Same API, mechanically mapped.** `className`->`class:`, camelCase props->snake_case kwargs, `children`->block, `asChild`->`as_child:` (false | tag symbol | component instance, Radix Slot merge in `Phlex::Shadcn::Base`), `defaultX`->`default_x:`, `onXChange`->dispatched `x-change` event, compound exports `DialogContent`->`Dialog::Content` (the name rule lives in one place). → references/api-mapping.md
R4. **Accept both string and symbol options.** `variant: :outline` and `variant: "outline"`, `size: "icon-sm"` and `size: :icon_sm` behave identically; defaults equal `defaultVariants`.
R5. **`data-slot` on every part,** with the exact value of the React source, on the same element.
R6. **`**attrs` pass through on every part** (merged, never overwritten): `class` goes through `cn` (tailwind_merge) last so callers win; `data`/`aria` hashes deep-merge with required component data.
R7. **Same DOM, not same look.** Tag, role, aria-*, `data-state/side/align/orientation/disabled/...`, id wiring (`aria-labelledby`, `aria-controls`) and DOM order match the Radix output, including portal content and hidden parts. → references/radix-dom-contract.md
R8. **Every state in the matrix.** Each cva variant x size, each Radix state (`open/closed`, `checked/unchecked/indeterminate`, `active/inactive`, `on/off`, `disabled`, `aria-invalid`, orientation, side/align), with/without icon, dark mode. The scenario file lists them; none may be skipped. → references/state-matrix.md
R9. **Theme-neutral.** Only semantic tokens/CSS variables from the shadcn v4 contract (`--background`, `--primary`, `--radius`, `--chart-*`, `--sidebar-*`...) via `@theme inline`. Pasting any theme from ui.shadcn.com/themes into the host stylesheet must restyle the port with no code change. → references/theme-contract.md
R10. **Behavior lives in Stimulus, shared logic in primitives.** One controller per interactive component under `gems/phlex-shadcn/app/javascript/controllers/shadcn/`, built on the shared primitives (`gems/phlex-shadcn/app/javascript/shadcn/primitives/*`). No inline JS, no per-component copies of focus-trap/positioning/dismiss logic. Rules for the controller itself: see `stimulus`; Radix behavior map: see `radix-stimulus`.
R11. **Scenario file is the shared truth.** `docs/shadcn-port/scenarios/<name>.json` is rendered by BOTH the React harness and the Phlex harness. A component without a complete scenario file is not done.
R12. **Gates decide, not opinion.** A component is DONE only when G1 static, G2 DOM/style, G3 behavior and G4 theme gates pass (G5 house gate per wave). Reviewers triage gate output; they do not overrule it. → references/parity-gates.md
R13. **Ownership.** A builder touches only its component's files (`gems/phlex-shadcn/lib/phlex/shadcn/<name>*.rb`, `gems/phlex-shadcn/app/javascript/controllers/shadcn/<name>_controller.js`, its scenario file, its deviations file, tests). Shared files (importmap, catalog index, locales, stylesheets, primitives) are changed only by the orchestrator or the infra wave.
R14. **Third-party parts are wrapped, not rewritten.** Where shadcn wraps a library (cmdk, sonner, embla, react-day-picker, vaul, input-otp, react-resizable-panels, recharts), use a pinned JS equivalent behind a Stimulus controller and document the mapping in the spec.
R15. **From scratch, in `Phlex::Shadcn`.** The port lives in `gems/phlex-shadcn/lib/phlex/shadcn/` (namespace `Phlex::Shadcn`, Stimulus identifiers `shadcn--<name>`, events `shadcn--<name>:<event>`, primitives `gems/phlex-shadcn/app/javascript/shadcn/`). The legacy `app/components/ui/*` and `controllers/ui/*` are frozen: planners and builders never open, copy or import them, so none of their errors carry over. Port components may only depend on other `Phlex::Shadcn` components, Phlex and tailwind_merge (never on host constants). Migrating callers from `Ui` to `V2` is a separate, later step (`CALLERS.md`), never part of a component task.
R16. **DX helpers are generated, never written.** Every compound root `yield self`s and `Phlex::Shadcn::Base` generates one helper per nested part (`table.header`, `dialog.content`...), equal to the explicit class call. Specs carry the derived list (`spec_helpers.rb`); the unit test asserts each helper renders the same HTML as its class; gate G2b (`parity_run.mjs --dx helpers`) proves the helper path against React. → references/api-mapping.md

## Where things live

| Thing | Path |
|---|---|
| Oracle (generated, committed) | `docs/shadcn-port/oracle/{registry,src,manifest}/`, `graph.json` |
| Spec per component | `docs/shadcn-port/specs/<name>.md` |
| Scenarios (shared) | `docs/shadcn-port/scenarios/<name>.json` |
| Deviations | `docs/shadcn-port/deviations/<name>.json` + register in `docs/shadcn-port/DEVIATIONS.md` |
| Theme (developer-edited) / tokens / presets | `app/assets/tailwind/theme/{theme.css,tokens.css,presets/*.css}` |
| Run state | `docs/shadcn-port/state.json`, reports in `tmp/shadcn-port/<component>/` |
| React catalog (oracle renderer) | `react-shadcn-catalog/` |
| Phlex port | `gems/phlex-shadcn/lib/phlex/shadcn/<name>.rb` (+ `gems/phlex-shadcn/lib/phlex/shadcn/<name>/` for large parts); nested parts like `Dialog::Content` live in the same file |
| Stimulus | `gems/phlex-shadcn/app/javascript/controllers/shadcn/<name>_controller.js`, primitives in `gems/phlex-shadcn/app/javascript/shadcn/primitives/` |

## References (load on demand)

- `references/api-mapping.md`: React -> Ruby mapping table and examples (Button, Dialog, controlled/uncontrolled).
- `references/state-matrix.md`: how scenarios are derived (variants x sizes x states) and the scenario JSON format.
- `references/parity-gates.md`: gates G1-G5, finding codes, pass criteria, tools, harness contract.
- `references/theme-contract.md`: CSS variable set, `@theme inline`, dark mode, theme gate.
- `references/radix-dom-contract.md`: DOM/ARIA each Radix primitive emits that the port must reproduce.
