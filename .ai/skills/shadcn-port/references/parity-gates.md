# Parity gates

A component is DONE when every gate passes. Gates are scripts; agents only fix and triage.

| Gate | What | Tool | Fails with |
|---|---|---|---|
| **G1 static** | Tailwind tokens identical, no extra tokens, `data-slot`s, parts, variant options, defaults, kwargs, no hardcoded colors | `ruby .claude/scripts/shadcn/static_gate.rb --component NAME` | `G1_*` |
| **G2 DOM + style** | For every scenario: same nodes (by `data-slot`), tag, classes, attrs (aria/data/role), id wiring, text, visibility, boxes (0.5px), 45 computed style props | `node parity_run.mjs --component NAME` | `CLASS ATTR A11Y_REL TEXT VISIBLE BOX STYLE NODE_COUNT TAG SLOT_ORDER` |
| **G3 behavior** | Same steps (click, hover, Tab, keys, typing) produce the same snapshot after every step: state attrs, focus target, open/close, scroll lock, roving focus, typeahead, dismissal | same run (steps in the scenario) | `FOCUS FOCUSED SCROLL_LOCK VISIBLE ATTR` at a step > 0, `PHLEX_JS_ERROR` |
| **G4 theme** | Re-run G2 on the default scenarios with each preset in `app/assets/tailwind/theme/presets/` (slate, stone, zinc-radius0) and `--dark` | `parity_run.mjs --theme slate [--dark]` | `STYLE` |
| **G5 house (per wave and final)** | All previously DONE components still pass G1+G2 (regression), host test suite and rubocop green, catalog complete, importmap pins resolve, no unused controllers, deviations register consistent | `/shadcn-audit all --house` | `G5_*` |

## Severity

Every gate finding is MANDATORY. There is no advisory tier for G1-G4. (Advisory findings exist only for code quality items reported by the auditor on top of gates, tagged `Q_*`.)

## Triage vocabulary (for `shadcn-parity-auditor`)

For each failing diff the auditor assigns exactly one `cause` and a `fix_target`:

- `cause`: `CLASS_DRIFT` (token mismatch), `STRUCTURE` (wrong tag/nesting/missing wrapper), `ATTR_MAPPING` (aria/data not set or set on wrong element), `STATE_CLASS` (state attr present but class conditional wrong), `BEHAVIOR_MISSING` (no keyboard/dismiss/focus), `BEHAVIOR_TIMING` (race, rAF, Presence), `POSITIONING` (floating-ui options/offsets/collision), `THEME` (hardcoded value), `API` (kwarg/variant), `HARNESS` (scenario or renderer bug; not a port bug), `ORACLE_NOISE` (React-only non-determinism; add to ignore list with proof).
- `fix_target`: file + the smallest change.

`HARNESS` and `ORACLE_NOISE` verdicts require evidence (a second run on the oracle alone that is unstable, or a renderer unit failure); otherwise the port is wrong.

## Harness contract

- React: `react-shadcn-catalog` serves `/#/parity/<component>/<scenarioId>` which renders `tree` through `import.meta.glob("/src/components/ui/*.tsx")`; no chrome except the tree. Body has `class="bg-background text-foreground"`.
- Phlex: dev/test-only route `GET /design-system/parity/:component/:scenario` -> `Views::DesignSystem::Parity::Show` -> `Components::Parity::TreeRenderer` reading the same JSON and applying `api-mapping.md`. Same body classes, same fonts, same CSS variables source (generated from one file; see theme-contract.md).
- Both pages load the same font files and set `html { font-size: 16px }`.
- Runner ignores: `id`, `for`, Stimulus/Turbo/React attributes (regex in `parity_run.mjs`); ids are compared structurally through `A11Y_REL`.
- Not compared: scrollbar rendering, subpixel text anti-aliasing (boxes rounded to 0.5px), `data-radix-*` internals.

## Reports

`tmp/shadcn-port/<component>/{g1.json,g2.json,g4-<theme>.json,triage.json}` and `shots/` (optional PNG pairs). `docs/shadcn-port/state.json` stores per component: `status` (`pending|planned|built|fixing|done|blocked`), `iteration`, `last_green_sha`, `oracle_sha`, `blocked_reason`.
