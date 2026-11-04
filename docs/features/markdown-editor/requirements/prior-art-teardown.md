# PRIOR: Prior art teardown requirements for the Md gem

This doc takes apart the closest prior art for the Md gem: Marksmith (Avo's markdown textarea), Lexxy (37signals'
Lexical editor for Action Text), Rhino Editor (TipTap for Action Text), Trix with Action Text, markdown-rails and
html-pipeline, plus GitHub's `markdown-toolbar-element`, which Marksmith builds on. For each it records the install flow,
API shape, JavaScript delivery, theming, extension points, tests and CI, release cadence and licence, and what users ask
for in the issue trackers. It then turns those findings into what Md copies, what it avoids and what it reuses instead of
rebuilding. Developer experience comes first: most of the pain users report in these trackers is integration pain
(install steps, Turbo lifecycle, asset pipelines, theming collisions), not a missing feature.

## Scope

This doc decides which lessons from prior art become requirements, and which parts of prior art Md reuses. It leaves the
design of each layer to its own area: the rendering pipeline and dialect to RENDER, the editing experience to EDIT,
asset delivery to ASSETS, tokens and overrides to THEME, view and form integration to VIEWS, install and public API to
DX. Where a lesson lands in another area, the requirement here states the lesson and its acceptance check; the synthesis
merges duplicates by ID.

