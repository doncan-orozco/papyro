# PapyroFormBuilder Reference

`PapyroFormBuilder` is Papyro's custom `ActionView::Helpers::FormBuilder`. It injects cohesive shadcn/Tailwind class strings on all form field types, provides a `field` wrapper helper for label + input + hint + errors, and exposes an `unstyled:` opt-out for fields that intentionally bypass the design system defaults.

## File Location

`app/forms/papyro_form_builder.rb`

## Default Class Constants

| Constant | Applied to |
|----------|-----------|
| `INPUT_CLASS` | `text_field`, `email_field`, `password_field`, `search_field`, `url_field` |
| `TEXTAREA_CLASS` | `text_area`, `markdown_area` |
| `SELECT_CLASS` | `select` |
| `SUBMIT_CLASS` | `submit` |
| `HINT_CLASS` | hint paragraph inside `field` wrapper |

`INPUT_CLASS` and `TEXTAREA_CLASS` include `border border-input`, `shadow-sm`, `focus-visible:ring-1 focus-visible:ring-ring`, and error state classes (`aria-invalid:*`).

## The `field` Wrapper Helper

Use `form.field` for labeled form fields. It composes: optional label, optional before-input slot, the input, optional hint, and inline error messages.

```ruby
form.field :email,
  as: :email_field,
  label: t("..."),
  hint: t("..."),
  options: { placeholder: "..." }
```

Supported `as:` values: `:text_field`, `:email_field`, `:password_field`, `:search_field`, `:url_field`, `:text_area`, `:markdown_area`, `:select`.

### Hiding Label or Hint

Pass `nil` to suppress:

```ruby
form.field :title,
  as: :text_field,
  label: nil,   # no label rendered
  hint: nil,    # no hint rendered
  options: { ... }
```

## Class Merging Behavior

The builder uses `merge_class(options, base_class)` which **concatenates** the base class string with any `class:` you pass:

```ruby
options[:class] = [base_class, options[:class]].compact.join(" ")
```

> ⚠️ **Implication**: Tailwind utilities added in the view (e.g. `border-none`) are concatenated with builder-injected classes (e.g. `border border-input`). Because both classes appear in the output HTML, and Tailwind's CSS specificity is based on file position (not DOM order), the result is **unpredictable** — the builder's border may win even when you write `border-none` in the view.

## The `unstyled: true` Opt-Out

When you need a field with no design-system styling (e.g. a canvas-style title input with no border/shadow/ring), pass `unstyled: true` in the `options:` hash:

```ruby
form.field :title,
  as: :text_field,
  label: nil,
  hint: nil,
  options: {
    unstyled: true,                  # ← skips INPUT_CLASS injection entirely
    class: "w-full text-4xl font-extrabold border-none bg-transparent px-0 shadow-none outline-none focus-visible:outline-none focus-visible:ring-0",
    placeholder: "Title..."
  }
```

### How It Works (implementation)

```ruby
def merge_input_options(method, options)
  merge_field_options(method, options, INPUT_CLASS)
end

def merge_field_options(method, options, base_class)
  options = options.dup
  unstyled = options.delete(:unstyled)        # consume the key
  merged = unstyled ? options : merge_class(options, base_class)
  return merged unless has_errors?(method)

  merged[:aria] = (merged[:aria] || {}).merge(invalid: true)
  merged
end
```

Key points:
- `options.delete(:unstyled)` — **destructively** removes the key so it isn't passed to the HTML element as an attribute
- When `unstyled` is truthy, `merge_class` is skipped entirely — only your `class:` string is used
- Error state (`aria-invalid`) is still applied even for unstyled fields

### When to Use `unstyled: true`

✅ **Use** for intentionally bare, canvas-style fields:
- Blank canvas editor title input
- Blank canvas editor body textarea/markdown area
- Any field where the design explicitly calls for no visible border, shadow, or ring

❌ **Do NOT use** for normal form fields:
- All regular auth forms (login, signup, password reset)
- Settings forms
- Any field that should look like a standard input

## Error Display

Field errors are rendered below the input automatically when `object.errors` is present on the method:

```ruby
form.field_errors(:title)  # renders <p class="text-xs text-destructive">...</p> for each error
```

The `field` helper calls `field_errors` automatically; you only need to call it manually for custom layouts.

## Enforcement Rule: Never Hide Form Errors

- Every editable form control must have a visible validation error path.
- Preferred approach: use `form.field`, which renders inline errors automatically.
- If you must use raw helpers (for example `form.file_field`), render matching errors directly under that control.

Example for raw file field:

```ruby
form.file_field :cover_image, accept: "image/png,image/jpeg,image/webp"
form.field_errors(:cover_image)
```

If a form is rendered in a sheet/dialog/modal, keep the overlay open on validation failure so those errors remain visible.

## Markdown Area Integration

For House markdown editor fields, use `as: :markdown_area`. The form builder routes this through a custom helper:

```ruby
# In field_input, for :markdown_area
merged = merge_field_options(method, options, TEXTAREA_CLASS)
public_send(:markdown_area, method, **merged)
```

The `markdown_area` helper (defined in `lib/rails_ext/action_text_tag_helper.rb`) renders the `<house-md>` custom web component.

## Example: Standard Form Field

```ruby
# Normal field — builder injects INPUT_CLASS with borders/shadows/rings
form.field :email,
  as: :email_field,
  label: t("users.form.email"),
  hint: t("users.form.email_hint"),
  options: {
    placeholder: "you@example.com",
    autocomplete: "email"
  }
```

## Example: Canvas-Style Field (Blank Canvas Editor)

```ruby
# Opt-out field — no builder classes, fully custom appearance
form.field :title,
  as: :text_field,
  label: nil,
  hint: nil,
  options: {
    unstyled: true,
    required: true,
    class: "mb-6 w-full rounded-none border-none bg-transparent px-0 text-4xl font-extrabold leading-tight tracking-tight shadow-none outline-none placeholder:text-muted-foreground/30 focus-visible:outline-none focus-visible:ring-0 md:text-5xl",
    placeholder: t("studio.articles.form.title_placeholder"),
    data: { testid: "article-title-field" }
  }
```

## See Also

- [blank-canvas-editor.md](../../frontend-design/references/blank-canvas-editor.md) — Full blank canvas editor pattern
- [form-snapshot.md](form-snapshot.md) — Snapshot of existing form structure for refactoring reference
- [../design-system/SKILL.md](../../design-system/SKILL.md) — Base UI component design tokens
