# VIEWS: View layer, form builder and admin framework requirements for the Md gem

This doc plans how an app puts the Md editor and viewer on a page, whatever it renders views with: ERB helpers, Phlex
components, ViewComponent, the Rails `FormBuilder`, simple_form and Formtastic inputs, and the admin frameworks (Avo,
ActiveAdmin, Administrate, Madmin, RailsAdmin) where markdown fields are most common. It matters because this is the
first code a developer writes against the gem. If `f.markdown_field :body` does not behave like `f.text_area :body`
(same name, id, errors, labels and required state) in the stack they already have, the gem fails its first priority,
developer experience, before anyone sees the editor. The benchmark settles the layer split (render core, viewer,
editor, agent layer) and the rule "ERB first, Phlex optional". This doc decides which view layer is the canonical
implementation and how every other entry point wraps it without a second code path.

## Scope

This doc decides:

- the one canonical implementation of each UI piece (editor, viewer) and the protocol every view layer uses to render it;
- the form builder method, the tag helper and how field state (value, errors, label, hint, required, disabled) reaches
  the editor;
- the simple_form and Formtastic inputs, and the admin framework adapters: which are first-party and which are recipes;
- whether Phlex is a runtime dependency.

Left to other areas: the final names of methods and helpers (`DX`; the names here are the benchmark's illustrative
ones), Action Text and Active Record adapters, Turbo lifecycle and the Action Text editor registry (`RAILS`), how the
JavaScript and CSS reach a page or an admin layout (`ASSETS`), how the invalid, disabled and focus states look and how
apps override markup (`THEME`), toolbar, modes and keyboard behaviour inside the editor (`EDIT`), what the viewer renders
(`RENDER`), the review component of the agent layer (`AGENT`), and what Papyro's Studio needs (`PAPYRO`).

Out of scope (WON'T, for every release this research plans):

- a replacement form builder (an `Md::FormBuilder` set as `default_form_builder`). The gem adds one method to the
  builder the app already uses;
- React, Vue or Svelte components of the editor;
- a first-party RailsAdmin field type (a documented recipe instead, see VIEWS-19);
- adapters for admin frameworks outside the five named here (Trestle, Motor Admin and others get the adapter contract of
  VIEWS-21 instead);
- inline server-side error messages rendered by the editor control itself (see the open decisions; the browser's
  constraint message of VIEWS-12 is not one).

## Questions

1. How does a single implementation serve ERB, Phlex and ViewComponent apps without three code paths?
2. How do form errors, labels, hints and required state flow into the editor?
3. What does an admin framework field adapter need, and which frameworks justify first-party adapters?
4. What does the same editor field look like in each view layer (one code sample per layer)?
5. Is Phlex a runtime dependency of the gem, and why?
6. Which choices can only a maintainer make, and what is the recommendation for each?

## Findings

### 1. One protocol already joins ERB, Phlex and ViewComponent: `render_in`

Rails' `render` accepts any object that responds to `render_in(view_context)` and calls it with the current view context
(`ActionView::Helpers::RenderingHelper`, read in actionview 8.1.4, `rendering_helper.rb` and `template/renderable.rb`).
ViewComponent and phlex-rails are both built on this protocol, and it works in every direction:

| Caller | How it renders an object with `render_in` | Read in |
|---|---|---|
| ERB view or partial | `<%= render obj %>` calls `obj.render_in(self)` | actionview 8.1.4 `RenderingHelper#render` |
| Phlex view (phlex-rails) | `render obj` forwards any non-Phlex object that responds to `render_in` to the Rails view context and outputs the result raw | phlex-rails 2.4.0 `lib/phlex/rails/sgml.rb` (`render`, line 91, the `render_in` branch) |
| ViewComponent | `render obj` delegates to the view context's `render` | view_component 4.4.0 `lib/view_component/base.rb` (`render`) |
| Phlex component inside ViewComponent | phlex-rails' own `render_in` detects a `ViewComponent::Base` context and uses its `helpers` | phlex-rails 2.4.0 `sgml.rb` (`render_in`) |

So the answer to question 1 is that the editor and the viewer are each **one plain Ruby object implementing
`render_in`** (`Md::Editor`, `Md::Viewer`). ERB helpers, the form builder method, the simple_form and Formtastic inputs
and the admin fields are thin adapters. They build that object's arguments and call `render` on it, and nothing else
emits editor markup. This keeps the public half of the benchmark's design rule 1 ("ERB first, Phlex optional", report
section "No Rails gem covers this") and narrows its internal half ("Internally the gem can render with Phlex"): the gem
renders with Action View's tag builder instead (see the open decisions), so it never chooses a view library for the app.

