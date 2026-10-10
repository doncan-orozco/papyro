# Radix DOM contract (what the port must reproduce)

Radix wires attributes at runtime. Rails renders on the server, then Stimulus takes over. The **post-connect DOM** must equal the Radix DOM. Where the server can render the attribute, render it (no flash); where it depends on runtime (ids, positions) Stimulus sets it in `connect()`.

Do not trust this file over the real thing: when in doubt, open the Radix source (`@radix-ui/react-<name>`, linked from `manifest.meta.links.radix.api`) and the live catalog DOM. Everything below is the minimum to check.

| Primitive | Elements and attributes the DOM must carry |
|---|---|
| Dialog / AlertDialog / Sheet | Trigger: `aria-haspopup="dialog" aria-expanded aria-controls data-state`. Overlay: `data-state`, `aria-hidden` on siblings while open (hideOthers), body `pointer-events:none` + scroll lock. Content: `role="dialog"` (`alertdialog`), `aria-labelledby` -> Title id, `aria-describedby` -> Description id, `tabindex="-1"`, `data-state`. AlertDialog: Cancel receives focus on open, no overlay-click dismiss. |
| Popover / HoverCard | Trigger `aria-haspopup="dialog" aria-expanded aria-controls data-state`; Content `role="dialog"`, `data-state data-side data-align`, wrapper `data-radix-popper-content-wrapper` with `position:fixed; transform` (compare box, not wrapper attrs). |
| Tooltip | Content `role="tooltip"`, trigger `aria-describedby` while open, `data-state="delayed-open|instant-open|closed"`, `data-side`. Provider delay + skip-delay. |
| DropdownMenu / ContextMenu / Menubar | Trigger `aria-haspopup="menu" aria-expanded aria-controls data-state`. Content `role="menu" aria-orientation="vertical" data-state data-side data-align`. Items `role="menuitem|menuitemcheckbox|menuitemradio" data-highlighted data-disabled data-orientation tabindex="-1"`; checked items `aria-checked data-state`. Sub: `data-state` trigger + `aria-haspopup`. Typeahead, arrow/Home/End, Esc, ArrowRight/Left for sub-menus. |
| Select | Trigger `role="combobox" aria-expanded aria-controls aria-autocomplete="none" data-state data-placeholder`, hidden native `<select aria-hidden>` for forms. Content `role="listbox"`, items `role="option" aria-selected data-state data-highlighted`. Item-aligned position by default. |
| Tabs | List `role="tablist" aria-orientation`, trigger `role="tab" aria-selected aria-controls data-state data-orientation id`, content `role="tabpanel" aria-labelledby data-state tabindex="0"`; roving tabindex, activation mode. |
| Accordion / Collapsible | Trigger `aria-expanded aria-controls data-state data-orientation`, content `role="region" aria-labelledby data-state`, `hidden` when closed, height variables `--radix-accordion-content-height` / `--radix-collapsible-content-height` for animations. |
| Checkbox / Switch / Toggle / RadioGroup | `role="checkbox|switch|radio"`, `aria-checked` (`"mixed"` indeterminate), `aria-pressed` (toggle), `data-state`, `data-disabled`, hidden bubble input for forms (Checkbox/Switch/Radio render `<input type=checkbox aria-hidden tabindex=-1 style=position:absolute...>` when inside a form). Keys (verified in `@radix-ui/react-checkbox` / `react-switch` source): Checkbox cancels Enter (`if (event.key === "Enter") event.preventDefault()`), so only Space toggles it; Switch and Toggle have NO key handler, they are native buttons, so Space AND Enter both toggle. Do not add key handlers to a Switch: the native button click is the contract. Radio: roving tabindex + arrows select. |
| Slider | Root `data-orientation`, thumb `role="slider" aria-valuemin aria-valuemax aria-valuenow aria-orientation tabindex=0`, keys Arrow/Home/End/PageUp/PageDown (step x10), pointer capture on track. |
| Progress | `role="progressbar" aria-valuemin aria-valuemax aria-valuenow aria-valuetext data-state="loading|complete|indeterminate" data-value data-max`. |
| Avatar | Image only mounted once loaded; Fallback with optional delay; same DOM for both states. |
| ScrollArea | Root/viewport/scrollbar/thumb structure with `data-state="visible|hidden"`; CSS vars for thumb size. |
| NavigationMenu | `nav aria-label`, list, trigger `aria-expanded aria-controls data-state`, viewport/indicator, hover intent delays. |
| Toggle group | Root `role="group"` (`radiogroup` for type single in newer versions: verify), items `aria-pressed|aria-checked`, roving focus. |
| Label / Separator / AspectRatio | `<label>` click focuses control; Separator `role="separator"` or `none` when `decorative` (default true in shadcn), `data-orientation`, `aria-orientation` only when not decorative. |

## Server vs client

Prefer rendering `role`, `aria-*` static parts, `data-state`, `hidden` and ids on the server so no-JS and first paint match. Stimulus owns: open/close transitions, focus management, roving tabindex, positioning, typeahead, outside-click, scroll lock, `aria-hidden` on siblings, id generation fallbacks.

## Ids

Server-generated ids (`SecureRandom`-free: derive from an `id:` kwarg or a per-render counter) so `aria-labelledby/controls` resolve before JS. The runner normalizes ids by first-seen order, so any scheme works as long as the **relations** are the same.
