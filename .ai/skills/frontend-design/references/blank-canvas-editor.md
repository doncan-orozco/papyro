# Blank Canvas Editor Pattern

A distraction-free, writing-first editor interface inspired by Medium, Notion, and Ghost. The goal is to eliminate all chrome that competes with the content itself — no cards, no visible field borders, no labels, just a clean writing surface.

## Philosophy

The **Tax Form Problem**: A default Rails CRUD form (card wrapper, label above each field, visible border/shadow/ring) is a psychological barrier to writing. The user is thinking about _filling in a form_ rather than _writing an article_.

The **Blank Canvas** solution removes all UI scaffolding: no wrapper card, no labels, no borders, no rings — just a giant title and an open body area with a subtle toolbar.

## Architecture

The edit experience is split across two files:

- **`edit.rb`** — Page shell: sticky action bar (back link + autosave + actions), trashed banner
- **`editor_form_component.rb`** — Editor canvas: title field + toolbar + body field

This separation keeps the action bar outside the scrollable content area.

## Page Shell (`edit.rb`)

```ruby
# Outermost wrapper — no card, no max-width constraint here
div(class: "bg-background pb-12") do
  # Trashed branch: simple non-sticky header
  if @article.trashed?
    div(class: "bg-background/95 px-4 py-3") do
      div(class: "mx-auto flex max-w-5xl items-center") do
        render_back_link
      end
    end
    # ...editor canvas below

  # Draft branch: sticky action bar with Sheet overlay for settings
  elsif @article.status_draft?
    render Components::Ui::Sheet.new do |sheet|
      # ⚠️ CRITICAL: NO border-b here — the main navbar already has one
      div(class: "sticky top-0 z-20 bg-background/95 px-4 py-3 backdrop-blur") do
        div(class: "mx-auto flex max-w-5xl items-center justify-between gap-3") do
          render_back_link
          div(class: "flex items-center gap-4") do
            # Autosave status text (replaced by Turbo Stream)
            div(
              id: "autosave-status",
              class: "text-sm text-muted-foreground",
              data: { testid: "autosave-status" }
            ) { t("studio.articles.autosave.saved") }
            # Save Draft button
            render Components::Ui::Button.new(variant: :outline, type: :submit, form: "article-editor-form") do
              t("studio.articles.form.save_draft")
            end
            # Publish button (triggers Sheet)
            sheet.trigger { render Components::Ui::Button.new { t("...") } }
          end
        end
      end
      render EditorFormComponent.new(@article)
      # Sheet content for publish settings...
    end

  # Published branch: same sticky bar, no publish button
  else
    div(class: "sticky top-0 z-20 bg-background/95 px-4 py-3 backdrop-blur") do
      # ...
    end
    render EditorFormComponent.new(@article)
  end
end
```

### Double-Header Anti-Pattern

❌ **WRONG** — causes two visible border lines at the top:
```ruby
div(class: "sticky top-0 z-20 bg-background/95 px-4 py-3 backdrop-blur border-b")
```

✅ **CORRECT** — the main navbar's border is sufficient:
```ruby
div(class: "sticky top-0 z-20 bg-background/95 px-4 py-3 backdrop-blur")
```

> The main Papyro navbar already has a `border-b`. Adding `border-b` to the sticky action bar immediately below it creates a "double line" artifact.

## Editor Canvas (`editor_form_component.rb`)

```ruby
# Centered reading-width container
div(class: "mx-auto mt-12 w-full max-w-3xl px-4 sm:px-6") do

  # Title: massive, bold, no border, no label
  form.field :title,
    as: :text_field,
    label: nil,
    hint: nil,
    options: {
      unstyled: true,   # ← bypasses PapyroFormBuilder's border/shadow/ring injection
      required: true,
      class: "mb-6 w-full rounded-none border-none bg-transparent px-0 text-4xl font-extrabold leading-tight tracking-tight shadow-none outline-none placeholder:text-muted-foreground/30 focus-visible:outline-none focus-visible:ring-0 md:text-5xl",
      placeholder: t("studio.articles.form.title_placeholder"),
      data: { testid: "article-title-field" }
    }

  # Toolbar: subtle sticky strip with ghost buttons
  div(class: "sticky top-0 z-10 mb-6 flex items-center gap-1 border-b border-border/40 bg-background py-3 px-0") do
    tag(:"house-md-toolbar", id: "house_toolbar")
  end

  # Body: open area, no border, generous height
  form.field :body,
    as: :markdown_area,
    label: nil,
    hint: nil,
    options: {
      unstyled: true,   # ← bypasses PapyroFormBuilder's border/shadow/ring injection
      toolbar: "house_toolbar",
      required: true,
      autofocus: true,
      class: "w-full min-h-[65vh] rounded-none border-none bg-transparent px-0 py-2 pb-32 text-lg leading-relaxed shadow-none outline-none focus-visible:outline-none focus-visible:ring-0",
      data: { controller: "house-autofocus", testid: "article-body-field" }
    }
end
```