### 2. Phlex as a runtime dependency costs most apps something and buys them nothing

- Phlex core has no `render_in`: `Phlex::SGML#call` returns a string (phlex 2.4.1 `lib/phlex/sgml.rb`). Rendering a
  Phlex component from ERB with helpers needs phlex-rails. The alternative is a hand-written `render_in` that calls `call`
  and marks the string safe, but then the component cannot use Rails helpers itself.
- Most Rails apps are not Phlex apps. RubyGems totals on 2026-11-03: phlex-rails 3.4M downloads, view_component 65.9M,
  simple_form 100.5M, formtastic 65.3M. A Phlex dependency would put a second view library into every ERB and
  ViewComponent app for the sake of one field.
- A Phlex dependency is a version constraint on the apps that do use Phlex. chadcn, the sibling design-system gem,
  depends on `phlex ~> 2.3` and states that Phlex 3 is not supported (chadcn README, "Requirements"). An Md gem pinned the
  same way blocks a Phlex app's upgrade, and one pinned differently cannot be installed next to chadcn.
- Phlex apps lose nothing without it. phlex-rails renders `render_in` objects (finding 1). It also wraps the builder
  that `form_with` yields in `Phlex::Rails::Builder`, which outputs any `ActiveSupport::SafeBuffer` a builder method
  returns, so a form builder method works unchanged in Phlex (phlex-rails 2.4.0 `lib/phlex/rails/builder.rb`).

The answer to question 5 is therefore **no**. Phlex is not a runtime dependency, and the gem does not load it on its own
either. The editor object renders its markup with Action View's tag builder, which every Rails app already has. Phlex
apps get the same objects, plus an optional kit (VIEWS-04) that only defines methods when the app has already loaded
Phlex.

### 3. Prior art in Rails editor gems: how they reach forms

- **Marksmith** (Avo, 0.6.0) offers `marksmith_tag :body` and `form.marksmith :body`. Its engine includes a module into
  `ActionView::Helpers::FormBuilder` and works around ViewComponent: when the builder's `@template` is a component
  without the helper, it calls `@template.helpers.marksmith_tag` instead (marksmith `lib/marksmith/engine.rb`). The
  textarea is rendered with `text_area_tag`, not with the builder (marksmith
  `app/views/marksmith/shared/_editor_pane.html.erb`). As a result Rails' `field_error_proc` never wraps it: an invalid
  body gets no `field_with_errors` wrapper and looks valid. A label still works only because `text_area_tag` derives the
  same default id (`post_body`) from the name and Marksmith's textarea stays visible; an editor that hides its textarea, as
  Md's does, loses that and has to wire the label itself (finding 4). The viewer is
  `<%== marksmithed @post.body %>`, and the README warns that the app must sanitize this raw output.
- **Lexxy** (37signals, 1.0.3) takes over Action Text's helpers on Rails 8.0 and 8.1. `form.rich_text_area` renders Lexxy
  unless `config.lexxy.override_action_text_defaults = false`, and `lexxy_rich_textarea_tag` and
  `form.lexxy_rich_text_area` stay available for gradual adoption. On Rails versions with an editor registry it plugs
  into `config.action_text.editor` instead (lexxy.dev docs). The lesson is that the opt-out flag and the prefixed
  explicit method make a takeover safe. An Md gem needs no takeover at all, because markdown fields are plain
  `text_area` fields today.
- **chadcn** (our design system) already solved field state for a component library. `Chadcn::Engine::FormBinding`
  builds names and ids with the builder's own `field_name` and `field_id` (so `fields_for` indexes and `namespace:` are
  exact), reads errors from `model.errors`, and reads labels from `helpers.label.*` translations before
  `human_attribute_name` (chadcn `lib/chadcn/engine/form_binding.rb`). The same split fits the Md editor: adapters build a
  binding object, and the component reads only the binding.

