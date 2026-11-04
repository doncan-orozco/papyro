# DX: developer experience and public API requirements for the Md gem

This doc covers what a Rails developer types, reads and maintains to adopt the Md gem: the install command, the
generators, the model, form and view API, the configuration object, the extension points, the error messages, the upgrade
policy and the docs. Developer experience is the gem's first priority (see `README.md` in this folder), and it is where
the closest prior art falls short. Marksmith leaves three steps to the developer after install (the stylesheet tag, the
Stimulus controller registration and sanitizing its `<%==` output), and Lexxy is smooth but stores HTML. The benchmark report already settles what the gem does (four layers: render core, viewer,
editor, optional agent layer). This doc settles how that surface feels from `bundle add` to the third upgrade. `Md` /
`md:` is the placeholder name until the naming decision lands.

## Scope

This doc decides:

- the shortest install path and what the install generator does;
- the names and shape of the public API: `Md.render`, the `markdown_field` form-builder method, the `markdown_view`
  helper, the optional `has_markdown` macro, `Md.configure`;
- which defaults ship out of the box;
- how apps extend the gem (toolbar buttons, render passes, upload handling) without learning a plugin framework;
- error messages and diagnostics, the version and deprecation policy, and the docs, quick start and demo.

Left to other areas, which this doc refers to by area name only:

- how JavaScript and CSS reach the app under importmap, jsbundling, Propshaft or Sprockets (ASSETS);
- Phlex, ViewComponent, simple_form and admin-framework integrations (VIEWS);
- Active Record, Action Text, Active Storage and Turbo details (RAILS);
- theme tokens and visual overrides (THEME);
- the toolbar's contents, shortcuts and modes as a writing experience (EDIT);
- the dialect and sanitizer allowlist (RENDER);
- suggestion tables and MCP (AGENT).