Out of scope (WON'T):

- Forking or extending Marksmith as the base of Md. The benchmark already settles why: a CodeMirror 6 surface, a
  versioned sanitized pipeline and a suggestion model each replace part of Marksmith's architecture instead of extending
  it (`../reports/Markdown editor benchmark.md`, section "No Rails gem covers this, so build one").
- HTML or a document model as the stored format (Lexxy, Rhino, Trix). Markdown text stays the only source of truth.
- Depending on the Action Text editor adapter in the core. It exists only on Rails main and is marked `:nodoc:`.
- Re-evaluating editor libraries outside the Rails ecosystem; the benchmark and
  `../research_notes/Markdown editor benchmark/editor_libraries.md` cover them.
- Taking html-pipeline or markdown-rails as runtime dependencies.

## Questions

1. What do Marksmith and Lexxy users ask for most in their issues and discussions?
2. Which design choices of each prior-art project does Md adopt or reject, and why?
3. Can any part (the toolbar element, upload handling, preview endpoint, sanitizer allowlist, template handler) be reused
   instead of rebuilt?
4. How do these projects install, expose their API, deliver JavaScript and CSS, test and release, and what does each
   choice cost a newcomer?

## Findings

All facts below were read from the repositories, the RubyGems and npm registries and the trackers on 2026-11-03. Sources
are listed at the end; issue numbers refer to the trackers linked in the Sources section. Storage models, bundle sizes
and download counts that the benchmark already settled are cited from it rather than researched again.

### At a glance

| Project | What it is | Stored format | Latest release | Licence | Maintenance |
|---|---|---|---|---|---|
| Marksmith (`marksmith`, `@avo-hq/marksmith`) | Textarea + `markdown-toolbar-element` + server preview tab, Rails engine with Stimulus | Markdown | gem 0.6.0 (2026-08-14); npm 0.5.1 (2026-04-24) | MIT | Active, Avo team, 0.x, README warns the API may change |
| Lexxy (`lexxy`, `@37signals/lexxy`) | WYSIWYG custom element on Lexical for Action Text | Action Text HTML | 1.0.3 (2026-10-29) | MIT | Very active, 37signals, 82 gem versions in 14 months |
| Rhino Editor (`rhino-editor`) | TipTap custom element (lit, Shadow DOM) for Action Text | Action Text HTML | npm 0.18.6 (2026-10-29) | MIT | Active, one maintainer, pre-1.0, no Ruby gem |
| Trix + Action Text | WYSIWYG editor + Rails storage and rendering framework | Action Text HTML | trix 2.1.19 (2026-05-09); actiontext 8.1.4 (2026-09-24) | MIT | Active; being superseded by Lexxy at 37signals |
| markdown-rails (`sitepress/markdown-rails`) | Action View template handler for `.md` views | None (view files) | 2.2.0 (2025-11-04) | MIT | Low activity; renders with Redcarpet |
| html-pipeline | Text, convert, sanitize and node filter chain (commonmarker + Selma) | None (string in, HTML out) | 3.2.4 (2026-01-06) | MIT | Low cadence; GitHub no longer uses it |
| `markdown-toolbar-element` | Custom elements that apply markdown formatting to a textarea | None | 2.2.3 (2024-03-01) | MIT | Low volume but alive: fixes merged in October 2026, unreleased |

### Marksmith

- **Install.** Five manual steps: `bundle add marksmith commonmarker` (the parser gem is not a dependency), pin or
  `yarn add @avo-hq/marksmith`, register two Stimulus controllers by hand, add `stylesheet_link_tag "marksmith"`, and
  run `bin/rails generate marksmith:install`, which only writes a commented initializer. The engine appends itself to the
  host routes at `/marksmith`. Stimulus and Turbo are prerequisites; Active Storage and Tailwind are optional (README,
  install generator, engine).
- **API.** `marksmith_tag(name, **kwargs)`, `form.marksmith :body` (added to `ActionView::Helpers::FormBuilder`, with a
  ViewComponent 4 fallback), `marksmithed(body)` for display and `marksmith_asset_tags`. A `Marksmith::Editor` value
  object computes field name, value and ids; the default id is `rand(1000..9999)`, the source of the duplicate-id bugs
  #52 and #45. `Marksmith.configure` has four settings: `automatically_mount_engine`, `mount_path`, `parser`
  (commonmarker, redcarpet or kramdown) and `redcarpet_options`. The commonmarker branch calls `Commonmarker.to_html`
  with no options. Custom rendering means redefining `Marksmith::Renderer` in the host app.
- **JavaScript.** An npm package with a full bundle (115 KB, which inlines its own copy of Stimulus's `Controller`) and a
  `/core` build (20 KB, dependencies external). The gem ships no JavaScript of its own, so importmap users pin from the
  npm CDN, and the two release channels drift: gem 0.6.0 versus npm `latest` 0.5.1. Runtime dependencies are
  `markdown-toolbar-element`, `paste-markdown`, `hotkey`, `@rails/activestorage` and `@rails/request.js`.
- **Theming.** A prebuilt Tailwind v4 stylesheet (44 KB) with an `ms:` prefix and hard-coded neutral and blue colours.
  Dark mode works only through a `.dark` ancestor class. Semantic hook classes (`marksmith-editor-wrapper`,
  `marksmith-preview-pane`, ...) arrived in PR #74 as the override path. The preview uses typography classes that
  `marksmithed` output does not get, which users found confusing (#71, #33).
- **Extension points.** The preview posts to an engine controller that inherits bare `ActionController::Base` (no
  authorization hook) and answers only with a Turbo Stream, so without Turbo the request returns 204 and the spinner never
  stops (#142). Uploads use Active Storage `DirectUpload` and insert a hard-coded `/rails/active_storage/...` path. List
  continuation assigns `textarea.value`, which wipes native undo. Hotkeys install and uninstall for every
  `[data-hotkey]` on the page. Tab inserts a tab character with no escape. Adding toolbar buttons means overriding an ERB
  partial. Avo-specific field and gallery code lives in the generic gem (#67).
- **Tests and CI.** Minitest with a full dummy app. The real tests cover renderer output per parser; the preview
  controller test is an empty scaffold and the only system test is the generated Posts CRUD, which CI does not run. There
  are no JavaScript tests and the lint job is commented out.
- **Releases.** 31 versions since 2025-01-22: a burst of about 25 in early 2025, then one every two to four months. GitHub
  Releases stop at v0.4.7, so 0.4.8 to 0.6.0 have no changelog.

### Lexxy

- **Install.** No generator. Importmap apps pin `lexxy.js` and `@rails/activestorage`; bundler apps `yarn add
  @37signals/lexxy`. CSS comes from `stylesheet_link_tag "lexxy"` or the npm stylesheet exports, and apps override the
  Action Text `_content` layout to add the `lexxy-content` class. On Rails 8.0 and 8.1 the gem monkey-patches
  `rich_text_area` and its siblings to render Lexxy (which broke `add_default_name_and_id` on Rails 8.0.3, #296, #234);
  on Rails with the editor adapter it registers itself as `config.action_text.editor = :lexxy`. At boot it appends to
  `ActionText::ContentHelper.allowed_tags` and pushes `var` into Loofah's allowed CSS functions, a global mutation.
- **API.** A form-associated custom element (`lexxy-editor`) whose value is HTML, with native validation, `required`,
  `disabled` and `placeholder`. Configuration is layered: global, then preset, then kebab-case attributes per element.
  Feature switches cover attachments, code blocks, markdown shortcuts, tables and more. Namespaced DOM events
  (`lexxy:change`, the cancelable `lexxy:file-accept`, the upload lifecycle, `lexxy:insert-markdown`) carry callback
  helpers in `detail`.
- **Markdown.** Input only: typing shortcuts through Lexical transformers and plain-text paste parsed by `marked`. No
  markdown export or storage.
- **JavaScript.** Pure custom elements, no Stimulus. Two Rollup builds from one source: a self-contained ESM shipped in the
  gem for importmap (1.07 MB, 167 KB brotli for the minified file) and an npm build with Lexical, DOMPurify, marked and
  Prism kept external, with subpath exports for helpers and stylesheets. `@rails/activestorage` is an optional peer,
  imported lazily when an upload starts.
- **Theming.** Plain CSS with `--lexxy-*` custom properties in raw and semantic layers, separate content, editor and
  variables files, and zero-specificity `:where()` selectors so app CSS wins without `!important`. No built-in dark mode;
  the highlight palette uses unprefixed `--highlight-*` variables.
- **Extension points.** Prompts (`lexxy-prompt`) for mentions and commands with inline or remote sources and local or
  server filtering; Direct Upload with a documented response contract and deferred-preview polling; Prism highlighting
  with a fixed grammar set (#1192); an experimental `Lexxy.Extension` API that "may evolve with no deprecation period";
  limited toolbar control (on, off, external toolbar, or one per-button object).
- **Tests and CI.** About 930 Playwright tests across Chromium, Firefox and WebKit against a Vite harness, about 280
  Vitest unit tests and about 130 Minitest tests, with a Rails 8.1 versus Rails main matrix, RuboCop, ESLint, actionlint
  and zizmor, SHA-pinned actions, a benchmarks workflow and a docs site (lexxy.dev) deployed from the same repo.
- **Releases.** 82 gem versions from 2025-09-04 to 1.0.3. Breaking changes shipped in betas without notes (#1031). The
  1.0.2 and 1.0.3 gems bundle DOMPurify 3.3.0 although `yarn.lock` pins 3.4.17, bringing back fixed advisories (#1325).

### Rhino Editor

- No Ruby gem and no helpers: the docs have users hand-write a hidden field plus `rhino-editor` with direct-upload and
  blob URL data attributes. A gem is still open on the 1.0 wish list (#197, the most-reacted issue).
- A lit custom element with Shadow DOM over TipTap 3. The normal importmap flow fails on lit transitive dependencies
  (#159, #161, #306); the docs tell users to download a prebuilt bundle into `vendor/javascript`.
- Theming through about 23 `--rhino-*` custom properties and `::part()` hooks; toolbar buttons and icons are customizable
  through named slots. `rhino-before-initialize` and a `defer-initialize` attribute let apps configure the editor before
  it boots regardless of load order.
- CI runs a Rails app with Minitest, Capybara and Playwright, unit tests on web-test-runner, and a MinIO service so direct
  uploads are tested against real S3-compatible storage. 0.18.0 broke APIs when it moved from TipTap 2 to 3.
- The HTML round trip loses whitespace that users expected to keep (#292, 33 comments). Markdown exists only as input
  shortcuts (PR #225).

### Trix and Action Text

- `bin/rails action_text:install` pins `trix` and `@rails/actiontext` (or adds the npm packages), copies `actiontext.css`
  and the content partials, and adds migrations. `rich_textarea` defaults `data-direct-upload-url` and
  `data-blob-url-template` from the app's routes, so uploads need no configuration.
- Rendering sanitizes with the Rails safe-list sanitizer through overridable `allowed_tags`, `allowed_attributes` and
  `scrubber`; `config.action_text.sanitizer_vendor` swaps the sanitizer.
- Uploads go through `AttachmentUpload`, which wraps `DirectUpload` and dispatches `direct-upload:*` events. Trix exposes
  `trix-file-accept` (cancelable) and `trix-attachment-add`.
- Rails main (8.2.0.alpha, unreleased) adds a pluggable editor adapter (`ActionText::Editor` with `as_canonical`,
  `as_editable` and `editor_tag`; rails#51238, plus block children for Lexxy in rails#56926) and an HTML-to-markdown
  export (`ActionText::Content#to_markdown`, rails#56858) that already has open bugs (#59019 tables, #59359 list start)
  and a fixed stored XSS (rails#58754). The adapter API is `:nodoc:`.
- Trix refused markdown: "Add markdown support or state that it will not be added" (trix#626, over 100 thumbs-up) was
  closed with no plans to add it, and the `md-input` PR (trix#737) was closed unmerged. In that thread users point at
  37signals' unreleased House editor as the wanted answer.
- Trix's stylesheet uses no CSS custom properties, dark mode is an open request since 2021 (trix#947), and the README
  tells apps to copy the content styles under their own class name, which forks them.

### markdown-rails

- `bin/rails g markdown_rails:install` writes an initializer and an app-owned renderer subclass
  (`app/markdown/application_markdown.rb`). `MarkdownRails.handle :md` registers one Action View template handler per
  extension; a separate `markerb` handler runs ERB first and is documented as for trusted content only.
- The handler is about 40 lines around `ActionView::Template.register_template_handler`. Renderer options are reachable
  only by subclassing a Redcarpet renderer (#4, PR #5 unmerged), images under Propshaft are unsolved (#3), and the
  default view context is `ApplicationController.new.view_context`, which is brittle in engines and API-only apps. The
  original `joliss/markdown-rails` repository is abandoned; maintenance moved to Brad Gessler (joliss#12).

### html-pipeline

- Phases: text filters on the string, exactly one convert filter (commonmarker 2.x in the built-in `MarkdownFilter`), a
  sanitization step that is on unless `sanitization_config: nil` is passed explicitly, then node filters selected by CSS
  selector, all sanitization and node filters in one streaming Selma pass. `SanitizationFilter::DEFAULT_CONFIG` is a
  frozen allowlist that apps `deep_dup` and extend. Per-call `context:` and ActiveSupport::Notifications instrumentation
  are built in.
- Risks: v3 lost inline-style sanitization, which blocks GFM table `text-align` (#405); point releases regressed (#413
  "v3.2.1 is badly broken", #407 node filters applied twice); a filter rename is pending (#430).

### `markdown-toolbar-element`

- `markdown-toolbar` with a `for` attribute naming the textarea, and buttons such as `md-bold`, `md-link`,
  `md-task-list`; a WAI-ARIA toolbar with roving tabindex. Zero dependencies, about 5 KB gzipped, MIT.
- It works only on an `HTMLTextAreaElement`: it computes the new text and selection from `textarea.value` and applies it
  with `execCommand('insertText')`, falling back to assigning `value`. With CodeMirror 6 the visible surface is a
  contenteditable and the textarea is hidden, so the element would edit the hidden field and fight the editor state. Its
  formatting rules (prefix, suffix, multiline, list numbering, word expansion, toggling) are pure functions that can be
  ported to CodeMirror commands. Open issues show the costs to avoid: auto-registration at import breaks server rendering
  (#68), buttons without discernible text (#43), hotkeys broken on non-US layouts (#15).

### What Marksmith and Lexxy users ask for

Marksmith (40 issues, 11 open; Discussions disabled; low reaction counts, at most 4):

| Theme | Issues | What users report or ask |
|---|---|---|
| Turbo and several editors per page | #45 (14 comments), #52, #142 | Editors loaded in frames or broadcasts fail to preview; duplicate ids; preview silently needs Turbo |
| Rendering parity with GitHub | #19 (most reacted), #3, #15, #7 | Move to commonmarker, task lists, syntax highlighting, who sanitizes `marksmithed` output |
| Preview and renderer hooks | #103, #138 | Custom renderer (shortcodes) works on the show page but not in the preview; an event after preview so MathJax can run |
| Preview versus display styling, dark mode | #71, #33 | Preview and `marksmithed` look different; preview unreadable in Tailwind 4 dark mode |
| Uploads | #8, #20, #80, #67 | Wrong inserted path, video and audio, a media library without Avo |
| Engine and asset integration | #18, #27, #35, #114, #51 | Eager-load and partial-Rails boot failures, runtime asset compile, Rails 8.2 deprecation, Safari textarea sizing |
| Editing extras | #4, #81, #82 | Keyboard shortcuts (shipped), mentions, text expander |

No Marksmith issue asks for a live preview; the requests are about integration and parity.

Lexxy (138 issues, 27 open; 81 discussions):

| Theme | Issues | What users report or ask |
|---|---|---|
| Markdown as the stored format | D391 (top discussion, 9 upvotes), D174, #914, #916 | Export or store markdown (one comment wants an API that reads and writes markdown for AI assistants); extend markdown syntax; markdown paste quirks |
| Per-feature control | #1097 (top issue, 10 reactions), D497, D313 | More feature switches and a way to hide toolbar buttons without forking |
| Turbo lifecycle | #688 (most commented), #263, #196, #1200, #1283 | Not initializing in frames, morphing breaks listeners, content lost or pristine value submitted around the Turbo cache |
| CSS collisions | #485, #732 | Tailwind preflight and Bootstrap break the toolbar |
| Packaging | #1057, #1290, #1325 | Task lists unavailable because the importmap bundle cannot take extra Lexical packages; npm CSS path confusion; stale DOMPurify in the bundle |
| Round-trip loss | #1004, #938, #714, #284 | Line breaks lost on save, `s` instead of `del`, dropped empty lines, Trix content migration |
| Mobile, IME, accessibility, i18n | #1078, #1246, #877, D1258 | iOS capitalization, Korean IME duplication, moving attachments by keyboard, hard-coded English toolbar |

The most-voted Lexxy request is the thing Lexxy will not do: keep markdown. Across both trackers the recurring cost is
integration with Turbo, CSS frameworks and asset pipelines.

### Adopt and avoid, per project

| Project | Adopt | Avoid |
|---|---|---|
| Marksmith | Markdown textarea as the form value; form-builder method with a ViewComponent fallback; `paste-markdown`-style HTML-to-markdown paste; locale files for UI strings; partials apps can override | Generator that only writes config; gem and npm versions released apart; Turbo-only preview with no auth hook; renderer customized by shadowing a class; hard-coded upload path; `textarea.value` writes that kill undo; page-wide hotkeys; prebuilt utility CSS with `.dark`-only dark mode; admin-framework code in the core; CI that skips system tests and lint |
| Lexxy | Zero-config Rails path; layered config (global, preset, per field) and feature switches; one source, two builds (self-contained ESM in the gem, externals in npm); lazy optional peers; namespaced, low-specificity CSS tokens; namespaced cancelable events; documented upload response contract; three-engine browser tests plus a Rails matrix; docs site and sandbox in the repo | HTML storage and editor-side normalization; monkey-patched Action Text helpers; global sanitizer mutations; a bundle nobody checks against the lockfile; a bundle that cannot take extra plugins; hard-coded English UI; an extension API with no deprecation policy; unprefixed CSS variables |
| Rhino Editor | `before-initialize` hook and `defer-initialize`; namespaced tokens and `::part()`-style hooks; toolbar slots; real-storage upload tests in CI | No Ruby helpers; lit and Shadow DOM transitive dependencies that break importmap; breaking changes in 0.x minors; HTML round trip |
| Trix + Action Text | Upload URLs defaulted from routes; `DirectUpload` events; one content class shared by editor and display; JavaScript served by the gem for importmap and published to npm | HTML as the source of truth; toolbar as an HTML string in JS config; styles without custom properties or dark mode; copying CSS into apps; relying on the unreleased editor adapter |
| markdown-rails | App-owned renderer class written by the generator; trusted and untrusted profiles kept apart; safe defaults | Redcarpet; options reachable only by subclassing; `ApplicationController.new.view_context`; no Propshaft image story |
| html-pipeline | Phase model with a mandatory sanitize step; frozen allowlist to dup and extend; per-call context; instrumentation | A hard runtime dependency (low cadence, point-release regressions, pending rename); losing table alignment in sanitization |
| `markdown-toolbar-element` | Formatting rules and toolbar keyboard pattern | Using it directly with CodeMirror; auto-registration at import; icon-only buttons without accessible names |

### What can be reused instead of rebuilt

| Part | Verdict | How |
|---|---|---|
| `markdown-toolbar-element` formatting rules | Port, with attribution (MIT) | Turn its style table and selection math into CodeMirror commands that dispatch transactions; keep the roving-tabindex toolbar pattern. The element itself cannot drive CodeMirror. |
| Active Storage direct upload (Action Text `AttachmentUpload`, Lexxy's upload contract, Marksmith's controller) | Reuse the protocol, write the glue | `@rails/activestorage` `DirectUpload` with `direct-upload:*` events, URLs from the app's routes as `rich_textarea` does, a placeholder replaced on completion, Lexxy's response fields and deferred-preview polling. About 40 lines in Marksmith; the fixes are known (path, MIME list, errors, undo). |
| Preview endpoint | Pattern only | Server render and swap is right; return HTML over fetch, Turbo Stream optional, authorization hook, request context, post-render event. |
| Sanitizer allowlist | Starting point | html-pipeline's `DEFAULT_CONFIG` or Action Text's allowed tags as the first allowlist, reviewed by RENDER; Rails' `allowed_uri?` for link schemes. |
| Template handler | Pattern only | markdown-rails' 40-line handler shape, backed by Md's own pipeline, with an untrusted default profile. |
| List continuation | Use CodeMirror's | `@codemirror/lang-markdown` ships `insertNewlineContinueMarkup`; Marksmith's regex is a parity reference for task lists and numbering. |
| `paste-markdown` | Needs a spike | Converts pasted HTML, links and tables to markdown on textarea paste events; compatibility with CodeMirror's paste handling is unverified. |
| Lexxy CSS tokens and content styles, Prism token variables | Reference | A checklist of what rendered-markdown typography must cover (headings, lists, tables, code, quotes, focus ring), mapped onto THEME's tokens. |
| Lexxy's Rollup dual build and Playwright harness, Rhino's MinIO CI service | Reference | Templates for packaging and CI. |
| Marksmith form-builder extension and locale keys | Reuse the idea | Small and proven; ids from `dom_id` or `SecureRandom`, never `rand`. |

## Requirements

Grouped by the lesson they come from. Each requirement names the prior art that motivates it; the synthesis merges them
with the area that owns the topic.

### Storage and fidelity

- **PRIOR-01** (MUST) The editor never rewrites the stored markdown on load or on an unedited save: what the field held is
  what the form submits, byte for byte (Lexxy #1004, #938, #714, Rhino #292, Trix #626). Acceptance: a fixture corpus
  of tricky markdown (reference links, footnotes, mixed list markers, escapes, trailing spaces, CRLF) round-trips through
  open and submit in a system test with no byte changed.
- **PRIOR-02** (MUST) Every edit command (toolbar, shortcut, list continuation, upload insert, paste conversion) goes
  through the editor's transaction API so a single undo reverts it (Marksmith's `textarea.value` writes). Acceptance: a
  browser test runs each command, presses Cmd+Z or Ctrl+Z once and gets the previous text and selection back.

### Install and API

- **PRIOR-03** (MUST) One generator command finishes the install: JavaScript pins or package, controller registration,
  stylesheet and initializer, with no manual step left (Marksmith's config-only generator, Lexxy's missing generator,
  Rhino's missing gem). Acceptance: in a fresh `rails new` app, `bundle add` plus the generator gives a working editor
  that submits its value, with no other file edited.
- **PRIOR-04** (MUST) The gem defines its own form-builder method and view helper and never aliases, prepends or
  monkey-patches Rails or Action Text helpers (Lexxy's `rich_text_area` override and #296, #234). Acceptance: a grep of
  the gem finds no `alias_method`, `prepend` or reopened class on Action View or Action Text helpers, and the README shows
  `f.markdown_field :body` working beside `f.rich_textarea` in the same form.
- **PRIOR-05** (MUST) Field ids are deterministic and unique per record and attribute, so several editors on one page,
  inside frames and in broadcasts never collide (Marksmith #52, #45, `rand(1000..9999)`). Acceptance: a system test
  renders two editors for the same attribute of two records plus one inside a Turbo Frame, and every editor previews and
  submits its own value.
- **PRIOR-06** (MUST) The core has no admin-framework code; integrations such as Avo or ActiveAdmin live in optional files
  loaded only when that framework is present (Marksmith's Avo field and gallery, #67). Acceptance: the gem boots and its
  test suite passes in an app without Avo, and a grep of the core finds no reference to an admin framework's constants.
- **PRIOR-07** (SHOULD) Options resolve in three layers, global configuration, then a named preset, then per-field
  options, with a feature switch for each optional capability (Lexxy's configure and presets, #1097). Acceptance: a
  test sets tables on globally, off in a preset and on again for one field, and each field shows the expected commands.
- **PRIOR-08** (SHOULD) The toolbar is declared as a list of button names in the field options or preset, and an app adds a
  custom button by registering it, without overriding a partial or a JS template (Lexxy D497, D313, Marksmith's action
  bar partial, Trix's `getDefaultHTML`). Acceptance: the README shows one option that removes two default buttons and one
  registration that adds a custom button, both covered by a system test.

### JavaScript delivery

- **PRIOR-09** (MUST) The gem serves a self-contained ESM build from its own assets for importmap apps, so pinning never
  fetches transitive dependencies from a CDN (Marksmith's CDN pins, Rhino #159, #161, #306). Acceptance: an importmap
  dummy app with network access blocked in CI boots the editor using only files served by the gem.
- **PRIOR-10** (MUST) The gem and the npm package are released together from the same commit with the same version
  (Marksmith gem 0.6.0 versus npm 0.5.1). Acceptance: the release workflow fails when the gemspec version and
  `package.json` version differ, and publishes both or neither.
- **PRIOR-11** (MUST) CI rebuilds the vendored JavaScript and fails when it differs from the committed or packaged build,
  or when a bundled dependency's version differs from the lockfile (Lexxy #1325). Acceptance: a CI job compares the
  dependency versions embedded in the built file with the lockfile and fails on a mismatch.
- **PRIOR-12** (SHOULD) Importmap apps can add editor extensions, such as an extra CodeMirror language, as separate pins
  without rebuilding the gem's bundle (Lexxy #1057). Acceptance: the importmap dummy app registers one extra language
  pack through a documented hook and highlights a fenced block in that language.
- **PRIOR-13** (SHOULD) Optional peers such as `@rails/activestorage` are imported lazily, only when the feature that needs
  them runs (Lexxy's upload node). Acceptance: an app without Active Storage loads the editor with no module error, and
  the network panel shows no Active Storage module until a file is dropped.

### Preview and rendering

- **PRIOR-14** (MUST) The preview works without Turbo: the endpoint returns HTML over `fetch`, and a Turbo Stream response
  is an option, not the only path (Marksmith #142). Acceptance: a system test with Turbo not loaded shows the rendered
  preview, and a request test gets HTML back from the endpoint.
- **PRIOR-15** (MUST) The preview endpoint runs the same render pipeline and the same content class as the display helper,
  and the pipeline receives the request context (Marksmith #71, #103, #33). Acceptance: a test renders one document through
  the preview endpoint and through the view helper and gets identical HTML, and a custom filter that reads the context
  works in both.
- **PRIOR-16** (MUST) The preview endpoint passes through an app-supplied authorization hook and the gem documents it;
  no rendering endpoint is reachable by an unauthenticated visitor unless the app allows it (Marksmith's controller on
  bare `ActionController::Base`). Acceptance: a request test with the hook denying gets a 403 or 404, and the install
  generator writes the hook into the initializer.
- **PRIOR-17** (MUST) Rendering is customized through options and filter hooks around a mandatory sanitize step, never by
  redefining gem classes, and turning sanitizing off needs an explicit, documented opt-out (html-pipeline's phase model,
  markdown-rails #4, Marksmith's shadowed renderer). Acceptance: the README adds a node filter through configuration, and a
  test shows raw HTML is scrubbed unless the opt-out is set.
- **PRIOR-18** (MUST) The gem keeps its sanitizer configuration local and never mutates global allowlists such as Loofah
  constants or `ActionText::ContentHelper.allowed_tags` (Lexxy's engine initializer). Acceptance: a test captures those
  values before and after the gem boots and finds them unchanged.
- **PRIOR-19** (SHOULD) The viewer and the preview dispatch a namespaced DOM event after new HTML is in place, so apps can
  run MathJax, analytics or their own enhancers (Marksmith #138). Acceptance: a system test listens for the event and sees
  it fire once per preview refresh and once per viewer connect.
- **PRIOR-20** (SHOULD) The gem offers an optional `.md` template handler backed by its own pipeline, with the untrusted
  profile by default and ERB inside markdown only as an explicit trusted opt-in (markdown-rails' `md` and `markerb`).
  Acceptance: a dummy app renders an `.html.md` view through the gem pipeline, and ERB tags in it stay literal unless the
  trusted handler is registered.

### Turbo lifecycle

- **PRIOR-21** (MUST) The editor survives Turbo Frame navigation, morphing page refreshes, cache snapshots and
  back/forward restores without double mounting, lost content or a stale submitted value (Lexxy #688, #263, #196, #1200,
  #1283, Marksmith #45). Acceptance: a system test suite with two editors covers frame advance, morph refresh,
  `turbo:before-cache` and history restore, and each submit sends the last typed text.

### Theming

- **PRIOR-22** (MUST) Editor and viewer styles use namespaced CSS custom properties and zero-specificity selectors, ship
  light and dark values that follow both `prefers-color-scheme` and an app class, and do not ship prebuilt utility-class
  CSS (Marksmith's 44 KB Tailwind file and #33, Trix #947, Lexxy's `:where()` and unprefixed variables). Acceptance: a
  visual test restyles editor and viewer by overriding tokens only, with no `!important`, in light and dark mode under
  both triggers.
- **PRIOR-23** (MUST) The editor's styles hold up inside apps that use Tailwind preflight or Bootstrap resets (Lexxy
  #485, #732). Acceptance: the dummy app has Tailwind and Bootstrap variants and a screenshot comparison of the toolbar
  and editor passes in both.

### Uploads

- **PRIOR-24** (MUST) Uploads use Active Storage direct upload with the direct-upload and blob URLs generated from the
  app's routes, a placeholder while the file uploads, a cancelable accept event, progress events and a visible error
  (Marksmith #8 and its hard-coded path, Action Text `rich_textarea` defaults, Lexxy's upload contract). Acceptance: a
  system test in an app with a custom Active Storage route prefix inserts the right URL, a cancelled accept event inserts
  nothing, and a failed upload shows an error message in the editor.
- **PRIOR-25** (SHOULD) The accepted upload types are configurable and include video and audio, inserted as markdown the
  viewer renders (Marksmith #20, #80). Acceptance: with video allowed, dropping an MP4 inserts markdown that the viewer
  renders as a playable video.
- **PRIOR-26** (COULD) The CI suite tests uploads end to end against S3-compatible storage, not only the disk service
  (Rhino's MinIO service). Acceptance: one CI job runs the upload system tests against a MinIO service.

### Editing extras

- **PRIOR-27** (MUST) Keyboard shortcuts are bound to the editor instance, not the page, and Tab never traps focus: a
  documented key combination moves focus out of the editor (Marksmith's page-wide hotkeys and Tab indent,
  `markdown-toolbar-element` #15). Acceptance: with two editors on a page, a shortcut acts only in the focused one, and a
  keyboard-only test can tab into and out of each editor.
- **PRIOR-28** (SHOULD) The toolbar's formatting commands reproduce the rules of `markdown-toolbar-element`, ported to
  editor commands with attribution, and its buttons follow the WAI-ARIA toolbar pattern with accessible names (its #43).
  Acceptance: unit tests replay that element's formatting cases through the ported commands and get the same text and
  selection, and an axe check finds no unnamed buttons.
- **PRIOR-29** (SHOULD) Pasting converts HTML, links and tables to markdown, and pasted plain-text markdown is kept as
  typed whatever else the clipboard holds (Marksmith's `paste-markdown`, Lexxy #914). Acceptance: a browser test pastes an
  HTML table and gets a GFM table, and pastes markdown with an HTML flavour present and gets the markdown unchanged.
- **PRIOR-30** (COULD) Mentions and emoji completion take an app-supplied source (inline list or remote endpoint with a
  filter parameter), modelled on Lexxy's prompt contract (Marksmith #81, #82). Acceptance: a dummy app registers a remote
  source and typing `@` followed by letters inserts the chosen item.
- **PRIOR-31** (MUST) Every user-facing string in the editor UI goes through the app's I18n, with English and Spanish
  shipped (Lexxy D1258, Marksmith's locale files). Acceptance: switching the dummy app to Spanish shows Spanish toolbar
  labels, tooltips and upload messages, and a check finds no hard-coded English string in the JavaScript or templates.

### Tests, docs and releases

- **PRIOR-32** (MUST) CI runs, as required checks, browser tests of the editor across Chromium, Firefox and WebKit, Rails
  system tests of the integration in a matrix of supported Rails versions, and lint for Ruby and JavaScript (Lexxy's
  suite; Marksmith's skipped system tests and disabled lint). Acceptance: the CI workflow defines those jobs and branch
  protection lists them as required.
- **PRIOR-33** (SHOULD) The repository holds a docs site and a live sandbox, deployed by a workflow on changes to the docs
  (Lexxy's lexxy.dev). Acceptance: a docs workflow publishes the site from the repo and the sandbox page runs the editor
  from the current build.
- **PRIOR-34** (MUST) Every release has a changelog entry, follows semantic versioning, and any public API marked
  experimental states its deprecation policy (Marksmith's releases without notes after v0.4.7, Lexxy #1031 and its
  experimental extension API). Acceptance: the release workflow fails when `CHANGELOG.md` has no section for the version
  being released.
- **PRIOR-35** (MUST) The README credits the prior art Md learns from or ports code from, and every ported file keeps its
  original MIT notice. Acceptance: the README has a prior-art section naming Marksmith, Lexxy, `markdown-toolbar-element`,
  html-pipeline and markdown-rails, and each ported file carries the source licence header.

## Developer experience notes

- **PRIOR-03, PRIOR-09, PRIOR-10, PRIOR-13** cost the newcomer nothing and remove the steps that generate most install
  issues in Marksmith and Rhino; they cost the maintainers a release workflow and a bundle build.
- **PRIOR-04, PRIOR-05** add one form-builder method and one helper, the smallest surface that still covers forms and
  standalone tags. Not overriding `rich_textarea` means a newcomer types a different method name, which is clearer than
  silently changing what an existing helper renders.
- **PRIOR-07, PRIOR-08** add configuration surface (presets, feature switches, a toolbar list). Each has a default that
  works untouched, so a newcomer never needs them on day one; they exist because the top Lexxy issue asks for them.
- **PRIOR-16** adds one required decision at install time: who may render previews. The generator writes a default that
  allows signed-in users of the app's own authentication and explains how to change it, so the cost is reading one
  commented block.
- **PRIOR-17, PRIOR-20** add filter and handler APIs that only advanced apps touch. A filter is one class with one method,
  mirroring html-pipeline's node filter, so developers who know that gem have nothing new to learn.
- **PRIOR-19, PRIOR-24, PRIOR-30** add namespaced DOM events and a source contract; they replace monkey-patching or
  partial overrides, which cost far more to maintain.
- **PRIOR-22, PRIOR-23** keep theming to CSS variables, the skill every Rails developer with Tailwind or plain CSS already
  has. Utility-class CSS would have been easier to ship but harder to override.
- **PRIOR-32 to PRIOR-35** cost newcomers nothing directly; they are what makes upgrades predictable, which Marksmith's
  0.x warning and Lexxy's beta breakages show users care about.

## Open decisions

- Should the editor's JavaScript API be a Stimulus controller over the real textarea, like Marksmith, or a
  form-associated custom element, like Lexxy, Rhino and Trix? Recommendation: a Stimulus controller over the real
  textarea. The textarea is already a native form control, so form association, validation and progressive enhancement
  come free, Stimulus matches Papyro and most Hotwire apps, and no lit or Shadow DOM dependency can break importmap. Add a
  thin custom element later only if non-Stimulus apps ask for it.
- Port `markdown-toolbar-element`'s formatting rules into editor commands, or depend on the element? Recommendation: port
  with attribution (PRIOR-28). The element only drives a visible textarea and has not had a release since 2024.
- Which sanitizer engine: Selma (as in html-pipeline, streaming and fast) or `rails-html-sanitizer` and Loofah (as in
  Action Text, familiar to Rails developers)? Recommendation: `rails-html-sanitizer` for 0.1 behind a small interface
  that RENDER owns, with a benchmark spike before 1.0 deciding whether Selma is worth a native dependency.
- Mirror html-pipeline's filter interface so its existing node filters plug in, or define a smaller interface of Md's
  own? Recommendation: Md's own interface whose node filter signature matches html-pipeline's (`selector` plus
  `handle_element`), with no dependency on the gem, so porting a filter is a copy, not an adapter.
- Contribute the small fixes found here (Turbo-free preview, upload path, undo-safe list continuation) upstream to
  Marksmith? Recommendation: yes, as issues or PRs credited to the research, without making Md's plan wait on them;
  they help Marksmith users and cost little.
- Ship an Action Text editor adapter for Md? Recommendation: not before Rails releases the adapter API as public
  (it is `:nodoc:` on main today); revisit after 1.0 as an optional bridge, since Action Text's canonical form is HTML.
- Keep admin-framework integrations in the Md repository or in separate gems? Recommendation: optional files in the Md
  repository loaded only when the framework is present (PRIOR-06), tested in a later CI matrix, until one of them needs
  its own release cadence.

## Sources

- https://github.com/avo-hq/marksmith (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/blob/main/README.md (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/blob/main/lib/generators/marksmith/install_generator.rb (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/blob/main/lib/marksmith/engine.rb (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/blob/main/lib/marksmith/configuration.rb (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/blob/main/app/models/marksmith/editor.rb (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/blob/main/app/models/marksmith/renderer.rb (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/blob/main/app/controllers/marksmith/markdown_previews_controller.rb (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/blob/main/app/frontend/entrypoints/javascript/controllers/marksmith_controller.js (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/blob/main/app/frontend/entrypoints/javascript/controllers/list_continuation_controller.js (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/blob/main/app/frontend/entrypoints/application.css (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/blob/main/package.json (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/blob/main/.github/workflows/ci.yml (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/pull/74 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/3 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/4 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/7 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/8 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/15 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/18 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/19 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/20 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/27 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/33 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/35 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/45 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/51 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/52 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/67 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/71 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/80 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/81 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/82 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/103 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/114 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/138 (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith/issues/142 (accessed 2026-11-03)
- https://rubygems.org/api/v1/versions/marksmith.json (accessed 2026-11-03)
- https://registry.npmjs.org/@avo-hq/marksmith (accessed 2026-11-03)
- https://github.com/basecamp/lexxy (accessed 2026-11-03)
- https://dev.37signals.com/lexxy-1-0/ (accessed 2026-11-03)
- https://lexxy.dev (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/blob/main/lib/lexxy/engine.rb (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/blob/main/lib/lexxy.rb (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/blob/main/home/docs/index.md (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/blob/main/home/docs/configuration.md (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/blob/main/home/docs/events.md (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/blob/main/home/docs/attachments.md (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/blob/main/home/docs/extensions.md (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/blob/main/home/docs/css-setup.md (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/blob/main/app/assets/stylesheets/lexxy-variables.css (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/blob/main/rollup.config.mjs (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/blob/main/rollup.config.npm.mjs (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/blob/main/.github/workflows/ci.yml (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/discussions/391 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/discussions/174 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/discussions/313 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/discussions/497 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/discussions/1258 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/1097 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/1057 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/485 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/732 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/688 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/263 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/196 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/1200 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/1283 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/284 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/296 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/234 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/1325 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/1290 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/1192 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/1078 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/1246 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/877 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/914 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/916 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/1004 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/938 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/714 (accessed 2026-11-03)
- https://github.com/basecamp/lexxy/issues/1031 (accessed 2026-11-03)
- https://rubygems.org/api/v1/versions/lexxy.json (accessed 2026-11-03)
- https://registry.npmjs.org/@37signals/lexxy (accessed 2026-11-03)
- https://github.com/KonnorRogers/rhino-editor (accessed 2026-11-03)
- https://github.com/KonnorRogers/rhino-editor/blob/main/docs/src/_documentation/tutorials/01-getting-started.md (accessed 2026-11-03)
- https://github.com/KonnorRogers/rhino-editor/blob/main/docs/src/_documentation/tutorials/04-usage-with-rails.md (accessed 2026-11-03)
- https://github.com/KonnorRogers/rhino-editor/blob/main/docs/src/_documentation/references/04-modifying-the-editor.md (accessed 2026-11-03)
- https://github.com/KonnorRogers/rhino-editor/blob/main/src/exports/styles/rhino-editor.css (accessed 2026-11-03)
- https://github.com/KonnorRogers/rhino-editor/blob/main/.github/workflows/tests.yml (accessed 2026-11-03)
- https://github.com/KonnorRogers/rhino-editor/blob/main/CHANGELOG.md (accessed 2026-11-03)
- https://github.com/KonnorRogers/rhino-editor/issues/197 (accessed 2026-11-03)
- https://github.com/KonnorRogers/rhino-editor/issues/159 (accessed 2026-11-03)
- https://github.com/KonnorRogers/rhino-editor/issues/161 (accessed 2026-11-03)
- https://github.com/KonnorRogers/rhino-editor/issues/306 (accessed 2026-11-03)
- https://github.com/KonnorRogers/rhino-editor/issues/292 (accessed 2026-11-03)
- https://github.com/KonnorRogers/rhino-editor/pull/225 (accessed 2026-11-03)
- https://registry.npmjs.org/rhino-editor (accessed 2026-11-03)
- https://github.com/basecamp/trix (accessed 2026-11-03)
- https://github.com/basecamp/trix/blob/main/README.md (accessed 2026-11-03)
- https://github.com/basecamp/trix/issues/626 (accessed 2026-11-03)
- https://github.com/basecamp/trix/pull/737 (accessed 2026-11-03)
- https://github.com/basecamp/trix/issues/947 (accessed 2026-11-03)
- https://github.com/rails/rails/blob/main/actiontext/lib/generators/action_text/install/install_generator.rb (accessed 2026-11-03)
- https://github.com/rails/rails/blob/main/actiontext/app/helpers/action_text/tag_helper.rb (accessed 2026-11-03)
- https://github.com/rails/rails/blob/main/actiontext/app/helpers/action_text/content_helper.rb (accessed 2026-11-03)
- https://github.com/rails/rails/blob/main/actiontext/app/javascript/actiontext/attachment_upload.js (accessed 2026-11-03)
- https://github.com/rails/rails/blob/main/actiontext/lib/action_text/editor.rb (accessed 2026-11-03)
- https://github.com/rails/rails/blob/main/actiontext/lib/action_text/markdown_conversion.rb (accessed 2026-11-03)
- https://github.com/rails/rails/pull/51238 (accessed 2026-11-03)
- https://github.com/rails/rails/pull/56926 (accessed 2026-11-03)
- https://github.com/rails/rails/pull/56858 (accessed 2026-11-03)
- https://github.com/rails/rails/pull/58754 (accessed 2026-11-03)
- https://github.com/rails/rails/issues/59019 (accessed 2026-11-03)
- https://github.com/rails/rails/issues/59359 (accessed 2026-11-03)
- https://rubygems.org/api/v1/versions/actiontext.json (accessed 2026-11-03)
- https://registry.npmjs.org/trix (accessed 2026-11-03)
- https://github.com/sitepress/markdown-rails (accessed 2026-11-03)
- https://github.com/sitepress/markdown-rails/blob/main/lib/markdown-rails/handler.rb (accessed 2026-11-03)
- https://github.com/sitepress/markdown-rails/blob/main/lib/markdown-rails/renderer/rails.rb (accessed 2026-11-03)
- https://github.com/sitepress/markdown-rails/issues/3 (accessed 2026-11-03)
- https://github.com/sitepress/markdown-rails/issues/4 (accessed 2026-11-03)
- https://github.com/sitepress/markdown-rails/pull/5 (accessed 2026-11-03)
- https://github.com/joliss/markdown-rails/issues/12 (accessed 2026-11-03)
- https://rubygems.org/api/v1/versions/markdown-rails.json (accessed 2026-11-03)
- https://github.com/gjtorikian/html-pipeline (accessed 2026-11-03)
- https://github.com/gjtorikian/html-pipeline/blob/main/README.md (accessed 2026-11-03)
- https://github.com/gjtorikian/html-pipeline/blob/main/lib/html_pipeline/sanitization_filter.rb (accessed 2026-11-03)
- https://github.com/gjtorikian/html-pipeline/blob/main/lib/html_pipeline/convert_filter/markdown_filter.rb (accessed 2026-11-03)
- https://github.com/gjtorikian/html-pipeline/issues/405 (accessed 2026-11-03)
- https://github.com/gjtorikian/html-pipeline/issues/413 (accessed 2026-11-03)
- https://github.com/gjtorikian/html-pipeline/issues/407 (accessed 2026-11-03)
- https://github.com/gjtorikian/html-pipeline/issues/430 (accessed 2026-11-03)
- https://rubygems.org/api/v1/versions/html-pipeline.json (accessed 2026-11-03)
- https://github.com/github/markdown-toolbar-element (accessed 2026-11-03)
- https://github.com/github/markdown-toolbar-element/blob/main/src/index.ts (accessed 2026-11-03)
- https://github.com/github/markdown-toolbar-element/pull/110 (accessed 2026-11-03)
- https://github.com/github/markdown-toolbar-element/pull/116 (accessed 2026-11-03)
- https://github.com/github/markdown-toolbar-element/issues/68 (accessed 2026-11-03)
- https://github.com/github/markdown-toolbar-element/issues/43 (accessed 2026-11-03)
- https://github.com/github/markdown-toolbar-element/issues/15 (accessed 2026-11-03)
- `../reports/Markdown editor benchmark.md` (benchmark report, sections on libraries and the gem landscape)
- `../research_notes/Markdown editor benchmark/editor_libraries.md` (storage models, sizes, maintenance)
