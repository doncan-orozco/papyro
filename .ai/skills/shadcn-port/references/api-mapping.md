# API mapping: React shadcn -> Phlex

One table, applied mechanically by the builder AND by the harness (`Components::Parity::TreeRenderer` converts the JSON scenario tree with exactly these rules, so a wrong rule fails the gate).

| React | Phlex | Notes |
|---|---|---|
| `<Button variant="outline" size="sm">` | `render Components::V2::Button.new(variant: "outline", size: "sm") { "Click" }` | Strings and symbols both accepted (R4). |
| `className="x"` | `class: "x"` | Merged last via `cn` (tailwind_merge): caller wins. |
| `children` | block | Text, other components, `plain`/`raw` inside the block. |
| camelCase prop `defaultValue` | `default_value:` | `ariaLabel` is passed as `aria: { label: }` or `"aria-label":`; both accepted. |
| `data-foo="x"`, `aria-*`, `role`, `id`, `type`, `disabled`... | same keys through `**attrs` | `data: {}` / `aria: {}` hashes deep-merged with component defaults. |
| `asChild` | `as_child:` | `false` (default) \| a tag symbol (`as_child: :a`, the part renders that tag with its own classes, `data-slot` and attrs) \| a V2 component **instance** (`as_child: Components::V2::Button.new(variant: "outline")`, Radix `Slot` semantics via `Components::V2::Base#render_as_child`). |
| `disabled` boolean | `disabled: true` | Renders attribute exactly like React (`disabled=""`). |
| `open` / `onOpenChange` | `open:` (initial/controlled) + event `v2--dialog:open-change` with `detail: { open }` | Controlled mode = the server renders the next state; client mode = Stimulus value. |
| `defaultOpen` | `default_open:` | |
| `value` / `defaultValue` / `onValueChange` | `value:` / `default_value:` / event `v2--<name>:value-change` (`detail: { value }`) | |
| `checked` / `onCheckedChange` | `checked:` / event `v2--<name>:checked-change` | `checked: "indeterminate"` supported where Radix supports it. |
| `onClick` etc. | plain DOM events; use `data: { action: "click->foo#bar" }` | No JS callbacks in Ruby. |
| `ref` | `data: { <controller>_target: ... }` or no equivalent | Not part of the API. List in the spec if React callers rely on it. |
| Compound exports `Dialog`, `DialogTrigger`, `DialogContent`... | `Components::V2::Dialog`, `Dialog::Trigger`, `Dialog::Content`... | Rule: strip the root name prefix. Exceptions (`buttonVariants`, `useSidebar`) map to class methods: `Components::V2::Button.variants(variant:, size:)` returns the class string. |
| `cva` variants | class-level table + `Component.variants(**opts)` | Keys identical to React (`"icon-sm"`). |
| `cn(...)` | `cn(...)` from `Components::Base` | Same semantic (clsx + tailwind-merge). |
| lucide icons (`<XIcon />`) | `render Components::V2::Icon.new(name: "x")` rendering the exact lucide SVG (`class`, `size-4`, `aria-hidden`) | Icon set must be the same lucide version as the catalog. |
| `useIsMobile()` and other hooks | Stimulus value/helper in the owning controller | Document in the spec. |

## Example: Button

```tsx
<Button variant="outline" size="sm" className="shrink-0" onClick={...}>Save</Button>
```
```ruby
render Components::V2::Button.new(variant: "outline", size: "sm", class: "shrink-0", data: { action: "click->foo#save" }) { "Save" }
```
Must emit `<button data-slot="button" class="...tokens identical to React...">Save</button>`.

## Example: Dialog (compound)

```tsx
<Dialog>
  <DialogTrigger asChild><Button variant="outline">Open</Button></DialogTrigger>
  <DialogContent><DialogHeader><DialogTitle>Hi</DialogTitle></DialogHeader></DialogContent>
</Dialog>
```
```ruby
render Components::V2::Dialog.new do
  render Components::V2::Dialog::Trigger.new(as_child: Components::V2::Button.new(variant: "outline")) { "Open" }
  render Components::V2::Dialog::Content.new do
    render Components::V2::Dialog::Header.new { render Components::V2::Dialog::Title.new { "Hi" } }
  end
end
```

## `as_child` = Radix Slot merge (implemented once in `Components::V2::Base`)

`render_as_child(child, **slot_attrs, &block)` merges the parent part's computed attributes (`slot_attrs`: aria, `data-state`, `data-action`, `id`...) into the child's attributes with exactly Radix `mergeProps` semantics: **child props win** (so the child's `data-slot="button"` is kept), `class` is joined and conflict-resolved (`cn(slot, child)`), `data-action` descriptors are concatenated (both run), `style` is merged, everything else child-over-slot. Then it renders the child with the block. `as_child: :tag` is the degenerate case (no child component): same merge against a bare element. Parts never implement this themselves.

The scenario `tree` uses `"asChild": true` with one child node; the Phlex harness converts that child into the instance passed to `as_child:`, React renders real `asChild`, and the DOM is compared.

## Result of each rule must be observable

For each row above the scenario set contains at least one scenario that exercises it. If a rule cannot be mapped 1:1, it is a **deviation**: write `deviations/<name>.json` (`{ "reason": "...", "allow_tokens": [], "allow_missing_tokens": [], "api": ["..."] }`) and list it in DEVIATIONS.md. Undeclared differences fail the gates.