Out of scope (WON'T):

- a JavaScript plugin registry or a gem-specific plugin API: extensions use Ruby callables, data and DOM events;
- a copy-the-code installer in the style of the shadcn CLI: the code stays in the gem, so upgrades are a `bundle update`;
- React or Vue components;
- an HTML storage mode: markdown text is the only stored format;
- a hosted service or any LLM call made by the gem itself;
- a content migration command for Marksmith, Trix or Lexxy in the DX surface (whether to migrate content is PRIOR's and
  PAPYRO's call).

## Questions

1. What is the shortest path from `bundle add` to a working editor and viewer, measured in commands and lines?
2. Which defaults must be right out of the box, so that most apps never configure anything?
3. How does the gem expose extension points (custom syntax, toolbar buttons, upload handlers) without a plugin framework
   newcomers must learn?
4. What is the public API surface: install command, model macro, form-builder method, view helpers, configuration
   object, extension points?
5. How do the best-loved Rails gems (Devise, Pagy, Pundit, Action Text, Lexxy, Marksmith, ViewComponent, Phlex,
   simple_form, Avo, chadcn) install, configure, report errors, upgrade and document themselves, and what should Md copy
   or avoid?
6. What does a README quick start look like when it is under 30 lines of code and covers install, model, form and view?
7. Which choices can only a maintainer make?

## Findings

The inputs that settle the product are `../reports/Markdown editor benchmark.md` (section "No Rails gem covers this,
so build one": the four layers, the illustrative `Md.render`, `f.markdown_field` and `markdown_view` API, and design
rules 1-5) and `../research_notes/Markdown editor benchmark/editor_libraries.md` (Q3: Marksmith's install generator and
helpers, Lexxy's Action Text integration, importmap pin costs). They are cited here, not researched again. Everything
below was read from each gem's README, guide or source on 2026-11-03.

### Install flows of eleven gems

"Commands" counts shell commands from a working Rails app to first use (a Gemfile line and its `bundle install` count as
one). "Lines" counts app code a developer types to show an editor or the feature and the saved content; Gemfile lines and
the strong-parameters entry are excluded, because every row needs the same one. Counts come from each gem's own
getting-started page or source.

| Gem | Commands to first use | What the install generator writes | Lines of app code to first use | Manual steps left after install | Extension mechanism |
|---|---|---|---|---|---|
| Devise | 4: `bundle add devise`, `rails g devise:install`, `rails g devise User`, `rails db:migrate` | initializer with every option, model, migration, route | 1: `before_action :authenticate_user!` | mailer `default_url_options` per environment (printed by the generator), restart | modules listed in the `devise` macro; `devise:views` and `devise:controllers` generators copy code to customize |
| Pagy | 1: Gemfile line and `bundle install`; no generator | none | 3: `include Pagy::Method`, `pagy(:offset, scope)`, `@pagy.series_nav` | none | options passed to `pagy` per call; the paginator chosen by its first argument (`:offset`) |
| Pundit | 1: `bundle add pundit` (`pundit:install` is optional) | `ApplicationPolicy` | about 13: `include Pundit::Authorization`, a policy class, `authorize @post` | none | policy classes found by naming convention; `verify_authorized` as a development safety net |
| Action Text | 2: `bin/rails action_text:install`, `bin/rails db:migrate` | migrations, JavaScript imports, CSS, partials | 3: `has_rich_text :content`, `form.rich_textarea :content`, `<%= @article.content %>` | none | swap the editor (Lexxy) |
| Lexxy | 1 on top of Action Text (Gemfile line and `bundle install`); importmap apps add 2 pins and 1 import | none | 0 beyond Action Text's on Rails 8.0/8.1: `form.rich_text_area` renders Lexxy once the gem is installed | the pins and the import | layered options: default, then preset, then HTML attribute (`Lexxy.configure`); prompts |
| Marksmith | 2: `bundle add marksmith commonmarker`, `bin/importmap pin @avo-hq/marksmith`; `marksmith:install` only writes the config | initializer | 2: `form.marksmith :body`, `<%== marksmithed post.body %>` | stylesheet tag, Stimulus controller registration, sanitizing the raw output | override `Marksmith::Renderer` by defining the same class in the app; choose the parser |
| ViewComponent | 2: Gemfile line and `bundle install`, then `bin/rails g view_component:component Example title`; no install generator | per component: class, template, test | 1: `render(ExampleComponent.new(title:))` | none | subclassing; previews served in development by default |
| phlex-rails 2.4 | 3: `bundle add phlex-rails`, `bin/rails g phlex:install`, `bin/rails g phlex:component Thing` | `config/initializers/phlex.rb`, `app/components/base.rb`, `app/views/base.rb` | 1: `render Components::Thing.new` | none | subclassing the generated bases; `phlex:component` and `phlex:view` generators |
| simple_form | 2: `bundle install`, `rails g simple_form:install` (`--bootstrap`, `--foundation`) | initializer with wrappers for the chosen CSS framework | 1 per field: `f.input :username` | include the CSS framework | a class in `app/inputs/*_input.rb`, used with `as: :currency`; no registration |
| Avo | 1 with the app template, or 2: Gemfile line and `bundle install`, then `bin/rails g avo:install` | initializer, `/avo` mount in routes | a resource per model, made by the resource generator | authentication, authorization, licence | resources and fields, generators |
| chadcn | 3: `bundle add chadcn`, `bin/rails g chadcn:install`, `bin/rails tailwindcss:build` | managed CSS block, theme files copied once | 1: `render Chadcn::Button.new` | `tailwindcss-rails` must be installed first | eject one component; `chadcn:doctor` explains a broken setup |

The research notes record `config.action_text.editor = :lexxy` for Lexxy; its current docs say installing the gem is
enough on Rails 8.0/8.1 and that the setting is needed only on Rails versions that include Lexxy.

What the table shows:

1. **The best installs are one generator that finishes the job and says what is left.** Devise's installer prints the
   per-environment mailer settings it cannot write itself. Avo's app template does the install in one command and leaves authentication, authorization and licensing as documented next steps.
   chadcn's generator writes a managed block that is the same on every machine. Marksmith is the counter-example for
   this gem: its generator writes only a config file, so the developer adds the pin, registers the controllers and adds
   the stylesheet tag by hand, and Stimulus and Turbo must already be set up.
2. **Zero configuration is a feature people name.** Pagy says it works "with almost zero configuration". Lexxy needs no
   extra line on Rails 8.0/8.1, because installing the gem is enough for `form.rich_text_area` to render it. Action Text
   renders saved content with a plain `<%= @article.content %>`, with no `raw`.
3. **Rails-native verbs beat new concepts.** Every loved gem uses a verb Rails developers already know: a model macro
   (`devise`, `has_rich_text`), a form-builder method (`form.rich_textarea`, `form.marksmith`, `f.input`), a view helper
   or `render`. None asks the developer to learn a registry.
4. **Extension by convention or plain objects, not plugins.** simple_form finds `app/inputs/currency_input.rb` by name.
   Pundit finds `PostPolicy` from `Post`. Marksmith lets an app redefine `Marksmith::Renderer`. Lexxy layers options
   from a default to a named preset to an HTML attribute. In each case the developer writes an ordinary class or an
   ordinary value.
5. **Good errors say what to do.** Pundit's denial message names the policy, the query and the record ("not allowed to
   PostPolicy#update? this Post"). Pundit's `verify_authorized` catches a forgotten call in development and is
   documented as a development aid, not a security control. chadcn ships `chadcn:doctor`, which says why styles are
   missing instead of making the developer grep for it.
6. **Upgrades are trusted when nothing is copied into the app and breaking changes are announced first.** The Rails
   maintenance policy pairs breaking changes with deprecation notices in the previous release. chadcn upgrades are a
   `bundle update` because the components stay in the gem. Pagy's upgrade guide to version 43 has search-and-replace
   tables, which is good, but it discontinued helpers with no transition period. Pagy's own quick start then
   recommends pinning the minor version (`~> 43.8`) "to avoid breaking changes". The gem should not train its users to
   pin minors.
7. **A live demo shortens evaluation.** Lexxy has a sandbox at lexxy.dev, Pagy a dev-tools sandbox, ViewComponent serves
   previews in development by default, and chadcn has a component catalog. Lexxy's docs page still pins
   `gem 'lexxy', '~> 0.9.21'` while the gem is at 1.0.3, which shows that copy-paste docs need a test to stay correct.
8. **Unsafe output is a DX bug.** Marksmith renders with `<%== marksmithed post.body %>` and warns that the content must
   be sanitized. Every app that copies the snippet inherits the risk. Papyro's own renderer had exactly that defect (the
   benchmark report, section "Fix first").

### Shortest path, measured

From a Rails 8 app with Stimulus, Turbo and a `posts.body` text column:

| Path | Commands | Lines of app code | Manual edits beyond the lines |
|---|---|---|---|
| Action Text with Trix | 2 | 3 (model, form, render) | none |
| Action Text with Lexxy | 3 (adds `bundle install`) | 3 (model, form, render), plus 2 pins and 1 import under importmap | the pins and the import |
| Marksmith | 2 (+1 optional generator) | 2 (form, render) | stylesheet tag, controller registration, sanitizing |
| **Md target** | **2**: `bundle add md`, `bin/rails generate md:install` | **2**: `form.markdown_field :body`, `markdown_view @post.body` | **none** |

The target needs no model change, because the core works on any text column (design rule 3 in the benchmark report).
The permitted parameter is ordinary Rails form work, the same for every row, so no row counts it.

### Defaults that must be right

A developer who never opens the initializer gets: safe rendering (raw HTML off, the allowlist sanitizer, no `raw` in
views); the pinned dialect; `hardbreaks: false`; a preview drawn by the same renderer as the viewer; Source mode; the
standard toolbar; uploads on when Active Storage direct uploads are available and off (with no upload button) when they
are not; light and dark styles that follow the app's theme variables; English and Spanish UI strings that the app can
override with I18n; Turbo-safe setup and teardown; a real `<textarea>` as the form value, so the form works before and
without JavaScript; and rendered HTML cached in `Rails.cache` under a key made of the text digest, the locale and the
renderer version.

### Extension points without a framework

Three mechanisms (data, DOM events and Ruby callables) cover the known needs for custom syntax, toolbar buttons and
upload handlers, and each is something a Rails developer already knows:

- **Data in the initializer** for the toolbar: a list of symbols, and custom buttons that insert a markdown template
  around the selection. No JavaScript.
- **DOM events** for behaviour: the editor dispatches `md:change`, `md:upload`, `md:command` and `md:preview`, and the
  app's own Stimulus controllers listen to them.
- **Plain Ruby callables** for rendering and uploads: a render pass is any object that responds to `call(node)` on the
  root node of the commonmarker AST, appended to a list in the configuration, and its output still goes through the
  sanitizer; `config.uploads.url_for` maps an uploaded blob to the URL written into the markdown, and
  `uploads: { url: }` swaps the endpoint per field.

### Draft README quick start

This is the quick start the README opens with: 13 lines of code from install to viewer (10 without the comment lines).

```bash
bundle add md
bin/rails generate md:install
```

```ruby
# app/models/post.rb: optional, adds post.body_document (TOC, headings, reading time)
class Post < ApplicationRecord
  has_markdown :body
end
```

```erb
<%# app/views/posts/_form.html.erb %>
<%= form_with model: @post do |form| %>
  <%= form.markdown_field :body %>
  <%= form.submit %>
<% end %>

<%# app/views/posts/show.html.erb %>
<%= markdown_view @post.body %>
```

`body` is any `text` column, and the controller permits it as usual (`params.expect(post: [:title, :body])`). The
generator wires the JavaScript and the stylesheet for importmap or jsbundling and writes `config/initializers/md.rb` with
every option commented out; the engine mounts the preview endpoint itself, with no route edit (DX-15). Phlex apps render `Md::Editor` and `Md::Viewer` with the
same options.

## Requirements

Grouped by the developer's journey: install, everyday API, defaults, extension, errors, upgrades, docs.

### Install

- **DX-01** (MUST) Two commands take an existing Rails app with a text column to a working editor and viewer:
  `bundle add md` and `bin/rails generate md:install`, with no manual edit afterwards. Acceptance: a CI job runs the two
  commands in a fresh `rails new` app (importmap and Propshaft), adds `form.markdown_field :body` and
  `markdown_view @post.body` to a scaffold, and a system test saves a post through the editor and sees formatted output
  on the show page.
- **DX-02** (MUST) The install generator detects the JavaScript pipeline (importmap, or jsbundling with a
  `package.json`) and the CSS setup, wires each one inside marked, managed blocks, and is idempotent. The mechanisms per
  pipeline are ASSETS requirements. Acceptance: running the generator twice in the importmap and esbuild dummy apps
  leaves no diff after the second run.
- **DX-03** (MUST) The generator ends by printing every file it changed and the exact command for each remaining step,
  the way Devise prints its mailer settings. A working install never depends on reading the initializer. Acceptance: in
  an app without Active Storage, the generator output names the files it touched and the one command that enables
  uploads.
- **DX-04** (MUST) The generator checks its prerequisites (Stimulus, Turbo, a supported JavaScript pipeline) before
  writing anything, and stops with the install command for what is missing. Acceptance: in an app without stimulus-rails
  the generator exits non-zero, prints the fix, and leaves `git status` clean.
- **DX-05** (SHOULD) The generator writes `config/initializers/md.rb` with every option commented out, its default value
  and a one-line explanation. Acceptance: a test compares the initializer template with the options `Md::Configuration`
  defines and fails when one is missing.
- **DX-06** (SHOULD) Optional parts have their own generators and are never installed by `md:install`: the agent
  layer's tables (`md:suggestions`, AGENT) and ejecting a component (VIEWS, THEME). Acceptance: `md:install` creates no
  migration, and `bin/rails generate --help` lists the optional `md:` generators.

### Everyday API

- **DX-07** (MUST) The editor and the viewer work on any `string` or `text` attribute with no model change. Acceptance:
  the DX-01 CI app runs without `has_markdown` and passes the same system test.
- **DX-08** (MUST) A form-builder method `form.markdown_field :body` and a `markdown_field_tag` for forms without a
  model accept the standard field options (`placeholder`, `required`, `disabled`, `autofocus`, `class`, `data`) and
  render a real textarea with the field's name, so the form submits with JavaScript off. Acceptance: with JavaScript
  disabled a system test submits the form and the body is saved, and the textarea has `name="post[body]"`.
- **DX-09** (MUST) A view helper `markdown_view(text)` returns an `html_safe` buffer from the sanitized pipeline, so app
  code never writes `raw`, `html_safe` or the `<%==` tag to show markdown. Acceptance: the README and docs contain no
  `<%==` and no `raw` around gem output, and the RENDER XSS corpus rendered through the helper contains no script, event
  handler or `javascript:` URL.
- **DX-10** (MUST) `Md.render(text, locale: I18n.locale)` is the Ruby entry point (the locale is optional and defaults to
  `I18n.locale`, as in `markdown_view`) and returns an `Md::Document` (`html`, `toc`, `headings`, `word_count`,
  `reading_time`) with the same HTML the helper and the preview show. Acceptance: a test
  asserts `Md.render(text).html` equals the inner HTML of `markdown_view(text)` and of the preview response for the
  fixture corpus.
- **DX-11** (SHOULD) An optional model macro `has_markdown :body` adds `body_document` (a memoized `Md::Document`, cached
  by digest, locale and renderer version) and nothing else: no table, no column, no callback that writes. Acceptance: a
  test lists the public methods the macro adds and fails on any other, and the macro creates no migration.
- **DX-12** (MUST) One option vocabulary everywhere: the form-builder method, the tag helper, the Phlex components
  (VIEWS) and the initializer use the same option names (`modes:`, `toolbar:`, `uploads:`, `preview:`), and a per-call
  option overrides the initializer default. Each per-call option maps to one initializer key: `modes:` and `toolbar:` to
  `config.editor`, `uploads:` to `config.uploads`, `preview:` to `config.preview`. Acceptance: a test iterates the editor options of `Md::Configuration` and
  passes each one to the helper and the component, and the docs have one options table.
- **DX-13** (MUST) The quick start adds at most two public names to learn for the editor and viewer
  (`markdown_field`, `markdown_view`); every other public name is optional. Acceptance: the README quick start uses no
  gem constant or method beyond those two and the optional `has_markdown`.

### Defaults

- **DX-14** (MUST) The defaults listed in Findings ("Defaults that must be right") ship as the out-of-box behaviour,
  with an empty initializer. Acceptance: a default-behaviour system test in the dummy app with an empty initializer
  asserts each listed default except uploads, which DX-16 checks (sanitized output, Source mode, toolbar, dark styles,
  Spanish strings under `I18n.locale = :es`, textarea fallback, cache hit on the second render).
- **DX-15** (MUST) The preview endpoint is mounted automatically, renders only the text it receives (it never loads a
  record), is CSRF-protected and rate-limited, and can be turned off with one option. Acceptance: the editor preview
  works with no route edit; `config.preview.mount = false` removes the route in a routing test; request tests show that a
  POST without a CSRF token is rejected, that the rate limit answers 429, and that a `record_id` parameter is ignored.
- **DX-16** (SHOULD) Uploads default to Active Storage direct uploads when the app has Active Storage, and the editor
  shows no upload control when it does not. Acceptance: the default-behaviour test runs in an app with and an app
  without Active Storage and checks the toolbar.

### Extension points

- **DX-17** (SHOULD) The toolbar is declared as data (`toolbar: %i[bold italic link | heading quote code | image table]`),
  and a custom button that inserts a markdown template is defined in Ruby with no JavaScript, for example
  `config.editor.button :callout, label: "Note", icon: "info", insert: "> [!NOTE]\n> {selection}"`. Acceptance: a system
  test defines a button only in the initializer and sees its template inserted around the selection.
- **DX-18** (MUST) Editor behaviour is extended through documented DOM events (`md:change`, `md:upload`, `md:command`,
  `md:preview`) that the app's own Stimulus controllers handle, cancellable where it makes sense; the gem has no
  JavaScript plugin registry. Acceptance: the docs list each event with its `detail` payload, and a dummy-app controller
  cancels `md:upload` and inserts its own URL in a system test.
- **DX-19** (MUST) Upload handling can be replaced per field (`uploads: { url: }`, the Marksmith `upload_url`
  precedent) and app-wide with a callable that maps an uploaded blob to the URL written into the markdown
  (`config.uploads.url_for`). Acceptance: tests cover the default, a custom endpoint, a custom URL mapper and
  `uploads: false`.
- **DX-20** (MUST) Custom syntax is added with plain Ruby callables appended to the render pipeline
  (`config.render.passes << EmojiPass`, each responding to `call(node)`) and allowlist additions
  (`config.sanitizer.allow tags: [...], attributes: [...]`); pass output still goes through the sanitizer. Acceptance:
  the docs' ten-line example pass works in a test, and an attribute the pass adds without an allowlist entry is stripped.
- **DX-21** (SHOULD) An app can replace the whole renderer with `config.renderer = MyRenderer`, an object that responds
  to `render(text, locale:)` and returns an `Md::Document`, and the viewer, the preview and `Md.render` all use it.
  Acceptance: a test with a stub renderer sees its output in all three.

### Errors and diagnostics

- **DX-22** (MUST) An invalid configuration raises `Md::ConfigurationError` at boot, naming the option, the value it got,
  the values it accepts, a did-you-mean suggestion and the docs URL. Acceptance: a test sets `config.editor.mods` and
  asserts the message contains "did you mean", "modes" and the docs URL.
- **DX-23** (MUST) `bin/rails md:doctor` checks the setup (JavaScript pins or package, stylesheet, Stimulus
  registration, Active Storage, preview route, CSP nonce, Turbo) and prints each failure with its fix, following
  `chadcn:doctor`. Acceptance: in a dummy app with the stylesheet removed, the doctor prints that failure and its fix and
  exits non-zero.
- **DX-24** (SHOULD) In development the editor logs one console error naming the missing piece when the server markup
  and the JavaScript disagree (controller not registered, gem and npm package versions differ). Acceptance: a system test
  with a mismatched package version reads the documented console message.
- **DX-25** (SHOULD) Misuse fails early in development and test: `markdown_field` on an attribute that is not a string
  or text, or on a `has_rich_text` attribute, raises an `ArgumentError` that says what to use instead. Acceptance: a
  test for each case asserts the message.

### Upgrades

- **DX-26** (MUST) Versioning follows semver, and nothing public is removed before one release that warns about it
  through `Md.deprecator`, registered in `Rails.application.deprecators`; this holds in 0.x too. Acceptance: every
  CHANGELOG removal names the release that deprecated it, and a public-API snapshot test fails when a public method
  disappears without a deprecation entry.
- **DX-27** (MUST) An upgrade is `bundle update md` (plus the npm package for jsbundling apps): the gem copies nothing
  into the app except the initializer and files the app chose to eject. Acceptance: from the second release on, a CI job
  upgrades a dummy app from the previous minor release with no change beyond the lockfiles, and its system tests stay
  green.
- **DX-28** (MUST) Changes to rendered output are versioned: any change bumps `Md::RENDERER_VERSION` (part of the cache
  key), the dialect never changes in a patch release, and the CHANGELOG has an "Output changes" section. The dialect itself is RENDER's. Acceptance: a
  snapshot test over the fixture corpus fails when output changes and the renderer version does not.
- **DX-29** (SHOULD) Every release with a breaking change ships an upgrade guide with search-and-replace tables (the
  Pagy precedent), and each deprecation message links to its entry. Acceptance: a CI check finds an upgrade-guide entry
  for every deprecation message.
- **DX-30** (SHOULD) A compatibility page lists the supported Ruby, Rails, Phlex and JavaScript-pipeline versions, and
  the CI matrix proves each row (chadcn's `docs/compatibility.md` precedent). Acceptance: the CI matrix and the
  compatibility table list the same rows.

### Docs and demo

- **DX-31** (MUST) The README opens with a quick start of at most 30 lines of code covering install, model, form and
  view, and CI runs it. Acceptance: a CI job extracts the quick start code blocks into a fresh app and runs the DX-01
  system test against them.
- **DX-32** (SHOULD) A docs site has one entry per option, extension point and event, with a live sandbox of the editor
  and viewer (the Lexxy and Pagy precedent). Acceptance: a test fails when a `Md::Configuration` option has no docs
  anchor, and a link check runs in CI.
- **DX-33** (COULD) A development-only gallery route shows the editor and viewer with the host app's own theme, like
  ViewComponent previews. Acceptance: `/rails/md` renders in development and returns 404 in production.
- **DX-34** (COULD) The gem ships an `llms.txt` and an agent skill describing its public API for coding agents, as
  chadcn does. Acceptance: the packaged gem contains both files, and they list every public method in the API snapshot.

## Developer experience notes

What a newcomer has to learn, by group:

| Group | New public surface | Cost to a newcomer |
|---|---|---|
| Install (DX-01 to DX-06) | 1 generator, 1 initializer they may ignore, optional generators | 2 commands. The cost is on the gem: pipeline detection and managed blocks must be tested on every supported setup (ASSETS). |
| Everyday API (DX-07 to DX-13) | `markdown_field`, `markdown_view`; optional `has_markdown`, `Md.render`, `markdown_field_tag` | 2 names to start. `has_markdown` is the only macro and it is optional: the quick start shows it as a skippable step, and DX-01 and DX-07 pass without it. |
| Defaults (DX-14 to DX-16) | none | Zero. Each default removes a configuration line most apps would otherwise copy. Automatic upload detection can surprise; the generator output (DX-03) says which way it went. |
| Extension (DX-17 to DX-21) | toolbar data, `config.editor.button`, 4 DOM events, `config.render.passes`, `config.sanitizer.allow`, `config.uploads.url_for`, `config.renderer` | Paid only by apps that extend. Each mechanism is a Rails idiom (initializer data, Stimulus events, callables). Seven extension points is the ceiling (toolbar data, `config.editor.button`, the DOM events counted as one, `config.render.passes`, `config.sanitizer.allow`, `config.uploads.url_for`, `config.renderer`); a new one must replace one or justify its cost in this table. |
| Errors (DX-22 to DX-25) | `md:doctor` | Negative cost: these shorten debugging. Messages are API too, and DX-22 and DX-25 test them. |
| Upgrades (DX-26 to DX-30) | `Md.deprecator` warnings | Paid by the maintainers. Developers get `bundle update` without pinning minors. |
| Docs (DX-31 to DX-34) | gallery route, llms.txt | None for the app. CI-run docs keep the quick start from going stale the way Lexxy's version pin did. |

Requirements that add API surface and their owners elsewhere: the Phlex components (VIEWS), the event payloads (EDIT),
the allowlist vocabulary (RENDER) and the suggestion generator (AGENT) must reuse the option names in DX-12 and stay
inside the extension budget above.

## Open decisions

- Form-builder method name: `markdown_field`, `markdown_textarea` (matching Rails 8's `rich_textarea`) or
  `markdown_editor`. Recommendation: `markdown_field`. It reads as "a field" in any form builder, it does not claim a
  textarea when JavaScript turns it into an editor, and the benchmark report already uses it.
- Model macro: ship `has_markdown` in 0.1, later, or never. Recommendation: ship it in 0.1 as optional sugar that adds
  only `body_document` (DX-11). It mirrors `has_rich_text`, so it is easy to discover, and it adds no storage.
- Configuration style: an `Md.configure` block in `config/initializers/md.rb`, or `config.md.*` in
  `config/application.rb`. Recommendation: the initializer block generated with every option commented out (Devise
  style). It is one place, it is greppable, and DX-05 can test it.
- Install generator behaviour: edit the layout and JavaScript entry point in managed blocks, or print instructions only.
  Recommendation: edit inside managed blocks (chadcn style) and print what changed. Marksmith's generator writes only a
  config file, so its README leaves the stylesheet tag, the controller registration and sanitizing to the developer.
- Upload default: on when Active Storage is present, or always off until configured. Recommendation: on when present
  (DX-16). Paste and drag uploads are the GitHub baseline writers expect (benchmark report), and an app without Active
  Storage sees no upload control.
- Custom syntax registration: an explicit list in the initializer, or discovery by convention (`app/markdown/*_pass.rb`,
  simple_form style). Recommendation: the explicit list (DX-20). Pass order matters for rendering, and an explicit list
  makes the order visible.
- Deprecation policy before 1.0: deprecate for one release even in 0.x, or allow breaking minors. Recommendation:
  deprecate in 0.x too (DX-26). Pagy shows that skipping it teaches users to pin minors, and Papyro as first consumer
  pays the cost first.
- Docs site and sandbox timing: README only for 0.1, a docs site and sandbox before 1.0. Recommendation: README plus the
  CI-run quick start for 0.1, with the docs site and sandbox (DX-32) as a 1.0 gate together with the second, non-Papyro
  app the benchmark report requires.
- Gem name and namespace: `Md` is a placeholder. Recommendation: pick a name that is free on both RubyGems and npm and
  works unchanged as the gem, the npm package, the Ruby constant and the generator namespace (`name:install`,
  `name:doctor`), short enough that `Name.render` reads as easily as `Md.render`; reject any candidate that needs a
  suffix in one of those four places.

## Sources

- https://github.com/heartcombo/devise (accessed 2026-11-03)
- https://github.com/ddnexus/pagy (accessed 2026-11-03)
- https://ddnexus.github.io/pagy/guides/quick-start (accessed 2026-11-03)
- https://ddnexus.github.io/pagy/guides/upgrade-guide (accessed 2026-11-03)
- https://github.com/varvet/pundit (accessed 2026-11-03)
- https://guides.rubyonrails.org/action_text_overview.html (accessed 2026-11-03)
- https://guides.rubyonrails.org/maintenance_policy.html (accessed 2026-11-03)
- https://github.com/basecamp/lexxy (accessed 2026-11-03)
- https://lexxy.dev/docs/ (accessed 2026-11-03)
- https://lexxy.dev/docs/configuration (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith (accessed 2026-11-03)
- https://viewcomponent.org/guide/getting-started.html (accessed 2026-11-03)
- https://viewcomponent.org/guide/previews.html (accessed 2026-11-03)
- https://github.com/yippee-fun/phlex-rails (accessed 2026-11-03; generators read from the installed phlex-rails 2.4.0 source)
- https://github.com/heartcombo/simple_form (accessed 2026-11-03)
- https://docs.avohq.io/3.0/installation.html (accessed 2026-11-03)
- https://github.com/doncan-orozco/chadcn (accessed 2026-11-03; README read from the sibling checkout at e31f53f)
- `docs/features/markdown-editor/reports/Markdown editor benchmark.md`
- `docs/features/markdown-editor/research_notes/Markdown editor benchmark/editor_libraries.md`