The benchmark already fixes the editor's form contract. CodeMirror 6 mounts over the real `<textarea name="post[body]">`,
which stays the form value and is synced on a debounce (report, sections "Source-of-truth libraries beat doc-model
editors for an agent-edited corpus" and "What the gem provides"; research note `editor_libraries.md`, Q3 on Turbo pitfalls
and its inference on keeping a real textarea). A debounce alone leaves the textarea behind the editor for a moment, and
the browser checks the textarea's constraints (VIEWS-12) before it fires `submit`. So the editor also flushes the pending
sync when focus leaves it, before any submit it starts itself, and on the form's `submit` event (VIEWS-07).

### 4. Errors, labels, hints and required state

Rails gives every builder field the same state handling. The editor has to keep it even though the focusable surface is
CodeMirror's `contenteditable`, not the textarea:

- **Errors.** `config.action_view.field_error_proc` wraps any builder-rendered field of an attribute with errors, by
  default in `div.field_with_errors` (actionview 8.1.4 `base.rb`, line 162). It only runs for fields rendered through the
  builder's tag classes, which is why Marksmith's `text_area_tag` skips it. The editor must render its textarea with
  `builder.text_area` whenever a builder exists (VIEWS-07). Because the textarea is hidden once JavaScript runs, it must
  also mark the visible editor itself (`aria-invalid` on the editable element, plus a data attribute the theme styles).
- **Labels.** `f.label :body` points `for` at the textarea id. A hidden textarea cannot be focused, so clicking the label
  must move focus into the editor, and the editable element needs the label as its accessible name. The browser exposes
  a control's labels (`HTMLTextAreaElement.labels`), and CodeMirror sets arbitrary attributes on its editable element
  through the `EditorView.contentAttributes` facet. The editor can therefore forward `aria-labelledby`,
  `aria-describedby`, `aria-invalid` and `aria-required` at mount time without new options.
- **Hints.** Rails has no hint concept, so apps pass `aria: { describedby: "body_hint" }`. simple_form and Formtastic
  render hints and errors in their wrappers, but give them no id the editor can rely on: simple_form sets none by default
  and takes `hint_html:` and `error_html:` options for one (simple_form README, "Usage"); Formtastic's `hint_html` renders
  a `p` without an id, and its sentence-style error uses `id: "#{method}_error"`, which is not unique on a page with two
  forms (formtastic `lib/formtastic/inputs/base/hints.rb` and `errors.rb`). So the gem's inputs set an id derived from the
  field id (`post_body_hint`, `post_body_error`) through those hooks (simple_form's options, an override of `hint_html`
  and `error_html` in the Formtastic input), only on elements that render. Either way, the ids must land on the editable
  element.
- **Required.** A `required` attribute on a textarea that is not rendered blocks submission without a usable message.
  The HTML standard says that when an invalid control "is not being rendered", user agents may report a script error
  instead of showing the validation bubble (WHATWG HTML, "Interactively validate the constraints"). Dropping `required`
  and validating in the editor would need a gem-owned message in every locale, so the gem keeps `required` on the
  textarea, listens for its cancelable `invalid` event (fired before the user agent reports the problem), cancels the
  default report, shows the textarea's own `validationMessage` (the browser's localized text) in the browser's UI
  language, as with a plain `text_area`, next to the editor and moves focus into it (VIEWS-12). Otherwise a required
  markdown field silently refuses to submit.
- **simple_form** decides required (presence validators, `required:`), hint and error itself and renders them with its
  wrapper components. A custom input only renders the control (simple_form README, "Custom inputs" and "Wrappers").
  **Formtastic** works the same way through `Formtastic::Inputs::Base` (formtastic README, "Custom inputs").

The answer to question 2: each adapter builds one field-state object (`Md::Field`: name, id, value, errors, required,
disabled, readonly, describedby, plus the optional `form_builder` and `method` it came from) from the state its framework
already computed, and the editor reads nothing else. When `form_builder` is present the editor renders the textarea with
`form_builder.text_area(method, ...)`, so `field_error_proc`, `fields_for` indexes and `namespace:` stay Rails'; without
one (`markdown_field_tag`, a hand-built field) it uses `text_area_tag`. Each adapter passes the form builder its framework
yields to the field, where it has one, so no adapter renders the textarea itself.

### 5. Admin frameworks: what a field adapter needs

Versions and download totals come from the RubyGems API on 2026-11-03.