### Key Typography Choices

| Element | Classes | Purpose |
|---------|---------|---------|
| Title input | `text-4xl md:text-5xl font-extrabold leading-tight tracking-tight` | Headline-scale, impactful |
| Title placeholder | `placeholder:text-muted-foreground/30` | Barely-there ghost text |
| Body textarea | `text-lg leading-relaxed` | Comfortable long-form reading size |
| Body min-height | `min-h-[65vh]` | Fills viewport — no empty space below |
| Body bottom padding | `pb-32` | Breathing room at the end of content |

## House Markdown Editor Integration

The body field uses a **custom web component** — not EasyMDE, not Trix:

- **`<house-md>`** — The editor element (wraps the textarea)
- **`<house-md-toolbar>`** — The floating toolbar
- **Source**: `vendor/javascript/house.min.js`
- **Styling**: `app/assets/stylesheets/house.css` (not Tailwind)
- **Integration helper**: `lib/rails_ext/action_text_tag_helper.rb` → `markdown_area()`

### Toolbar Styling (house.css)

Toolbar buttons are styled via `:where()` with CSS custom properties — **not Tailwind**:

```css
:where(house-md-toolbar) {
  color: var(--color-muted-foreground);
  display: inline-flex;
  gap: 0.25rem;

  :is(button, label) {
    background-color: transparent;
    border: none;
    border-radius: calc(var(--house-border-radius) * 0.8);
    inline-size: 2rem;
    min-block-size: 2rem;
    transition: background-color 180ms ease, color 180ms ease;

    &:where(:focus-visible),
    @media (hover: hover) &:hover {
      background-color: var(--color-muted);
      color: var(--color-foreground);
    }
  }
}
```

This produces muted ghost-button toolbar icons that don't compete with the writing surface.

### Connecting Toolbar to Editor

The toolbar `id` must match the `toolbar` option on the body field:

```ruby
# Toolbar
tag(:"house-md-toolbar", id: "house_toolbar")

# Body field
options: { toolbar: "house_toolbar", ... }
```

## The `unstyled: true` Opt-Out

**Why it's needed**: `PapyroFormBuilder` injects `INPUT_CLASS`/`TEXTAREA_CLASS` into every field, which include `border border-input`, `shadow-sm`, and `focus-visible:ring-1 focus-visible:ring-ring`. These classes are concatenated with any classes you pass — Tailwind's output order is unpredictable, so adding `border-none` in the view **does not reliably win**.

**Solution**: Pass `unstyled: true` in the field `options:` hash to skip base class injection entirely. See [../frontend/references/papyro-form-builder.md](../frontend/references/papyro-form-builder.md) for full documentation.

```ruby
options: {
  unstyled: true,
  class: "... your complete class list ...",
  ...
}
```

> **Scope**: Only use `unstyled: true` for intentionally bare canvas-style fields. All other forms keep builder defaults intact.

## Trashed Article Branch

When `@article.trashed?`, the title is shown read-only and the body is rendered as plain text inside a muted card:

```ruby
div(class: "mx-auto mt-8 w-full max-w-3xl space-y-4") do
  form.field :title,
    as: :text_field,
    label: nil,
    hint: nil,
    options: {
      unstyled: true,
      disabled: true,
      class: "w-full rounded-none border-none bg-transparent px-0 text-4xl font-extrabold ...",
    }

  div(class: "prose prose-neutral max-w-none rounded-md border bg-muted/20 p-4") do
    p { @article.plain_text_body }
  end
end
```

The trashed branch renders a non-sticky header bar (no autosave, no save button).

## Summary Checklist

When implementing a blank canvas editor:

- [ ] No card/wrapper component around the form
- [ ] No breadcrumbs (back link goes in the action bar)
- [ ] Sticky action bar has NO `border-b` (avoids double-header)
- [ ] Action bar uses `backdrop-blur` + `bg-background/95` for frosted glass
- [ ] Canvas is `max-w-3xl` centered
- [ ] Title uses `text-4xl md:text-5xl font-extrabold`
- [ ] Title and body fields both have `label: nil, hint: nil`
- [ ] Both fields use `unstyled: true` to bypass builder class injection
- [ ] Both fields use `px-0` (left-aligns with toolbar buttons)
- [ ] Toolbar strip uses subtle `border-b border-border/40`
- [ ] Body has `min-h-[65vh]` and `pb-32`
- [ ] Autosave status lives in the action bar (top-right), not inside the canvas
