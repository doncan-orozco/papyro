# Shared primitives (`app/javascript/v2/primitives/`)

Built in **wave 0** (before any overlay), pinned in `config/importmap.rb` with `pin_all_from "app/javascript/v2", under: "v2"`. Each primitive is a plain ES module (no Stimulus dependency), exports small functions that return a `release()` cleanup, and is covered by a harness page `/design-system/parity/_primitives/<name>` + scenario file `docs/shadcn-port/scenarios/_primitives-<name>.json` compared against the same primitive in React (Radix package used raw in `react-shadcn-catalog/src/parity/primitives/`).

| Module | API sketch | Replaces (Radix) |
|---|---|---|
| `presence.js` | `presence(el, { onExited })` waits for animation/transition end after `data-state=closed` | `@radix-ui/react-presence` |
| `portal.js` | `portal(el, container = document.body)` + restore on release | `react-portal` |
| `dismissable_layer.js` | `dismissable(el, { onEscape, onPointerDownOutside, onFocusOutside, onDismiss, disableOutsidePointerEvents })`; layer stack so only the top layer reacts | `react-dismissable-layer` |
| `focus_scope.js` | `focusScope(el, { trapped, loop, onMountAutoFocus, onUnmountAutoFocus })` | `react-focus-scope` |
| `focus_guards.js` | sentinel spans at body edges while a modal layer is open | `react-focus-guards` |
| `hide_others.js` | `aria-hidden` on siblings of the modal content; restore | `aria-hidden` package |
| `scroll_lock.js` | body `overflow:hidden` + scrollbar-width padding compensation, ref-counted | `react-remove-scroll` |
| `positioner.js` | floating-ui `computePosition/autoUpdate` with Radix's middleware order: offset(sideOffset+arrow), flip/shift (collisionPadding), size (sets `--radix-popper-available-width/height`, `--radix-popper-anchor-width/height`, `--radix-popper-transform-origin`), arrow, hide; writes `data-side`, `data-align` | `react-popper` |
| `roving_focus.js` | `rovingFocus(container, { orientation, loop, dir, currentTabStopId })` arrow/Home/End, `tabindex` swapping | `react-roving-focus` |
| `typeahead.js` | buffer with 1000 ms reset, repeated-letter cycling, `matchItem(items, search, current)` | internal in menu/select |
| `hover_intent.js` | open/close delays with skip-delay provider state | tooltip/hover-card/navigation-menu |
| `submenu_grace.js` | pointer-grace polygon for sub menus | `react-menu` |
| `collection.js` | ordered item registry from DOM (`[data-collection-item]`) honoring disabled | `react-collection` |
| `ids.js` | stable id helpers; reads server ids first | `react-id` |
| `direction.js` | reads `dir` from nearest ancestor/`html` | `react-direction` |
| `form_bubble_input.js` | hidden native input kept in sync (checkbox/switch/radio/select) so forms submit | internal BubbleInput |
| `pointer_capture.js` | slider/resizable drag | native |

## Rules for primitives

- No global mutable state except explicit stacks (`dismissable` layers, `scroll_lock` counter, `hide_others` registry) that are reset by the returned `release()`.
- Radix constants (z-index is NOT set by Radix; `shadcn` uses `z-50`) are copied verbatim.
- Floating content uses the same wrapper contract as Radix: `div[data-radix-popper-content-wrapper]` with `position: fixed; left:0; top:0; transform: translate(x,y); min-width: max-content; z-index` copied from the content. The runner compares the content box in viewport coordinates, so the wrapper must resolve to identical coordinates.
- Each primitive has a "known divergences" list at the top of its file; empty is the goal.