| Framework | Latest / downloads | View tech | Extension point (files) | Markdown today | Verdict |
|---|---|---|---|---|---|
| Avo | 4.3.10 / 3.7M | ViewComponent | `Avo::Fields::BaseField` subclass + Edit, Show, Index components (`bin/rails generate avo:field`); a gem can register a field and its assets through `Avo.plugin_manager` and `Avo.asset_manager` | `field :body, as: :markdown` is Marksmith since Avo 3.17; Marksmith registers it from its own engine when `defined?(Avo)` | First-party (SHOULD) |
| ActiveAdmin | 3.5.2 / 52.4M; 4.0.0.beta23 | Arbre + Formtastic; v4: Tailwind, importmap, no jQuery | a Formtastic custom input (`app/inputs/*_input.rb`) used as `f.input :body, as: :markdown` | none built in | Covered by the Formtastic input (SHOULD) |
| Administrate | 1.0.0 / 10.0M | ERB partials | `Administrate::Field::Base` subclass + `_form`, `_show`, `_index` partials (`rails generate administrate:field`), listed in `ATTRIBUTE_TYPES` | none built in | First-party, cheap (COULD) |
| Madmin | 3.4.1 / 0.57M | ERB partials | field class + `_form`, `_show`, `_index` partials (`rails g madmin:field`), `attribute :body, field: MdField` | Action Text only | First-party, cheap (COULD) |
| RailsAdmin | 3.3.1 / 13.4M | ERB partials | a class registered with `RailsAdmin::Config::Fields::Types.register` and a `partial` option; built-in `simple_mde` and `code_mirror` types load their JS from cdnjs | SimpleMDE 1.11.2 from a CDN (SimpleMDE's last release was 2016, per the benchmark) | Recipe in the docs (COULD) |

Downloads alone do not pick the first-party set: RailsAdmin has more than Avo and Administrate. The criterion is what a
first-party adapter saves an app compared with a documented recipe. Avo needs one: its `:markdown` field is already a
competing editor (Marksmith), a field needs Edit, Show and Index components plus asset registration, and Avo is the only
framework whose API lets a gem ship all of that. ActiveAdmin needs nothing beyond the Formtastic input, which also serves
plain Formtastic apps. Administrate and Madmin fields are a class and three partials each, cheap to ship but just as cheap
for an app to copy, hence COULD. RailsAdmin field types already take a `partial` option, so a few-line recipe whose partial
calls `f.markdown_field` gives the app the whole adapter, and a first-party type would add a class to maintain with no gain
over the recipe.

Every adapter needs the same four things:

1. a way to declare the field on a resource;
2. an edit view that renders `Md::Editor` with an `Md::Field` built from the framework's form builder;
3. show and index views that render `Md::Viewer` (the index shows a plain-text excerpt);
4. the gem's JavaScript and CSS in the admin layout. Only Avo's asset manager offers an API for this; the others need the
   app's layout or importmap (an `ASSETS` concern).

Because the editor mounts over a real textarea, an admin page without the JavaScript still shows a working textarea.

Marksmith's Avo field shows one hazard and one good pattern. The hazard: it registers itself under the generic
`:markdown` type, so a second gem that registers `:markdown` silently replaces one of them. Marksmith also registers
`:marksmith`, the gem-prefixed pattern VIEWS-17 recommends. The good pattern: it loads only when `defined?(Avo)` holds at
boot, so there is no hard dependency and no load error in apps without Avo.

### 6. The same field in each view layer

The names follow the benchmark's illustrative API (`Md`, `markdown_field`, `markdown_view`); `DX` picks the final ones.

ERB with `form_with`:

```erb
<%= form_with model: @post do |f| %>
  <%= f.label :body %>
  <%= f.markdown_field :body, required: true, aria: { describedby: "post_body_hint" } %>
  <p id="post_body_hint">Markdown is supported.</p>
<% end %>

<%= markdown_view @post.body %>
```

Phlex (phlex-rails), with the same form builder method and no adapter:

```ruby
class Posts::Form < ApplicationComponent
  include Phlex::Rails::Helpers::FormWith

  def initialize(post:) = @post = post

  def view_template
    form_with model: @post do |f|
      f.label :body
      f.markdown_field :body, required: true, aria: { describedby: "post_body_hint" }
      p(id: "post_body_hint") { "Markdown is supported." }
    end
  end
end

# viewer: render Md::Viewer.new(@post.body)
```

ViewComponent, with the same method. The builder's template is the component, and the gem calls `render` on it, which
ViewComponent forwards to the view context:

```erb
<%# app/components/post_form_component.html.erb %>
<%= form_with model: @post do |f| %>
  <%= f.label :body %>
  <%= f.markdown_field :body, required: true, aria: { describedby: "post_body_hint" } %>
  <p id="post_body_hint">Markdown is supported.</p>
<% end %>
```

Without a model, and with the canonical object rendered directly (any layer):

```erb
<%= markdown_field_tag "comment[body]", @draft, id: "comment_body" %>
<%= render Md::Editor.new(field: Md::Field.new(name: "comment[body]", id: "comment_body", value: @draft)) %>
```

simple_form, then Formtastic (ActiveAdmin):

```erb
<%= simple_form_for @post do |f| %>
  <%= f.input :body, as: :markdown, hint: "Markdown is supported." %>
<% end %>
```

```ruby
# app/admin/posts.rb (ActiveAdmin)
form do |f|
  f.inputs { f.input :body, as: :markdown }
  f.actions
end
```

Admin frameworks:

```ruby
field :body, as: :md_markdown              # Avo resource (type name: see the open decisions)
body: Md::Administrate::Field,             # Administrate dashboard ATTRIBUTE_TYPES
attribute :body, field: Md::Madmin::Field  # Madmin resource
```

## Requirements

The requirements are grouped by entry point. Every requirement keeps the one-implementation rule of VIEWS-01.

### Canonical implementation

- **VIEWS-01** (MUST) The editor and the viewer each have exactly one implementation, a plain Ruby object that responds
  to `render_in(view_context)` (`Md::Editor`, `Md::Viewer`); helpers, the form builder method, form-library inputs and
  admin adapters only build its arguments and render it. Acceptance: no file outside the two objects emits editor or
  viewer markup, and each adapter's test asserts that it renders the canonical object.
- **VIEWS-02** (MUST) The same object renders identical HTML from an ERB view, a phlex-rails view and a ViewComponent.
  Acceptance: the gem's CI renders one fixture field through all three in the dummy app and compares the HTML.
- **VIEWS-03** (MUST) The gem has no runtime dependency on Phlex, phlex-rails or ViewComponent and renders its markup with
  Action View's tag builder. Acceptance: the gemspec lists none of them, and the Gemfile.lock of a separate ERB-only CI
  job (its own Gemfile, next to the dummy app VIEWS-02 uses) contains neither phlex nor view_component.
- **VIEWS-04** (COULD) An optional Phlex kit exposes the components as Phlex methods (`MarkdownEditor(field:)`,
  `MarkdownView(text)`) and is defined only when the app has loaded Phlex, checked in an engine initializer after
  `Bundler.require` (or loaded by an explicit `require "md/phlex"`). Acceptance: requiring the gem in an app without
  Phlex defines no Phlex constants, and a phlex-rails view can call the kit methods after including the kit.

### Form builder and tag helper

- **VIEWS-05** (MUST) `f.markdown_field :attribute, **options` is added to `ActionView::Helpers::FormBuilder` with the
  signature and HTML options of `f.text_area`, returns an `ActiveSupport::SafeBuffer`, and works when the builder's
  template is an Action View context or a ViewComponent, and when phlex-rails wraps the builder in
  `Phlex::Rails::Builder`. Acceptance: one test per context renders the field and finds the textarea with the Rails name
  and id.
- **VIEWS-06** (MUST) `markdown_field_tag(name, value = nil, **options)` renders the same editor for forms without a model.
  Acceptance: its parsed DOM equals the builder method's for the same name, id and value, minus the error state.
- **VIEWS-07** (MUST) When the `Md::Field` carries a form builder, `Md::Editor` renders the textarea with that builder's
  own `text_area`, so name, id, `fields_for` index, `namespace:`, value and `field_error_proc` follow Rails exactly; without
  one it uses `text_area_tag`. Either way the textarea stays the form value and the no-JavaScript fallback, and the editor
  flushes its pending debounced sync into it when focus leaves the editor, before any submit the editor starts and on the
  form's `submit` event, so constraint validation and the submitted params never read a stale value. Acceptance: with
  JavaScript disabled a dummy form submits the field, nested `fields_for` produces the ids that `text_area` produces, an
  invalid record's textarea sits inside the app's `field_error_proc` wrapper, and a system test that types into an empty
  required editor and clicks submit before the debounce elapses sends the request with the typed text in the params.

### Field state

- **VIEWS-08** (MUST) Field state travels in one value object (`Md::Field`: name, id, value, errors, required, disabled,
  readonly, describedby, and the optional `form_builder` and `method`) that every adapter builds and the editor reads
  exclusively; adapters pass the form builder their framework yields when there is one, and `markdown_field_tag` passes
  none. Acceptance: for the same invalid model and the same resolved options (`required: true`, one hint id), the form
  builder, simple_form, Formtastic and each admin adapter build `Md::Field` objects whose attributes other than
  `form_builder` are equal in unit tests.
- **VIEWS-09** (MUST) When the attribute has errors, the editable element gets `aria-invalid="true"` and the editor root a
  documented invalid-state hook that the theme styles, independent of `field_error_proc`. Acceptance: a system test with
  an invalid record finds `aria-invalid` on the editable element and the hook on the root.
- **VIEWS-10** (MUST) The editor takes its accessible name from the textarea's labels (or from `aria-label` or
  `aria-labelledby` given to the field), and clicking an `f.label` for the attribute focuses the editor. Acceptance: a
  system test clicks the label and finds focus inside the editor, and an axe check reports an accessible name on the
  editable element.
- **VIEWS-11** (MUST) `aria: { describedby: }` on the field is forwarded to the editable element, and the simple_form and
  Formtastic inputs give the hint and error elements their wrappers render an id derived from the field id (simple_form's
  `hint_html:` and `error_html:`, an override of Formtastic's `hint_html` and `error_html`) and forward those ids as well,
  listing only elements that render. Acceptance: a system test finds the hint id in the editable element's
  `aria-describedby`, and an element with that id on the page, for the builder, simple_form and Formtastic fields, and
  with an invalid record the error element's id for the simple_form and Formtastic fields.
- **VIEWS-12** (MUST) `required: true` stays on the textarea and sets `aria-required` on the editable element; submitting
  an empty required editor is blocked, the textarea's own `validationMessage` (the browser's localized text, so no gem
  string is needed) is shown next to the editor until the textarea becomes valid, and referenced from its
  `aria-describedby`, and focus moves to the editor, never a silent refusal from a hidden control. Acceptance: a system test submits an empty required field, finds that no
  request was sent, finds the textarea's `validationMessage` text on the page and finds focus in the editor.
- **VIEWS-13** (SHOULD) `disabled:` and `readonly:` put the editor in a read-only state and disable its toolbar, and a
  disabled field is not submitted, as with `text_area`. Acceptance: a system test cannot type into a readonly field, and a
  disabled field is absent from the submitted params.

### Form libraries

- **VIEWS-14** (SHOULD) A simple_form input `as: :markdown`, defined only when simple_form is loaded, renders the
  canonical editor and passes simple_form's required, hint and error state into `Md::Field`, leaving labels, hints and
  messages to the app's wrappers; `text` columns keep simple_form's default input. Acceptance: `f.input :body, as: :markdown`
  in a dummy app renders simple_form's label, hint and error around the editor, and VIEWS-09 to VIEWS-12 hold.
- **VIEWS-15** (SHOULD) A Formtastic input `as: :markdown`, defined only when Formtastic is loaded, does the same for
  Formtastic and thereby for ActiveAdmin 3 and 4. Acceptance: an ActiveAdmin resource with `f.input :body, as: :markdown`
  renders the editor in the dummy app on ActiveAdmin 3.5 and on the current 4.0 prerelease.

### Admin frameworks

- **VIEWS-16** (SHOULD) Admin adapters ship inside the gem, each loaded only when its framework is defined, checked in an
  engine initializer after `Bundler.require`, and an admin page without the gem's JavaScript still shows a working
  textarea. Acceptance: booting the dummy app without each framework raises no load error, and with JavaScript blocked
  an admin edit form submits the field.
- **VIEWS-17** (SHOULD) An Avo field registers under a gem-prefixed type (never the generic `:markdown`) and wraps the
  canonical editor and viewer in its Edit and Show components; how its JavaScript and CSS reach Avo's layout (Avo's asset
  manager is the only admin hook for it, finding 5) is left to `ASSETS`. Acceptance: an Avo resource with the field edits
  and shows a record in the dummy app with Marksmith also installed, and both fields keep working.
- **VIEWS-18** (COULD) Administrate and Madmin fields (a field class and `_form`, `_show`, `_index` partials each) delegate
  to the canonical objects. Acceptance: a dashboard and a resource using the fields edit, show and list a record in the
  dummy app.
- **VIEWS-19** (COULD) The docs carry a RailsAdmin recipe: a field type registered with
  `RailsAdmin::Config::Fields::Types.register` whose partial renders `f.markdown_field`. Acceptance: following the recipe
  in a fresh RailsAdmin app shows the editor on the edit page.
- **VIEWS-20** (MUST) Every show and index view the gem ships, in helpers and adapters alike, renders through `Md::Viewer`
  (sanitized render core output), an index shows a plain-text excerpt produced by `Md::Viewer` (its excerpt output is a
  `RENDER` concern), and no gem view outputs markdown HTML with `<%==` or `raw`. Acceptance: the XSS corpus rendered
  through each adapter's show view stays inert, and a grep of the gem's views finds no raw output.

### Developer experience

- **VIEWS-21** (SHOULD) The adapter contract (build an `Md::Field`, render `Md::Editor` or `Md::Viewer`) is documented
  with a test helper, so a third party can write an adapter for another admin framework in about twenty lines.
  Acceptance: the docs page shows a complete adapter, and the helper fails a sample adapter that emits its own markup.
- **VIEWS-22** (MUST) The samples in the README (whose structure `DX` owns) show the same field in ERB, Phlex and
  ViewComponent, and each adapter has one copy-paste sample. Acceptance: the README samples run unchanged in the dummy
  app's ERB, phlex-rails and ViewComponent pages.
- **VIEWS-23** (SHOULD) Misuse fails loudly with the fix in the message: an attribute the object does not respond to, a
  form-library input used without its library, or an admin adapter referenced without its framework. Acceptance: each
  case raises an error whose message names the attribute or the missing gem.

## Developer experience notes

- **VIEWS-01 to VIEWS-03** add no API for a newcomer to learn, because they constrain the inside of the gem. Their benefit
  is that every guide, Stack Overflow answer and bug report is about one implementation, and that installing the gem adds
  no view library to the app.
- **VIEWS-04** is the only Phlex-specific surface. It costs a Phlex user one `include` and nobody else anything. It can
  wait until Phlex users ask for it, because `render Md::Editor.new(...)` and `f.markdown_field` already work in Phlex.
- **VIEWS-05 to VIEWS-07** cost one method that mirrors `f.text_area`, the method a newcomer is replacing. The rule
  "same options as `text_area`" leaves nothing new to read, and switching a field to markdown is a one-word diff.
- **VIEWS-08** introduces `Md::Field`, but only adapter authors and apps that render the object by hand see it. Form users
  never construct one.
- **VIEWS-09 to VIEWS-13** add no options. They make existing Rails options (`required`, `disabled`, `aria`) and model
  errors behave the way a developer already expects. Without them the gem would teach newcomers that markdown fields are
  second-class, which is the Marksmith gap in finding 3.
- **VIEWS-14 and VIEWS-15** cost one `as:` value in libraries the developer already uses. Not remapping `text` columns by
  default avoids surprises in existing forms.
- **VIEWS-16 to VIEWS-19** cost admin users one field type each. Loading adapters only when their framework is present
  keeps the gem silent for everyone else, and the RailsAdmin recipe costs the maintainers only the docs.
- **VIEWS-20** removes a footgun instead of adding API: the viewer never requires `<%==`, so there is nothing to forget.
- **VIEWS-21 to VIEWS-23** are documentation and error messages. They shorten the time to a first working field.

## Open decisions

- Is Phlex a runtime dependency? Recommendation: no (VIEWS-03). The `render_in` protocol already reaches Phlex apps, and a
  Phlex dependency would add a view library to the ERB and ViewComponent majority and pin Phlex versions for Phlex apps
  that also use chadcn. Revisit only if the gem's own components become hard to maintain with the tag builder, and then
  depend on `phlex` alone (not phlex-rails) with the same range as chadcn.
- Does the gem render markup from Ruby (the tag builder) or from ERB partials that apps can override by copying them?
  Recommendation: Ruby, with customization through options and theme tokens (`THEME`). Overridable partials are how
  Marksmith and the admin frameworks work, but every copied partial drifts from the gem on upgrade, a developer
  experience cost the gem pays forever.
- Which admin adapters are first-party in the first releases? Recommendation: the Formtastic input (it covers ActiveAdmin)
  and the Avo field as SHOULD after 0.1, Administrate and Madmin as COULD once someone asks, and RailsAdmin as a docs
  recipe only, by the criterion in finding 5 (what an adapter saves an app over a recipe, not download counts). Release
  0.1 ships the form builder method, the tag helper and the viewer helper, which any admin edit page can already use in a
  custom partial.
- Should the editor control render its own error messages (an `errors: :inline` option)? Recommendation: no, match
  `f.text_area`. Rails apps, simple_form and Formtastic already render messages, and a second place would duplicate them.
  The control only exposes the invalid state (VIEWS-09), forwards the message ids (VIEWS-11) and, for a blocked submit,
  surfaces the browser's own constraint message (VIEWS-12), which is client-side and never duplicates a server error.
- Which type name does the Avo field register? Recommendation: a gem-prefixed type derived from the final gem name, never
  `:markdown`, which Marksmith registers today. The README documents how to move a field from Marksmith's `as: :markdown`.
- Should simple_form map `text` columns to the markdown input automatically? Recommendation: no, keep it opt-in with
  `as: :markdown`, so installing the gem never changes an existing form.

## Sources

- `docs/features/markdown-editor/reports/Markdown editor benchmark.md` (layer table, design rules, "Source-of-truth libraries beat doc-model editors for an agent-edited corpus")
- `docs/features/markdown-editor/research_notes/Markdown editor benchmark/editor_libraries.md` (textarea as the form value, Turbo pitfalls, Marksmith)
- https://api.rubyonrails.org/classes/ActionView/Helpers/RenderingHelper.html (accessed 2026-11-03; read in actionview 8.1.4 source)
- https://www.phlex.fun/rails/helpers (accessed 2026-11-03)
- https://github.com/phlex-ruby/phlex-rails (accessed 2026-11-03; read in phlex-rails 2.4.0 source, `sgml.rb` and `builder.rb`)
- https://viewcomponent.org/guide/helpers.html (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith (accessed 2026-11-03; `lib/marksmith/engine.rb`, `_editor_pane.html.erb`, `lib/marksmith/fields/markdown_field.rb`)
- https://avohq.io/blog/ruby-on-rails-markdown-editor-marksmith (accessed 2026-11-03)
- https://lexxy.dev/docs/ (accessed 2026-11-03)
- https://github.com/doncan-orozco/chadcn (accessed 2026-11-03; `lib/chadcn/engine/form_binding.rb`, README requirements)
- https://html.spec.whatwg.org/multipage/form-control-infrastructure.html (accessed 2026-11-03; interactively validate the constraints)
- https://codemirror.net/docs/ref/ (accessed 2026-11-03; `EditorView.contentAttributes`)
- https://developer.mozilla.org/en-US/docs/Web/API/HTMLTextAreaElement/labels (accessed 2026-11-03)
- https://github.com/heartcombo/simple_form (accessed 2026-11-04; custom inputs, wrappers, `hint_html` and `error_html` options)
- https://github.com/formtastic/formtastic (accessed 2026-11-03; custom inputs)
- https://github.com/formtastic/formtastic/blob/master/lib/formtastic/inputs/base/hints.rb (accessed 2026-11-04)
- https://github.com/formtastic/formtastic/blob/master/lib/formtastic/inputs/base/errors.rb (accessed 2026-11-04)
- https://docs.avohq.io/3.0/fields/markdown.html (accessed 2026-11-03)
- https://docs.avohq.io/3.0/custom-fields.html (accessed 2026-11-03)
- https://activeadmin.info/docs/v3/5-forms.html (accessed 2026-11-03)
- https://github.com/activeadmin/activeadmin/blob/master/UPGRADING.md (accessed 2026-11-03; v4 Tailwind, importmap, jQuery removed)
- https://github.com/thoughtbot/administrate/blob/main/docs/adding_custom_field_types.md (accessed 2026-11-03)
- https://github.com/excid3/madmin (accessed 2026-11-03)
- https://github.com/railsadminteam/rails_admin/blob/master/lib/rails_admin/config/fields/types.rb (accessed 2026-11-03; `register`, built-in `simple_mde` and `code_mirror` types)
- https://rubygems.org/api/v1/gems/view_component.json (accessed 2026-11-03; versions and download totals of every gem in this doc come from this endpoint with the gem's name in place of view_component)
- https://rubygems.org/api/v1/gems/marksmith.json (accessed 2026-11-03; Marksmith 0.6.0)
