# Md gem: consolidated requirements and integration plan

This document merges the ten area docs in `requirements/` into one plan for a standalone Rails gem for markdown
viewers and editors (placeholder name `Md` until the sign-off picks one), with Papyro as its first consumer. It traces
every requirement ID, resolves the conflicts between the docs or escalates them, puts the Rails integration plan in one
place, assigns every MUST to a release, and lists the decisions the maintainer makes in the sign-off
(`DECISIONS.md`). The implementation epic is planned from this document and `DECISIONS.md`.

Inputs: the area docs as merged on `main` at `0f7ae55b` (PRs #339, #342 to #351), the benchmark report
(`reports/Markdown editor benchmark.md`) and the `shared` notes the research workers left on the epic's board issues
#324 to #333.

## How to read this document

- **Priorities.** Developer experience first, then the writer's and reader's experience, then customization
  (`requirements/README.md`). The release plan lists DX first in every release for that reason.
- **IDs are the area docs'.** This document defines no requirement of its own. Where a conflict changes how an area
  requirement is built, the change is written here as a resolution (C-01 to C-25) and the Notes column of the
  traceability table points to it; the implementation epic applies it and the area doc keeps its ID.
- **Effective priority.** A SHOULD or COULD that a MUST depends on is scheduled with that MUST: RENDER-23, RENDER-27,
  RENDER-31, RENDER-35, RAILS-06, RAILS-32, DX-11, DX-17, PRIOR-07, PRIOR-08 and ASSETS-19 ship in 0.1, and ASSETS-06 in
  0.3. The Priority column keeps the area doc's MoSCoW value; the Release column shows when it ships.
- **Release.** `0.1` to `0.4` are the 0.x series in the order this plan proposes, `1.0` is the stability release, and
  `later` holds SHOULD and COULD items with no release yet. For PAPYRO rows the release is the gem release Papyro adopts
  the requirement with. PAPYRO prerequisites (migration steps 0 and 1) show 0.1, meaning before Papyro adopts 0.1.
- **Departures from the benchmark.** The benchmark's phase 1 included uploads and agent read/propose; here the gem's
  upload endpoint is 0.2 (Papyro uses its own adapter in 0.1) and the agent layer 0.4. RENDER-10 drops design rule 5's
  raw-HTML opt-in for 0.x. D-03 narrows design rule 1.
- **Open decisions** are numbered D-01 to D-15 when they cross areas; the decisions each area doc raised are listed
  after them with the synthesis view. Every one has a recommendation.

### Requirements by area

| Area | Doc | MUST | SHOULD | COULD | Total |
|------|-----|------|--------|-------|-------|
| DX | `developer-experience.md` | 21 | 11 | 2 | 34 |
| RAILS | `rails-framework-integration.md` | 27 | 8 | 1 | 36 |
| ASSETS | `asset-pipeline-integration.md` | 15 | 5 | 0 | 20 |
| VIEWS | `view-and-form-integration.md` | 13 | 7 | 3 | 23 |
| EDIT | `editor-ux.md` | 31 | 9 | 3 | 43 |
| RENDER | `render-and-viewer.md` | 33 | 15 | 6 | 54 |
| THEME | `theming-and-customization.md` | 14 | 6 | 1 | 21 |
| AGENT | `agent-layer.md` | 25 | 8 | 3 | 36 |
| PRIOR | `prior-art-teardown.md` | 24 | 10 | 2 | 36 |
| PAPYRO | `papyro-as-consumer.md` | 18 | 7 | 1 | 26 |
| **All** | | **221** | **86** | **22** | **329** |

### Requirements by release

| Release | MUST | SHOULD | COULD | Total |
|---------|------|--------|-------|-------|
| 0.1 | 173 | 27 | 0 | 200 |
| 0.2 | 13 | 31 | 1 | 45 |
| 0.3 | 8 | 7 | 0 | 15 |
| 0.4 | 26 | 11 | 0 | 37 |
| 1.0 | 1 | 3 | 0 | 4 |
| later | 0 | 7 | 21 | 28 |

## The gem at a glance

The benchmark's four layers stand, with the boundaries the area docs drew:

1. **Render core** (RENDER): `Md.render` over commonmarker 2.x with a pinned, numbered dialect, raw HTML off in every
   configuration, one final allowlist sanitizer and one `html_safe` call (RENDER-01 to RENDER-05, RENDER-10,
   RENDER-14). Every surface (preview, public page, feeds, email, content analysis) calls it.
2. **Viewer** (RENDER, VIEWS, THEME): `Md::Viewer`, a `render_in` object with one markup contract (`.md-prose`,
   RENDER-40), progressive enhancement through a Stimulus controller, Mermaid and KaTeX loaded only when used.
3. **Editor** (EDIT, VIEWS, ASSETS): `Md::Editor`, CodeMirror 6 over the real `textarea`, which stays the form value
   and the no-JavaScript fallback (EDIT-01, VIEWS-07). Source mode in 0.1; Live mode when its IME matrix passes
   (EDIT-07).
4. **Agent layer** (AGENT): opt-in tables, exact-string patches stored as pending, attributed suggestions, a review
   view, optional MCP tools (AGENT-01 to AGENT-36).

Cross-cutting: the Rails engine and its integrations (RAILS), JavaScript and CSS delivery (ASSETS), tokens and
customization (THEME), and what the prior art taught (PRIOR).

### Public API in one place

A newcomer learns two names (`markdown_field`, `markdown_view`, DX-13); everything else is optional. Names use the
placeholder `Md`; D-01 replaces it everywhere at once.

| Surface | Names | Requirements |
|---------|-------|--------------|
| Install and tasks | `bundle add md`, `bin/rails generate md:install`, `bin/rails md:doctor`; optional generators `md:theme` (`--full`), `md:suggestions MODEL`; tasks `md:theme:check`, `md:bench`, `md:dialect:diff`, `md:mcp` | DX-01 to DX-06, DX-23, THEME-13, THEME-14, AGENT-01, RENDER-06, RENDER-12, AGENT-31 |
| Forms | `form.markdown_field :body, **options`, `markdown_field_tag(name, value, **options)`; simple_form and Formtastic `as: :markdown` | DX-08, VIEWS-05, VIEWS-06, VIEWS-14, VIEWS-15 |
| Views | `markdown_view(text)`, `Md::Editor`, `Md::Viewer`, `Md::Field`; optional Phlex kit `MarkdownEditor`, `MarkdownView`; `markdown_review record, :body`, `markdown_alternate_link_tag` | DX-09, VIEWS-01, VIEWS-04, VIEWS-08, AGENT-15, AGENT-32 |
| Ruby | `Md.render(text, locale:, …)` returning `Md::Document`; optional `has_markdown :body` (name: D-02) adding `body_document` | DX-10, DX-11, RENDER-01, RAILS-06 |
| Configuration | `Md.configure` in `config/initializers/md.rb`; per-call options `modes:`, `toolbar:`, `uploads:`, `preview:` plus THEME-19's look options, each mapped to one configuration key (C-15) | DX-05, DX-12, THEME-19 |
| Extension | toolbar data and Ruby-defined buttons, DOM events `md:change`, `md:upload`, `md:command`, `md:preview`, `Md::Extension` and `Md::HtmlFilter` with `allow`, a cancellable editor-initialization event for CodeMirror extensions (D-11), `/` menu items (EDIT-24), versioned render hooks, upload URL mapping, storage adapter, icon resolver (budget: C-08, D-11) | DX-17 to DX-20, RENDER-20 to RENDER-23, RENDER-39, RENDER-47, RENDER-49, RAILS-10, THEME-17 |
| Security | one `config.authorize` hook (D-05), sanitizer allowlist additions declared on extensions, `Md::RESERVED_IDS` | RAILS-18, RAILS-21, AGENT-24, PRIOR-16, RENDER-15, RENDER-18 |
| Errors | `Md::ConfigurationError`, `Md::RenderError` (`InputTooLarge`, `NestingTooDeep`, `InvalidEncoding`), `Md::UnsafeAllowlist`, `Md::UncacheableExtension`, `Md::ExtensionError` | DX-22, RENDER-04, RENDER-15, RENDER-22, RENDER-24 |
| Testing | `Md::Testing.assert_renders`, `Md::Testing.run_corpus` | RENDER-25 |
| Agent | `Md::Patch` (`json_schema`, `tool_definition`), `Md::Suggestion.propose`, `Md::Agent.context_for`, `Md::Agent::Principal`, `md_mcp at:` | AGENT-04, AGENT-05, AGENT-25, AGENT-28, AGENT-34 |
| CSS | `--md-*` tokens (prefix: D-01) resolved into private `--_md-*` names, `data-md-theme` presets, `.dark` and `data-theme="dark"`, opt-in `color_scheme: :auto` | THEME-01, THEME-02, THEME-07, THEME-12 |

## Rails integration plan

### Versions and dependencies

| Dependency | Version | Kind | Requirements |
|------------|---------|------|--------------|
| Ruby | 3.3, 3.4, 4.0 (`required_ruby_version >= 3.3`) | runtime | RAILS-01, RAILS-03, D-12 |
| railties, actionpack, actionview | `>= 8.1`; Rails `main` as an allowed failure | runtime (the only Rails gems) | RAILS-01, RAILS-02, RAILS-04 |
| Active Record, Active Storage, Action Text, Action Cable | whatever the app runs | optional, enabled from load hooks | RAILS-04, RAILS-36 |
| commonmarker | `>= 2.10.1` floor; upper bound D-04 | runtime | RENDER-02, RENDER-54, C-16 |
| rails-html-sanitizer | `>= 1.7.2` | runtime | RENDER-54, RENDER area decision 2 |
| `mcp` | 1.0 or later, only when the app adds it | optional | AGENT-28 |
| `image_processing` | app's choice | optional (variants fall back to originals) | RAILS-23 |
| `reverse_markdown` | app's choice, only for the Action Text migration on Rails 8.1 | optional, never in the gemspec | RAILS-15, RAILS area decision 4 |
| Phlex, phlex-rails, ViewComponent | none | not a dependency (D-03); CI covers them | VIEWS-02, VIEWS-03 |
| CodeMirror 6 (`@codemirror/state`, `view`, `language`, `commands`), `@lezer/markdown` with GFM | measured at view 6.43.15, state 6.7.6, @lezer/markdown 1.8.1 | bundled into one gem file (D-08); npm dependencies of the package | ASSETS-02 to ASSETS-04 |
| `@codemirror/merge` | 6.12.3 (agent-layer.md) | optional, 0.4: the review mode of AGENT-22 | AGENT-22 |
| KaTeX | measured at 0.19.1 | vendored, lazy | ASSETS-10, ASSETS-20, RENDER-44 |
| Mermaid | measured at 12.3.0 | vendored Propshaft-safe build, lazy; companion gem per D-10 | ASSETS-11, RENDER-43 |
| Turndown with the GFM plugin | pinned when vendored | vendored, lazy on first HTML paste | EDIT-21, EDIT area decision 6 |
| `@rails/activestorage` | the app's | optional peer, imported lazily | RAILS-17, PRIOR-13 |

### Rails frameworks

| Framework | What the gem does | Requirements | Release |
|-----------|-------------------|--------------|---------|
| Engine and Zeitwerk | `isolate_namespace Md`, own loader, `on_load` hooks only, reload-safe configuration, prefixed helpers that refuse to overwrite, self-mounting routes through the engine proxy | RAILS-29 to RAILS-33 | 0.1 |
| Active Record | any `text` or `string` column; optional macro adding `body_document`; LF normalization with `normalizes`; storage adapter with column and association built-ins (Papyro's `ActionText::Markdown`) and a preload scope | RAILS-05 to RAILS-11, DX-07, DX-11 | 0.1 |
| Caching | `Rails.cache` keyed by digest, locale, dialect, renderer version and configuration fingerprint; never the record's cache key | RAILS-08, RENDER-30, RENDER-31, C-01 | 0.1 |
| Instrumentation | `render.md` event (union of both payloads), agent events | RAILS-09, RENDER-32, AGENT-27 | 0.1, 0.4 |
| Action Text | coexists, never patched; migration task with dry-run report, `to_markdown` or `reverse_markdown`, image attachments moved to stable upload URLs | RAILS-13 to RAILS-16 | 0.1 (coexistence), 0.2 (migration) |
| Active Storage | authorized direct uploads on every service, stable app-relative URLs, `:read` authorization for private records, attachment and purge, orphan job, variants from configuration only | RAILS-17 to RAILS-23, PRIOR-24 | 0.2 (0.1 ships the upload seam, DX-19) |
| Turbo and Stimulus | Drive cache, `disconnect()` cleanup, morph refreshes that never clobber a dirty editor, idempotent viewer enhancement, frames and streams | RAILS-24 to RAILS-28, PRIOR-21, RENDER-45 | 0.1 |
| I18n | `md.` keys in English and Spanish rendered server-side into data attributes; explicit content `locale:` | RAILS-34, RAILS-35, THEME-18, EDIT-41, PRIOR-31 | 0.1 |
| Action Cable | optional; morph refreshes and live suggestion updates documented, request-only fallback | RAILS-36, AGENT-23 | 0.4 (AGENT-23 later) |

### JavaScript and CSS delivery

| Setup | JavaScript | CSS | Release |
|-------|-----------|-----|---------|
| importmap + Propshaft (Rails default, Papyro) | engine pins through `config.importmap.paths`; one prebuilt CodeMirror file plus shim pins (C-11); Mermaid and KaTeX by `import(url)` from `asset_path` | prebuilt plain CSS on custom properties with `stylesheet_link_tag` | 0.1 (lazy viewer extras 0.3) |
| jsbundling (esbuild, Rollup, Bun, webpack) | npm package, or generator-managed copies until it is published (D-09); one `@codemirror/state` | plain CSS, or the npm package's `md.css` with cssbundling | 0.1 (esbuild smoke; cssbundling `md.css` with the npm package, D-09) |
| Sprockets 4 | engine declares every file in `config.assets.precompile` | same plain CSS; KaTeX font URLs verified | 0.2 (KaTeX in 0.3) |
| tailwindcss-rails 4.3+ | as above | optional engine entry `app/assets/tailwind/md/engine.css`, `@import … layer(components)` | 0.1 (ASSETS-19; THEME-06's Tailwind entry) |
| Vite Ruby, Shakapacker | npm package and an install snippet each | npm `md.css` | snippets 0.2, Vite Ruby smoke 0.3 (ASSETS-06, with ASSETS-10; needs the npm package, D-09) |
| Strict CSP | `EditorView.cspNonce` from `csp_meta_tag`; `katex.render` on nodes; no inline handlers, styles or `javascript:` URLs; diagrams need `style-src-attr 'unsafe-inline'`, image mode or server SVG | no `style` attributes in output (RENDER-16) | 0.1 editor, 0.3 diagrams and math |

Budgets: editor at most 110 KiB gzip and viewer controller at most 10 KiB (ASSETS-08), re-measured with the
re-exports of D-08 before they are fixed.

### View layers, forms and admin frameworks

| Layer | How it renders | Requirements | Release |
|-------|----------------|--------------|---------|
| ERB | `form.markdown_field`, `markdown_field_tag`, `markdown_view` | DX-08, DX-09, VIEWS-05, VIEWS-06 | 0.1 |
| Phlex | `render Md::Editor.new(field)` and `render Md::Viewer.new(document)` through `render_in`; the optional kit adds `MarkdownEditor(field:)` | VIEWS-01, VIEWS-02, VIEWS-04, PAPYRO-17 | 0.1 (kit 0.2) |
| ViewComponent | the same `render_in` objects | VIEWS-02 | 0.1 |
| simple_form, Formtastic (ActiveAdmin 3 and 4) | `as: :markdown` inputs building `Md::Field` | VIEWS-14, VIEWS-15 | 0.2 |
| Avo | gem-prefixed field type | VIEWS-17 | 0.2 |
| Administrate, Madmin, RailsAdmin | fields (COULD) and a docs recipe | VIEWS-18, VIEWS-19 | later |

### Render pipeline

`Md.render` resolves the locale default and the cache, then runs a pure core: input bounds (RENDER-04), commonmarker
parse with the dialect's pinned options (RENDER-02), built-in AST passes (slugs, typography, metadata), app
`Md::Extension`s through `context.replace_text` (RENDER-20), HTML rendering with highlighter classes (RENDER-41),
built-in and app `Md::HtmlFilter`s (RENDER-23, RENDER-29), the final sanitizer and link policy (RENDER-14,
RENDER-17), and the `Md::Document` with its metadata (RENDER-28, RENDER-37, RENDER-38). Dialect v1 ships in 0.1 and
v2 (Mermaid and math fences) in 0.3; a dialect never changes once released (RENDER-07). The hostile-input corpus and
the parser-abuse budget run on every pull request (RENDER-51, RENDER-52).

### Security model

- One authorization hook (D-05) guards every gem endpoint: preview, upload, upload reads, agent reads, proposals,
  decisions and direct writes. Every action fails closed unless the hook allows it; the only allowance the generator
  writes is `:preview` (D-06), so a fresh install exposes no upload, private upload read or agent action.
- Raw HTML is off in every dialect, variant and configuration in 0.x (RENDER-10); the sanitizer is the last stage and
  extensions can widen the allowlist only within the never-allow list checked at boot (RENDER-15).
- Uploads never use the unauthenticated stock direct-upload route or permanent signed-id URLs (RAILS-18, RAILS-19).
- Agent text is neutralised before review: no outbound requests, links without `href`, visible invisible characters,
  bidi and tag characters refused (AGENT-16 to AGENT-19).
- Strict CSP with nonces works for the editor and math (ASSETS-13 to ASSETS-15).

### Papyro adoption path

The PAPYRO doc's migration steps, mapped to gem releases; no step rewrites stored markdown (PAPYRO-03).

| Step | Gem release | Papyro change | Requirements |
|------|-------------|---------------|--------------|
| 0 | none | one sanitized render entry point; `to_html` delegates (#352) | PAPYRO-01 |
| 1 | none | baseline corpus, checksums, heading ids and word counts | PAPYRO-02, PAPYRO-04 |
| 2 | 0.1 | if D-02 keeps `has_markdown` for the gem, rename Papyro's on-load macro first (host and engine call sites, no data); then the render core behind the facade and a switch; image and slugger extensions | RAILS-31 (D-02), PAPYRO-05, PAPYRO-06, PAPYRO-09 to PAPYRO-13 |
| 3 | 0.1 | public page and Studio preview render the gem viewer | PAPYRO-17, PAPYRO-19, PAPYRO-21 |
| 4 | 0.1 | Studio editor on the real `article[body]` field; Papyro upload adapter; House deleted | PAPYRO-07, PAPYRO-08, PAPYRO-14, PAPYRO-15, PAPYRO-18, PAPYRO-20, PAPYRO-22, PAPYRO-23 |
| 5 | 0.4 | `Translate` writes a pending suggestion; hunk review in Studio | PAPYRO-16, PAPYRO-24 |
| 6 | 1.0 at the latest | facade, `lib/markdown_renderer*`, Redcarpet and Rouge removed | PAPYRO-02 corpus check stays green |

Papyro keeps its own preview and upload controllers (PAPYRO area decision 5, PAPYRO-08, PAPYRO-16), so 0.1
needs the upload seam (DX-19) and the render hooks, not the gem's endpoints. During 0.x the gem repository joins
Papyro's flow workspace as a companion like `papyro_studio` (PAPYRO-25, D-13).

## Conflicts between the area docs

Each row names the requirements involved and how the synthesis settles them. "Resolved" rows are applied by the
implementation epic; rows marked with a decision wait for the sign-off.

| # | Requirements | Conflict | Resolution |
|---|--------------|----------|------------|
| C-01 | RAILS-08, RENDER-31, DX-14, DX-11, PAPYRO-12 | RAILS-08 caches every render through `Rails.cache`; RENDER-31 caches only when `cache:` is passed. | Resolved: `Md.render` caches only with `cache:` (RENDER-31, so the core stays pure). The helpers and readers app code uses (`markdown_view`, the macro's `body_document`, `Md::Viewer`) pass `config.cache_store`, which defaults to `Rails.cache`; RAILS-08's key is RENDER-30's. The preview path never caches. DX-14's "cache hit on the second render" holds through the helper. |
| C-02 | EDIT-30, EDIT-31, RENDER-35, RENDER-37, PAPYRO-11 | EDIT-30 counts with `Intl.Segmenter` over text without markers, link targets or image URLs; RENDER-35 says "Unicode words of the plain text" without a rule, is only a SHOULD, and RENDER-37's plain text keeps image alt text. | Resolved: RENDER owns one rule, used on both sides: UAX #29 word segments that contain a letter or a digit, over `Document#plain_text` as RENDER-37 defines it (alt text counted, URLs and markers not). RENDER-35 ships in 0.1 with the MUSTs that depend on it. A spike at the start of 0.1 picks the Ruby side (a UAX #29 word-break implementation); if none matches `Intl.Segmenter` on EDIT-31's corpus, both sides implement one simpler rule the spike defines identically. The corpus of EDIT-31 is the judge. |
| C-03 | AGENT-08, AGENT-03, RAILS-07, PRIOR-01, PAPYRO-03 | AGENT-08 assumes, unverified, that browsers submit textarea line breaks as CRLF. | Resolved: the HTML standard converts every lone LF or CR to CRLF when it builds URL-encoded and multipart form data, while the textarea's API value is LF (sources cited in RAILS findings), so AGENT-08's assumption holds. Stored text is LF only where a normalizer runs: the macro's `normalizes` (RAILS-07), the README line PRIOR-01 ships for attributes without the macro, and, with the association adapter (RAILS-10), the record that holds the text, which the adapter docs name. DX-07's no-model-change path keeps CRLF; AGENT-01 therefore requires the macro and AGENT-03 hashes LF-normalised text regardless. RAILS-07's acceptance (CRLF in, LF stored) is the verification; AGENT-08's acceptance runs against a record saved through a real form submit, and PAPYRO-03's load-and-save check runs with Papyro's normalizer on `ActionText::Markdown#content` and `article_translations.content`. |
| C-04 | DX-11, DX-13, RAILS-06, RAILS-31, AGENT-01, AGENT-15, AGENT-32 | RAILS-31 puts the gem's prefix on every method the gem adds to `ActiveRecord::Base`, `FormBuilder` and the helpers, and notes that Papyro defines `has_markdown` on every model; DX and AGENT use `has_markdown` and unprefixed `markdown_*` helpers. | Needs the maintainer: D-02 (macro name, what RAILS-31's prefix means, when Papyro renames). |
| C-05 | VIEWS-03, VIEWS-04, PAPYRO-17, AGENT-15, DX-12 | The benchmark's "render with Phlex internally" and PAPYRO-17's "ship as Phlex components" against VIEWS-03 (no Phlex runtime dependency). | Proposed: Phlex views render `Md::Editor` and `Md::Viewer` with `render` because they respond to `render_in`, which meets PAPYRO-17's acceptance; AGENT-15's "Phlex component" is part of the optional kit (VIEWS-04). Confirm in D-03. |
| C-06 | DX-20, RENDER-20 to RENDER-23, PRIOR-17, PAPYRO-09 | DX-20 adds syntax with `config.render.passes << Pass` (`call(node)`) and `config.sanitizer.allow`; RENDER defines `Md::Extension` and `Md::HtmlFilter` classes with `version` and `allow`, registered with `config.extensions.use`. | Resolved: RENDER's mechanism, because it carries the cache-key version (RENDER-22) and keeps allowlist additions on the extension that needs them (RENDER-21). DX-20's acceptance runs with it: a ten-line `Md::Extension` in the docs, and an attribute added without `allow` is stripped. RENDER-23 ships in 0.1 because Papyro's lightbox needs it (PAPYRO-09). |
| C-07 | DX-21, RENDER-03 | DX-21 lets an app replace the whole renderer; RENDER-03 requires the gem's sanitizer to be the last stage before `html_safe`. | Needs the maintainer: D-07. |
| C-08 | DX notes (seven extension points), DX-18, EDIT-15, EDIT-24, EDIT-42, THEME-17, RENDER-39, RENDER-47, RENDER-49, RAILS-10, PRIOR-12, PRIOR-30, PAPYRO-10 | DX caps the extension points at seven and DX-18 rules out a JavaScript plugin registry; the other areas add an icon resolver, shortcut rebinding, `/` menu items, completion providers, versioned render hooks, a storage adapter and a JavaScript registration call for CodeMirror extensions (PRIOR-12). | Needs the maintainer: D-11 proposes the recount. |
| C-09 | RAILS-18, RAILS-21, AGENT-24, PRIOR-16, DX-15, PAPYRO-16 | Three hook shapes: uploads `(user, record, attribute, action)`, agents `(principal, record, action)`, and a preview hook; DX-15's preview endpoint has none, and RAILS' `:read` (an upload) and AGENT's `:read` (a document) collide. | Needs the maintainer: D-05 (one hook) and D-06 (preview default). |
| C-10 | DX-16, DX-01, DX-14, RAILS-18 | DX-16 turns uploads on when Active Storage is present; RAILS-18 refuses every upload until an authorization hook exists. | Resolved: the editor shows the upload control only when Active Storage is loaded and the hook answers for `:upload`; from 0.2 the generator prints the hook as the step that enables uploads (DX-03); in 0.1 it names the DX-19 seam, so DX-01's two commands still give a working editor and viewer without uploads. |
| C-11 | ASSETS-02, PRIOR-09, PRIOR-12, PAPYRO-18 | ASSETS-02 ships CodeMirror as one prebuilt file with re-exports and "one CodeMirror pin"; PRIOR-09 wants `@codemirror/state`, `view` and `language`, and PAPYRO-18 `state` and `view`, as pins that third-party packs import by bare specifier. | Resolved: one prebuilt file, plus shim pins named `@codemirror/state`, `@codemirror/view`, `@codemirror/language` and `@codemirror/commands` that re-export from it. Extensions pinned from npm (PRIOR-12) resolve to the single copy, and ASSETS-02's acceptance reads "one CodeMirror build plus its shim pins". Confirm the delivery shape in D-08. |
| C-12 | PAPYRO-10, RENDER-01, RENDER-26, RENDER-27, RENDER-30 | PAPYRO-10 needs a slugger hook for Papyro's legacy anchors; RENDER makes slug style configuration only (`:unicode`, `:ascii`). | Resolved: `config.slug` also accepts a callable registered with `version:` like RENDER-39's hooks, so it joins the fingerprint (RENDER-30). RENDER-27 ships in 0.1 with it. Which slugs Papyro keeps is D-14. |
| C-13 | THEME-07, PRIOR-22, DX-14 | PRIOR-22 follows `prefers-color-scheme` by default; THEME-07 follows it only with `color_scheme: :auto`. | Resolved: THEME-07, the theming owner; an app without a dark mode never gets a dark editor. PRIOR-22's acceptance runs with `color_scheme: :auto` and keeps its check that an explicit app class wins over the OS setting. |
| C-14 | RAILS-34, THEME-18, EDIT-41, PRIOR-31 | Four requirements for one i18n mechanism. | Resolved: one implementation; RAILS-34 owns the mechanism (server-side keys under `md.` in data attributes), THEME-18 the key-rename policy, EDIT-41 and PRIOR-31 the coverage checks. |
| C-15 | DX-12, THEME-12, THEME-16, THEME-19, PRIOR-07, ASSETS-12, EDIT-24 | Option names drift between docs (`config.editor.*`, `it.mermaid_url`, `_1.theme`, `_1.icons`), THEME-19 adds per-field options outside DX-12's four, and "preset" means two things (PRIOR-07's option layer against THEME-12's look). | Resolved: DX owns every name. DX-12's vocabulary grows by THEME-19's look options and EDIT's switches, each mapped to one grouped key (`config.editor`, `config.viewer`, `config.render`, `config.uploads`, `config.preview`, `config.theme`); the first DX item of the implementation epic publishes the options table that DX-12's test iterates. The option layer of PRIOR-07 and THEME-16 is called a field preset, the look of THEME-12 a theme. |
| C-16 | RENDER-02, RENDER-07, RENDER-54 | commonmarker has a floor (2.10.1) and no ceiling, so a host's `bundle update` can change a dialect RENDER-07 calls frozen; the cache key includes the commonmarker version, so stale HTML is not the risk, changed markup is. | Needs the maintainer: D-04. |
| C-17 | VIEWS-07 | VIEWS-07 promises a fresh value on every submit, but `HTMLFormElement.submit()` from a script fires no `submit` event and skips constraint validation. | Resolved: freshness is guaranteed when the entry list is built, not at the `submit` event. The editor listens for the form's `formdata` event, which fires for user submits, `requestSubmit()`, `HTMLFormElement.submit()` and `new FormData(form)` (Turbo's path), and writes its text with `event.formData.set(name, text)`, so submitted params are never stale on any path. Constraint validation runs before `submit` and `formdata` (and `submit()` skips it), so for VIEWS-12's required check the editor also flushes into the textarea on capture-phase `click` of the form's submitters and on Enter-driven implicit submission; focus loss is not relied on (Safari does not focus a clicked button). VIEWS-07's acceptance adds a `requestSubmit()` and a `form.submit()` case, each asserting the typed text in the params. |
| C-18 | AGENT-01 | "Boot raises an error" for a model without `lock_version`, but models load lazily in development, and the generator runs once per model. | Resolved: the check runs when the model class declares `suggestions: true` (first load), not at boot; eager-loaded environments see it at boot. `md:suggestions` rerun for a second model adds that model's `lock_version` and skips the tables that exist. |
| C-19 | PRIOR-25, RENDER-08 | PRIOR-25 inserts video and audio as links the viewer upgrades to players; dialect v1 has no media syntax and the allowlist has no `video` or `audio`. | Resolved: stays `later`; it needs a dialect addition and allowlist entries in a future dialect, owned by RENDER. |
| C-20 | ASSETS area decision 3, RENDER-09, RENDER-42, THEME-11 | Dialect v2 puts Mermaid in the core dialect, while ASSETS proposes delivering Mermaid in a companion gem. | Proposed: the core dialect marks Mermaid fences (RENDER-09); the companion gem supplies the client build. Without it, a fence renders as escaped source with RENDER-43's note. Confirm in D-10. |
| C-21 | PRIOR-17, RENDER-03, RENDER-10, DX-21 | PRIOR-17 asks for an explicit, documented opt-out that turns sanitizing off, and its acceptance scrubs raw HTML "unless the opt-out is set"; RENDER-10 forbids any raw-HTML setting in 0.x and RENDER-03 keeps the sanitizer the last stage in every configuration. | Resolved: RENDER, the security owner (RENDER area decision 1). 0.x has no sanitize opt-out; PRIOR-17's filter-hook half is met by RENDER-20 to RENDER-23 and its acceptance reads "raw HTML is scrubbed in every configuration". A trusted-content path, if one is ever needed, is RENDER's separate raw-HTML profile or DX-21's replacement renderer, which still passes the final sanitizer (D-07). |
| C-22 | PAPYRO-15, RENDER-01, RENDER-05, DX-10, RAILS-35 | PAPYRO-15 says gem APIs never read `I18n.locale` and its DX notes want a configured static fallback; RENDER-01, DX-10 and RAILS-35 default an omitted `locale:` to `I18n.locale`. | Resolved: the `I18n.locale` default stays for newcomers, resolved only in `Md.render` outside the pure core (RENDER-05) with RAILS-35's README warning. PAPYRO-15 holds because Papyro always passes the content locale from Mobility, never the request's UI locale; Papyro adds a test that every `Md.render` and `markdown_view` call under `app/` of the host and of the `papyro_studio` engine passes `locale:`. PAPYRO-15's acceptance is unchanged. A configurable fallback is a later DX addition. |
| C-23 | PRIOR-24, RAILS-17, RAILS-18, RAILS-19, RAILS-32 | PRIOR-24 builds the direct-upload and blob URLs from the app's Active Storage routes; RAILS-18 forbids the stock `rails_direct_uploads_url` and RAILS-19 stores a stable gem route, never a stock blob URL. | Resolved: RAILS owns the endpoints and the stored URL. PRIOR-24's lesson (no hard-coded path) is met by building both URLs through the engine's route proxy (RAILS-32); its placeholder, cancelable accept event, progress and error parts stand. Its acceptance becomes: in an app that mounts the engine at a custom path and uses a custom Active Storage route prefix, the inserted URL is the gem's stable upload URL and it serves the file. |
| C-24 | DX-27, ASSETS-04, ASSETS-05 | DX-27 makes an upgrade `bundle update` (plus the npm package) and lets the gem copy nothing into the app except the initializer and ejected files; D-09's fallback copies the controllers into jsbundling apps, so their upgrade also needs a generator rerun. | Needs the maintainer: D-09. |
| C-25 | DX-11, RAILS-06, AGENT-01, AGENT-03, AGENT-32 | DX-11's macro adds `body_document` "and nothing else" with no writing callback, and its acceptance fails on any other method; AGENT-01 adds `suggestions: true` to that macro, AGENT-32 gives every `has_markdown` model `to_markdown`, and AGENT-03 stores a revision for every text saved. | Resolved: DX-11 describes the core macro and its acceptance runs without the agent layer. `suggestions:` and `to_markdown` exist only after `md:suggestions` and only on models declaring `suggestions: true`; an agent-layer test lists exactly what they add. AGENT-03's revision rows are written by the gem's write APIs (propose, accept, apply) and when text is handed to an agent, never by a save callback, so a host save through its own operation (PAPYRO-14) writes no gem row. |

Duplicates that are one piece of work, implemented once and traced from every ID: DX-01 and PRIOR-03; DX-08 and
VIEWS-05; DX-10 and RENDER-01; DX-11 and RAILS-06; DX-17, PRIOR-08 and THEME-16; DX-26 and PRIOR-34; RAILS-09 and
RENDER-32; RAILS-17 and PRIOR-24 (URLs per C-23); RAILS-24 to RAILS-27, PRIOR-21 and RENDER-45; ASSETS-05 and PRIOR-10;
EDIT-10, PRIOR-02 and PRIOR-28; EDIT-12 and PRIOR-27; EDIT-14 and PRIOR-36; RAILS-07 and PRIOR-01.

## Release plan

Every MUST has a release. The order is 0.1, then 0.2 to 0.4 in the proposed order (0.3 and 0.4 depend only on 0.1
and 0.2 and may swap), then 1.0. Within each release DX comes first, then the Rails integration areas, the writer and
reader experience, customization, the agent layer, the prior-art checks and Papyro.

### 0.1: render core, viewer and Source editor

Goal: the quick start works, and Papyro can run migration steps 2 to 4. Exit criteria: the DX-01 and DX-31 CI apps
(importmap with Propshaft, and jsbundling with esbuild) are green; the hostile corpus and parser-abuse jobs pass
(RENDER-51, RENDER-52); the EDIT-34 IME matrix and the EDIT-38 screen reader script are recorded; Papyro's corpus diff
is classified (PAPYRO-02). Before 0.1, the maintainer settles D-01, D-02, D-04, D-05, D-06, D-08, D-09, D-11 and the
accent token name (THEME area decision 7), because changing them later costs a deprecation cycle.

0.1 carries most of the MUSTs: they are the minimum for a professional, safe editor, and Papyro needs all three
layers to leave Redcarpet and House. The implementation epic orders them in three internal milestones that mirror
Papyro's steps (render core, viewer, editor) and may publish a prerelease after each (`0.1.0.pre1` and so on); the
DX-01 quick start is the gate of the last one.

| Area | Requirements |
|------|--------------|
| DX | MUST: DX-01 to DX-04, DX-07 to DX-10, DX-12 to DX-15, DX-18 to DX-20, DX-22, DX-23, DX-26, DX-28, DX-31; SHOULD: DX-05, DX-11, DX-17, DX-25, DX-30 |
| RAILS | MUST: RAILS-01, RAILS-03 to RAILS-05, RAILS-07, RAILS-08, RAILS-10, RAILS-11, RAILS-13, RAILS-24 to RAILS-27, RAILS-29 to RAILS-31, RAILS-33 to RAILS-35; SHOULD: RAILS-06, RAILS-09, RAILS-28, RAILS-32 |
| ASSETS | MUST: ASSETS-01 to ASSETS-05, ASSETS-08, ASSETS-13, ASSETS-15, ASSETS-18; SHOULD: ASSETS-19 |
| VIEWS | MUST: VIEWS-01 to VIEWS-03, VIEWS-05 to VIEWS-12, VIEWS-20, VIEWS-22 |
| EDIT | MUST: EDIT-01 to EDIT-05, EDIT-09 to EDIT-15, EDIT-17 to EDIT-20, EDIT-25 to EDIT-31, EDIT-33 to EDIT-38, EDIT-40, EDIT-41 |
| RENDER | MUST: RENDER-01 to RENDER-05, RENDER-07, RENDER-08, RENDER-10, RENDER-14 to RENDER-22, RENDER-26, RENDER-28 to RENDER-30, RENDER-37, RENDER-38, RENDER-40, RENDER-41, RENDER-45, RENDER-46, RENDER-51, RENDER-52, RENDER-54; SHOULD: RENDER-06, RENDER-23, RENDER-24, RENDER-27, RENDER-31, RENDER-32, RENDER-35 |
| THEME | MUST: THEME-01 to THEME-04, THEME-06, THEME-07, THEME-09, THEME-10, THEME-15 to THEME-18 |
| PRIOR | MUST: PRIOR-01 to PRIOR-06, PRIOR-09 to PRIOR-11, PRIOR-14 to PRIOR-18, PRIOR-21 to PRIOR-23, PRIOR-27, PRIOR-31, PRIOR-34 to PRIOR-36; SHOULD: PRIOR-07, PRIOR-08, PRIOR-19, PRIOR-28 |
| PAPYRO | MUST: PAPYRO-01 to PAPYRO-04, PAPYRO-06 to PAPYRO-11, PAPYRO-14, PAPYRO-15, PAPYRO-17 to PAPYRO-21; SHOULD: PAPYRO-05, PAPYRO-12, PAPYRO-13, PAPYRO-22, PAPYRO-23, PAPYRO-25 |

### 0.2: uploads, migration, form libraries and theming

Goal: newcomers get uploads out of the box and apps on Action Text can move. Contents: the gem's upload endpoint and its
authorization (RAILS-17 to RAILS-23), the Action Text migration task, Sprockets, the simple_form,
Formtastic and Avo adapters, the theme eject generator and theme presets (THEME-12), HTML paste, tables and the `/`
menu, the static variant, and the upgrade CI from the previous release (DX-27). The simple_form, Formtastic and admin
cases of VIEWS-08, VIEWS-11 and VIEWS-20 run from this release, with their adapters.

| Area | Requirements |
|------|--------------|
| DX | MUST: DX-27; SHOULD: DX-16, DX-24 |
| RAILS | MUST: RAILS-14 to RAILS-21; SHOULD: RAILS-02, RAILS-22, RAILS-23 |
| ASSETS | MUST: ASSETS-07; SHOULD: ASSETS-09 |
| VIEWS | SHOULD: VIEWS-13 to VIEWS-17, VIEWS-21, VIEWS-23; COULD: VIEWS-04 |
| EDIT | SHOULD: EDIT-08, EDIT-21 to EDIT-24 |
| RENDER | SHOULD: RENDER-25, RENDER-33, RENDER-36, RENDER-47, RENDER-53 |
| THEME | MUST: THEME-13, THEME-14; SHOULD: THEME-05, THEME-08, THEME-12, THEME-19, THEME-21 |
| PRIOR | MUST: PRIOR-24; SHOULD: PRIOR-12, PRIOR-13, PRIOR-29 |

### 0.3: dialect v2, diagrams and math

Goal: Mermaid and math fences, delivered lazily and safely in every pipeline. Contents: dialect v2, lazy Mermaid
and KaTeX, the Propshaft-safe Mermaid build (in the companion gem of D-10), strict-mode initialization, CSP guidance
and image mode, themed diagrams.

| Area | Requirements |
|------|--------------|
| ASSETS | MUST: ASSETS-10, ASSETS-11, ASSETS-14, ASSETS-17, ASSETS-20; SHOULD: ASSETS-06, ASSETS-12, ASSETS-16 |
| RENDER | MUST: RENDER-42 to RENDER-44; SHOULD: RENDER-09, RENDER-12, RENDER-48 |
| THEME | SHOULD: THEME-11 |

### 0.4: agent layer

Goal: pending, attributed suggestions with hunk review, and optional MCP tools. Papyro migration step 5 follows.

| Area | Requirements |
|------|--------------|
| DX | SHOULD: DX-06 |
| RAILS | SHOULD: RAILS-36 |
| AGENT | MUST: AGENT-01 to AGENT-08, AGENT-10 to AGENT-13, AGENT-15 to AGENT-20, AGENT-24 to AGENT-27, AGENT-33, AGENT-34, AGENT-36; SHOULD: AGENT-09, AGENT-14, AGENT-21, AGENT-22, AGENT-28 to AGENT-30, AGENT-32 |
| PAPYRO | MUST: PAPYRO-16; SHOULD: PAPYRO-24 |

### 1.0: stable API

Goal: a public API Papyro and a second, non-Papyro app run on (the benchmark's and DX area decision 8's gate).
Contents: the docs site and sandbox, upgrade guides, the full browser matrix as required checks
(PRIOR-32; the Chromium job runs from 0.1), and the 1.0 reviews the open decisions defer (Papyro anchors in D-14,
budgets in ASSETS area decision 6, the sanitizer engine spike in PRIOR area decision 3).

| Area | Requirements |
|------|--------------|
| DX | SHOULD: DX-29, DX-32 |
| PRIOR | MUST: PRIOR-32; SHOULD: PRIOR-33 |

### Later

SHOULD and COULD items with no release yet. The implementation epic may pull any of them into a 0.x release; none
blocks a MUST.

| Area | Requirements |
|------|--------------|
| DX | SHOULD: DX-21; COULD: DX-33, DX-34 |
| RAILS | COULD: RAILS-12 |
| VIEWS | COULD: VIEWS-18, VIEWS-19 |
| EDIT | SHOULD: EDIT-06, EDIT-07, EDIT-32, EDIT-39; COULD: EDIT-16, EDIT-42, EDIT-43 |
| RENDER | COULD: RENDER-11, RENDER-13, RENDER-34, RENDER-39, RENDER-49, RENDER-50 |
| THEME | COULD: THEME-20 |
| AGENT | COULD: AGENT-23, AGENT-31, AGENT-35 |
| PRIOR | SHOULD: PRIOR-20, PRIOR-25; COULD: PRIOR-26, PRIOR-30 |
| PAPYRO | COULD: PAPYRO-26 |

## Open decisions for the maintainer

The sign-off (`DECISIONS.md`) answers these. D-01 to D-15 cross areas or settle a conflict above; the area
decisions after them were raised by one doc each, and the synthesis view says whether it agrees.

### Decisions that cross areas

- **D-01 Gem name and namespace.** One name for the gem, the npm package, the Ruby constant, the generator namespace,
  the CSS token prefix and the Avo field type (DX, THEME, VIEWS, ASSETS). Recommendation: DX's criterion: free on
  RubyGems and npm, usable unchanged in all four Ruby and JavaScript places, short enough that `Name.render` reads
  like `Md.render`; the token prefix is that name in two to five letters (THEME). Decide before 0.1.
- **D-02 Model macro name** (C-04). Options: the gem ships `has_markdown` and Papyro renames its own macro, or the gem
  uses a name derived from the gem name and leaves `has_markdown` to Papyro. Recommendation: the gem ships
  `has_markdown`. It mirrors `has_rich_text`, it is the name DX-13's quick start and AGENT-01 already use, and a derived
  name costs every newcomer a less guessable macro. Papyro pays first: it defines `has_markdown` on every model through
  `ActiveSupport.on_load :active_record`, so it renames that macro (code only, no data; host and engine call sites in
  one change) before the gem enters its bundle at migration step 2. RAILS-31 is read with this decision: the gem's
  prefix is the `markdown` family DX names (`has_markdown`, `markdown_field`, `markdown_field_tag`, `markdown_view`,
  `markdown_review`, `markdown_alternate_link_tag`), the boot refusal stays, and its acceptance becomes "the gem loads
  into Papyro after the rename with `markdown_area` untouched, and a dummy app that predefines `has_markdown` gets the
  boot error". Decide before 0.1.
- **D-03 Phlex as a runtime dependency** (C-05). Recommendation: no, as VIEWS-03 says. The `render_in` objects reach
  Phlex, ERB and ViewComponent alike; the optional kit (VIEWS-04, 0.2) gives Phlex apps method sugar. This narrows the
  benchmark's design rule 1 from "render with Phlex internally" to "Phlex-friendly, Phlex-free".
- **D-04 commonmarker upper bound** (C-16). Options: no ceiling (the area docs today), `< 3`, or the next minor
  (`~> 2.10.1`, so 2.10.x patches only). Recommendation: cap at the next minor and widen it in a gem patch release
  once a scheduled CI job has run the frozen fixtures of every dialect against the new commonmarker minor; a minor
  that changes markup is adopted only with a new dialect number (RENDER-07). The cost is a gem release per commonmarker
  minor, a security fix in a new minor waiting for that release, and a Bundler conflict in apps where another gem
  needs a newer commonmarker minor; the gain is that RENDER-07's freeze is true for
  hosts, not only for the gem's own CI.
- **D-05 One authorization hook** (C-09). Recommendation: one `config.authorize` callable taking the actor, the record,
  the action and an optional attribute, with the actions `:preview`, `:upload`, `:read_upload`, `:read`, `:propose`,
  `:withdraw`, `:apply` and `:review`. It fails closed for every action except `:preview`, whose default is D-06. The
  actor is always an `Md::Agent::Principal`-style object the app builds (AGENT-25); for a signed-in person its `record`
  is the user, so upload and agent decisions share one Pundit mapping. One hook is one thing a newcomer configures and
  one Pundit mapping for Papyro (PAPYRO-16); RAILS-21's `:read` becomes `:read_upload` so it does not collide with
  AGENT-24's document read. The gem's controllers get the actor from a generated `config.actor` callable that runs in
  controller context and returns the app's Principal, or `nil` when signed out (RAILS-21's signed-out `:read`).
- **D-06 Preview endpoint default** (C-09, DX-15, PRIOR-16). Recommendation: PRIOR's default, scoped to `:preview`. The
  generator writes D-05's hook as a branch on the action: `:preview` allows Rails 8's `authenticated?` or a
  `current_user` helper when the app has one, otherwise `true` with a warning comment; every other action returns
  `false` with a comment naming the step that enables it (uploads per C-10, agent actions per AGENT-24). The preview
  endpoint always sits behind CSRF and `rate_limit` (DX-15). A fresh app keeps a working preview (DX-01), the CPU-bound
  endpoint is never open and unlimited, and no generated line authorizes an upload, an upload read or an agent action.
- **D-07 Replacing the renderer** (C-07, DX-21). Recommendation: keep DX-21, but run the gem's final sanitizer over the
  replacement's HTML so RENDER-03 holds, and schedule it `later` (after 1.0): no area needs it before, and it is the
  extension point the budget of D-11 can spare.
- **D-08 CodeMirror delivery under importmap** (C-11, ASSETS area decision 2). Recommendation: one prebuilt file plus
  shim pins for the four core packages. The lean build measured 100.5 KiB gzip without the re-exports, the smallest
  option measured, and it keeps third-party packs on one copy.
- **D-09 npm package in 0.1** (C-24, ASSETS area decision 1). Recommendation: both delivery channels from one release
  workflow (ASSETS-05, PRIOR-10), with the npm package published from 0.1, because DX-27's upgrade promise holds only
  with it. If npm publishing is not ready for 0.1, ship chadcn's generator-copy approach for jsbundling, switch without
  changing DOM or identifiers no later than 0.2 (the release DX-27 ships in), and while copies are in use DX-27's text
  and CI job read "plus `bin/rails generate md:install` for jsbundling apps with managed copies", with the doctor
  printing that command on a version mismatch (ASSETS-05). When 0.1 shipped copies, the jsbundling leg of DX-27's CI job
  starts with the 0.2 to 0.3 upgrade.
- **D-10 Mermaid in a companion gem** (C-20, ASSETS area decision 3). Recommendation: yes (placeholder `md-mermaid`),
  registering its vendored build with the core; the core keeps the dialect, the strict initialization contract
  (RENDER-43) and the fallback. Mermaid is 108 files and 5.3 MB on disk and upgrades on its own schedule.
- **D-11 Extension budget** (C-08). Recommendation: recount DX's ceiling as eight mechanisms: toolbar, shortcut and `/`
  menu data with Ruby-defined items (DX-17, EDIT-15, EDIT-24, THEME-16); DOM events (DX-18); render extensions and HTML
  filters with `allow` (RENDER-20 to RENDER-23, replacing DX-20's passes); versioned render hooks (slug, image
  dimensions, image URL rewriter, static renderers); the upload URL mapping (DX-19); the storage adapter (RAILS-10); the
  icon resolver (THEME-17); and the renderer replacement (DX-21, later). Completion providers (EDIT-42, PRIOR-30) reuse
  the `/` menu mechanism and the authorization hook is a security setting, so neither counts. PRIOR-12's "documented
  hook" would be a JavaScript registry, which DX-18 rules out; it ships as one more DOM event (a cancellable
  initialization event whose `detail` carries the CodeMirror extension list the app's Stimulus controller appends to,
  named by DX per C-15), so it adds an event, not a ninth mechanism. A ninth needs a DX table entry that justifies it.
- **D-12 Version floor** (RAILS area decision 1). Recommendation: Rails 8.1+ on Ruby 3.3+; both older Rails series
  lose security support before 0.1 ships.
- **D-13 Repository and workspace** (PAPYRO-25, PAPYRO area decision 7, PRIOR area decision 9). Recommendation: a
  companion repository in Papyro's flow workspace during 0.x, standalone from 1.0; admin integrations stay optional
  files in that repository.
- **D-14 Papyro heading anchors** (C-12, PAPYRO-10, RENDER area decision 4). Recommendation: the gem defaults to
  Unicode GitHub-style slugs; Papyro keeps its legacy slugger through 0.x and decides at 1.0 with the baseline counts,
  because a broken `#fragment` cannot be redirected.
- **D-15 Live mode** (EDIT-06, EDIT-07, EDIT-39). Recommendation: Source is the default through 0.x; Live ships when
  EDIT-34 passes in Live mode, scheduled by the implementation epic rather than this plan, since it is the riskiest UX
  work for Spanish writers on composition input.

### Area decisions

Recommendations below are the area docs'; "agree" means the synthesis takes them as they are.

| Area | Decision | Area recommendation | Synthesis view |
|------|----------|---------------------|----------------|
| DX 1 | form-builder method name | `markdown_field` | agree |
| DX 2 | ship the model macro in 0.1 | yes, adding only `body_document` | agree; name in D-02 |
| DX 3 | configuration style | `Md.configure` initializer with every option commented | agree |
| DX 4 | generator edits files or prints steps | edit managed blocks and print what changed | agree |
| DX 5 | uploads default | on when Active Storage is present | agree with C-10's hook condition |
| DX 6 | custom syntax registration | explicit list | agree; mechanism per C-06 |
| DX 7 | deprecation before 1.0 | deprecate for one release in 0.x too | agree |
| DX 8 | docs site timing | README and CI quick start in 0.1; site and sandbox at 1.0 with a second app | agree |
| DX 9 | gem name | see D-01 | D-01 |
| RAILS 1 | version floor | Rails 8.1+, Ruby 3.3+ | D-12 |
| RAILS 2 | macro name and loading | load hook, name other than `has_markdown` | load hook agreed; name in D-02 |
| RAILS 3 | URL stored in markdown | the gem's stable route | agree |
| RAILS 4 | HTML-to-markdown converter on 8.1 | `to_markdown` when present, else `reverse_markdown` in the app once its licence is accepted | agree; the maintainer accepts or rejects the WTFPL licence |
| RAILS 5 | persisted HTML column | not in 0.1 | agree (RAILS-12 is `later`) |
| RAILS 6 | morph with a dirty editor | keep local text; the lock check reports the clash | agree |
| RAILS 7 | Action Text editor slot | no | agree (PRIOR area decision 8 agrees) |
| ASSETS 1 | vendored, npm or both | both | D-09 |
| ASSETS 2 | CodeMirror as one file or pins | one prebuilt file | D-08, with shim pins |
| ASSETS 3 | where Mermaid lives | companion gem | D-10 |
| ASSETS 4 | diagram mode under strict CSP | inline SVG with the doctor's warning | agree |
| ASSETS 5 | nested-language highlighting in the editor | no in 0.1 | agree |
| ASSETS 6 | size budgets | accept, revisit at 1.0 | agree |
| VIEWS 1 | Phlex runtime dependency | no | D-03 |
| VIEWS 2 | markup from Ruby or overridable partials | Ruby | agree |
| VIEWS 3 | first-party admin adapters | Formtastic and Avo after 0.1; Administrate and Madmin on request; RailsAdmin recipe | agree (0.2, later) |
| VIEWS 4 | inline error messages | no, match `text_area` | agree |
| VIEWS 5 | Avo field type name | gem-prefixed | agree; follows D-01 |
| VIEWS 6 | simple_form maps `text` automatically | no, opt-in | agree |
| THEME 1 | token prefix | derived from the gem name, two to five letters | D-01 |
| THEME 2 | shadcn fallbacks by default | yes | agree |
| THEME 3 | presets in 0.1 | `default` only | agree (THEME-12 in 0.2) |
| THEME 4 | dark-mode default | opt-in `prefers-color-scheme` | agree (C-13) |
| THEME 5 | icon set | Lucide subset, credited | agree |
| THEME 6 | code palette | fixed Primer-derived hues | agree |
| THEME 7 | accent token name | `--md-primary` and `--md-primary-foreground` | agree; decide before 0.1 |
| EDIT 1 | default mode | Source | agree (D-15) |
| EDIT 2 | Tab behaviour | indent in lists, cells in tables, focus elsewhere | agree |
| EDIT 3 | Mod+Shift+V | plain paste | agree |
| EDIT 4 | preview position | side by side from 1024 px, toggle below | agree |
| EDIT 5 | shared word rule | RENDER owns UAX #29 | resolved in C-02 |
| EDIT 6 | HTML paste converter | Turndown with the GFM plugin, lazy | agree |
| EDIT 7 | `/` menu default | on, line start or after a space | agree |
| EDIT 8 | Mod+Enter submits | off by default | agree |
| EDIT 9 | local backup | only with a host backup key | agree |
| RENDER 1 | raw HTML opt-in | never in 0.x | agree |
| RENDER 2 | sanitizer engine | rails-html-sanitizer 1.7.2+ | agree; Selma spike before 1.0 (PRIOR 3) |
| RENDER 3 | heading id namespace | plain ids with reserved-name suffix | agree |
| RENDER 4 | default slug style | Unicode | agree; Papyro per D-14 |
| RENDER 5 | external link `rel` | `nofollow ugc noopener` | agree |
| RENDER 6 | emoji shortcodes in v1 | on | agree |
| RENDER 7 | feed and email variants | one `:static` variant | agree |
| RENDER 8 | when dialect v2 ships | the 0.x after 0.1 | agree in substance; 0.3, because 0.2 carries uploads |
| AGENT 1 | revision model | content-addressed snapshots | agree |
| AGENT 2 | patch atomicity | all or nothing | agree |
| AGENT 3 | direct writes in 0.x | shipped, off by default | agree |
| AGENT 4 | MCP authentication default | an `authenticate` block, OAuth documented | agree |
| AGENT 5 | review endpoints mounted by default | yes, with a switch | agree; Papyro turns them off |
| AGENT 6 | audit table or events | events plus provenance columns | agree |
| AGENT 7 | MCP module location | in the gem, optional require | agree |
| AGENT 8 | bidi and tag characters | refuse | agree |
| AGENT 9 | unit of review | the agent's edit | agree |
| AGENT 10 | lock strategy | generator adds `lock_version` | agree (C-18) |
| AGENT 11 | relocating a conflicting hunk | no in the first release | agree |
| AGENT 12 | twin helpers in the gem | yes | agree; departs from the benchmark, which left twins to the host |
| PRIOR 1 | Stimulus over a textarea, not a custom element | confirm | agree |
| PRIOR 2 | `markdown-toolbar-element` | port with attribution | agree |
| PRIOR 3 | sanitizer engine | rails-html-sanitizer, Selma spike before 1.0 | agree |
| PRIOR 4 | html-pipeline filter interface | own interface with the same shape | agree; RENDER-23's `Md::HtmlFilter` has that shape with `call(element, context)` in place of `handle_element`; DX names the method (C-15) |
| PRIOR 5 | preview hook default | `authenticated?` or `current_user`, else `true` with a warning | D-06 |
| PRIOR 6 | CRLF normalization | `normalizes`; the macro uses it too | agree (RAILS-07) |
| PRIOR 7 | upstream fixes to Marksmith | yes, without waiting on them | agree |
| PRIOR 8 | Action Text editor adapter | not before Rails makes the API public | agree |
| PRIOR 9 | admin integrations location | optional files in the repository | D-13 |
| PAPYRO 1 | Papyro heading anchors | legacy slugger through 0.x | D-14 |
| PAPYRO 2 | where `ActionText::Markdown` lives | Papyro, behind the storage adapter | agree (RAILS-10) |
| PAPYRO 3 | body translations | keep the plain column | agree |
| PAPYRO 4 | when House goes | with the first gem editor release | agree (PAPYRO-23 in 0.1) |
| PAPYRO 5 | preview endpoint | keep Papyro's controller | agree |
| PAPYRO 6 | raw HTML in articles | convert by hand if the count is small | agree |
| PAPYRO 7 | gem workspace | companion during 0.x | D-13 |

## Tracked outside this epic

- #352: `ActionText::Markdown#to_html` sanitizes a second time and strips tables, heading ids and lightbox
  attributes; it is PAPYRO-01, migration step 0.
- #353: Papyro's CSP nonce is derived from the session id; the gem's strict-CSP support (ASSETS-13 to ASSETS-15)
  assumes a random per-request nonce.
- #340: the requirements checker's advisory gaps. `--synthesis` passes even when the area docs define no IDs, so the
  traceability check of this document was also verified against the union of IDs extracted from the ten docs (329
  IDs, all present).
- #338: `bin/worker-env` puts system Ruby ahead of version-manager shims; it affected the research workers only.
- Papyro's upload controller (`ActionText::Markdown::UploadsController#show`) serves any upload to anyone who has its
  slug and redirects to a permanent signed-id URL with a one-year public cache header (RAILS findings). The gem
  answers it with RAILS-18 to RAILS-21; Papyro's own fix has no issue yet and is listed as a follow-up of this item.

## Traceability

Every requirement ID of `requirements/*.md`, in area order. Notes name duplicates (one piece of work) and the
conflicts above.

| ID | Priority | Release | Doc | Notes |
|----|----------|---------|-----|-------|
| DX-01 | MUST | 0.1 | developer-experience.md | same work as PRIOR-03 |
| DX-02 | MUST | 0.1 | developer-experience.md |  |
| DX-03 | MUST | 0.1 | developer-experience.md | in 0.1 the upload step names the DX-19 seam; the authorization-hook step from 0.2 (RAILS-17, C-10) |
| DX-04 | MUST | 0.1 | developer-experience.md |  |
| DX-05 | SHOULD | 0.1 | developer-experience.md |  |
| DX-06 | SHOULD | 0.4 | developer-experience.md |  |
| DX-07 | MUST | 0.1 | developer-experience.md |  |
| DX-08 | MUST | 0.1 | developer-experience.md | same work as VIEWS-05, VIEWS-06 |
| DX-09 | MUST | 0.1 | developer-experience.md |  |
| DX-10 | MUST | 0.1 | developer-experience.md | subset of RENDER-01 |
| DX-11 | SHOULD | 0.1 | developer-experience.md | effective MUST for RAILS-07; macro name: C-04, D-02; same work as RAILS-06; agent options: C-25 |
| DX-12 | MUST | 0.1 | developer-experience.md | vocabulary extended: C-15 |
| DX-13 | MUST | 0.1 | developer-experience.md | macro name: C-04 |
| DX-14 | MUST | 0.1 | developer-experience.md | caching default: C-01 |
| DX-15 | MUST | 0.1 | developer-experience.md | authorization: C-09; Papyro turns the route off |
| DX-16 | SHOULD | 0.2 | developer-experience.md | shown only with a hook: C-10 |
| DX-17 | SHOULD | 0.1 | developer-experience.md | effective MUST for EDIT-15; same work as PRIOR-08, THEME-16 |
| DX-18 | MUST | 0.1 | developer-experience.md | no JS registry; PRIOR-12 via an event: C-08, D-11 |
| DX-19 | MUST | 0.1 | developer-experience.md | Papyro's upload adapter (PAPYRO-08); 0.1 tests the custom endpoint and `uploads: false`, the default and `url_for` cases from 0.2 with RAILS-17 |
| DX-20 | MUST | 0.1 | developer-experience.md | mechanism replaced by RENDER-20, RENDER-23: C-06 |
| DX-21 | SHOULD | later | developer-experience.md | conflicts with RENDER-03: C-07, D-07 |
| DX-22 | MUST | 0.1 | developer-experience.md |  |
| DX-23 | MUST | 0.1 | developer-experience.md |  |
| DX-24 | SHOULD | 0.2 | developer-experience.md |  |
| DX-25 | SHOULD | 0.1 | developer-experience.md |  |
| DX-26 | MUST | 0.1 | developer-experience.md | same policy as PRIOR-34 |
| DX-27 | MUST | 0.2 | developer-experience.md | copy-mode exception: C-24, D-09 |
| DX-28 | MUST | 0.1 | developer-experience.md |  |
| DX-29 | SHOULD | 1.0 | developer-experience.md |  |
| DX-30 | SHOULD | 0.1 | developer-experience.md |  |
| DX-31 | MUST | 0.1 | developer-experience.md |  |
| DX-32 | SHOULD | 1.0 | developer-experience.md |  |
| DX-33 | COULD | later | developer-experience.md |  |
| DX-34 | COULD | later | developer-experience.md |  |
| RAILS-01 | MUST | 0.1 | rails-framework-integration.md |  |
| RAILS-02 | SHOULD | 0.2 | rails-framework-integration.md |  |
| RAILS-03 | MUST | 0.1 | rails-framework-integration.md |  |
| RAILS-04 | MUST | 0.1 | rails-framework-integration.md |  |
| RAILS-05 | MUST | 0.1 | rails-framework-integration.md |  |
| RAILS-06 | SHOULD | 0.1 | rails-framework-integration.md | effective MUST for RAILS-07; same work as DX-11; name: D-02; agent options: C-25 |
| RAILS-07 | MUST | 0.1 | rails-framework-integration.md | settles AGENT-08: C-03 |
| RAILS-08 | MUST | 0.1 | rails-framework-integration.md | caching default: C-01 |
| RAILS-09 | SHOULD | 0.1 | rails-framework-integration.md | same event as RENDER-32 |
| RAILS-10 | MUST | 0.1 | rails-framework-integration.md | Papyro's ActionText::Markdown shape (PAPYRO-07) |
| RAILS-11 | MUST | 0.1 | rails-framework-integration.md |  |
| RAILS-12 | COULD | later | rails-framework-integration.md |  |
| RAILS-13 | MUST | 0.1 | rails-framework-integration.md |  |
| RAILS-14 | MUST | 0.2 | rails-framework-integration.md |  |
| RAILS-15 | MUST | 0.2 | rails-framework-integration.md |  |
| RAILS-16 | MUST | 0.2 | rails-framework-integration.md |  |
| RAILS-17 | MUST | 0.2 | rails-framework-integration.md | same work as PRIOR-24; URLs per C-23 |
| RAILS-18 | MUST | 0.2 | rails-framework-integration.md | one authorization hook: C-09, D-05 |
| RAILS-19 | MUST | 0.2 | rails-framework-integration.md |  |
| RAILS-20 | MUST | 0.2 | rails-framework-integration.md |  |
| RAILS-21 | MUST | 0.2 | rails-framework-integration.md | one authorization hook: C-09, D-05 |
| RAILS-22 | SHOULD | 0.2 | rails-framework-integration.md |  |
| RAILS-23 | SHOULD | 0.2 | rails-framework-integration.md |  |
| RAILS-24 | MUST | 0.1 | rails-framework-integration.md | same suite as PRIOR-21 |
| RAILS-25 | MUST | 0.1 | rails-framework-integration.md |  |
| RAILS-26 | MUST | 0.1 | rails-framework-integration.md |  |
| RAILS-27 | MUST | 0.1 | rails-framework-integration.md | diagram and math parts land in 0.3 |
| RAILS-28 | SHOULD | 0.1 | rails-framework-integration.md |  |
| RAILS-29 | MUST | 0.1 | rails-framework-integration.md |  |
| RAILS-30 | MUST | 0.1 | rails-framework-integration.md |  |
| RAILS-31 | MUST | 0.1 | rails-framework-integration.md | prefix meaning and acceptance per D-02; Papyro renames before step 2: C-04 |
| RAILS-32 | SHOULD | 0.1 | rails-framework-integration.md | effective MUST for DX-15's automatic preview mount |
| RAILS-33 | MUST | 0.1 | rails-framework-integration.md |  |
| RAILS-34 | MUST | 0.1 | rails-framework-integration.md | owns the i18n mechanism: C-14 |
| RAILS-35 | MUST | 0.1 | rails-framework-integration.md |  |
| RAILS-36 | SHOULD | 0.4 | rails-framework-integration.md |  |
| ASSETS-01 | MUST | 0.1 | asset-pipeline-integration.md |  |
| ASSETS-02 | MUST | 0.1 | asset-pipeline-integration.md | plus shim pins: C-11, D-08 |
| ASSETS-03 | MUST | 0.1 | asset-pipeline-integration.md |  |
| ASSETS-04 | MUST | 0.1 | asset-pipeline-integration.md | npm or generator copies in 0.1: D-09 |
| ASSETS-05 | MUST | 0.1 | asset-pipeline-integration.md | same work as PRIOR-10 |
| ASSETS-06 | SHOULD | 0.3 | asset-pipeline-integration.md | effective MUST for ASSETS-10's Vite Ruby smoke; needs the npm package (D-09) |
| ASSETS-07 | MUST | 0.2 | asset-pipeline-integration.md | math part in 0.3 |
| ASSETS-08 | MUST | 0.1 | asset-pipeline-integration.md |  |
| ASSETS-09 | SHOULD | 0.2 | asset-pipeline-integration.md |  |
| ASSETS-10 | MUST | 0.3 | asset-pipeline-integration.md |  |
| ASSETS-11 | MUST | 0.3 | asset-pipeline-integration.md | companion gem: C-20, D-10 |
| ASSETS-12 | SHOULD | 0.3 | asset-pipeline-integration.md | option names are DX's: C-15 |
| ASSETS-13 | MUST | 0.1 | asset-pipeline-integration.md | Papyro nonce fix tracked as #353 |
| ASSETS-14 | MUST | 0.3 | asset-pipeline-integration.md |  |
| ASSETS-15 | MUST | 0.1 | asset-pipeline-integration.md |  |
| ASSETS-16 | SHOULD | 0.3 | asset-pipeline-integration.md |  |
| ASSETS-17 | MUST | 0.3 | asset-pipeline-integration.md | editor rows of the table in 0.1 |
| ASSETS-18 | MUST | 0.1 | asset-pipeline-integration.md |  |
| ASSETS-19 | SHOULD | 0.1 | asset-pipeline-integration.md | effective MUST for THEME-06's Tailwind entry and DX-02's CSS wiring; cssbundling half needs the npm package (D-09) |
| ASSETS-20 | MUST | 0.3 | asset-pipeline-integration.md |  |
| VIEWS-01 | MUST | 0.1 | view-and-form-integration.md |  |
| VIEWS-02 | MUST | 0.1 | view-and-form-integration.md |  |
| VIEWS-03 | MUST | 0.1 | view-and-form-integration.md | Phlex dependency: C-05, D-03 |
| VIEWS-04 | COULD | 0.2 | view-and-form-integration.md | Phlex kit: C-05 |
| VIEWS-05 | MUST | 0.1 | view-and-form-integration.md | same work as DX-08 |
| VIEWS-06 | MUST | 0.1 | view-and-form-integration.md |  |
| VIEWS-07 | MUST | 0.1 | view-and-form-integration.md | scope narrowed: C-17 |
| VIEWS-08 | MUST | 0.1 | view-and-form-integration.md | simple_form, Formtastic and admin cases land with VIEWS-14 to VIEWS-18 |
| VIEWS-09 | MUST | 0.1 | view-and-form-integration.md |  |
| VIEWS-10 | MUST | 0.1 | view-and-form-integration.md |  |
| VIEWS-11 | MUST | 0.1 | view-and-form-integration.md | simple_form and Formtastic cases land in 0.2 with VIEWS-14, VIEWS-15 |
| VIEWS-12 | MUST | 0.1 | view-and-form-integration.md |  |
| VIEWS-13 | SHOULD | 0.2 | view-and-form-integration.md |  |
| VIEWS-14 | SHOULD | 0.2 | view-and-form-integration.md |  |
| VIEWS-15 | SHOULD | 0.2 | view-and-form-integration.md |  |
| VIEWS-16 | SHOULD | 0.2 | view-and-form-integration.md |  |
| VIEWS-17 | SHOULD | 0.2 | view-and-form-integration.md |  |
| VIEWS-18 | COULD | later | view-and-form-integration.md |  |
| VIEWS-19 | COULD | later | view-and-form-integration.md |  |
| VIEWS-20 | MUST | 0.1 | view-and-form-integration.md | adapter show views land with their adapters |
| VIEWS-21 | SHOULD | 0.2 | view-and-form-integration.md |  |
| VIEWS-22 | MUST | 0.1 | view-and-form-integration.md | adapter samples land with their adapters |
| VIEWS-23 | SHOULD | 0.2 | view-and-form-integration.md |  |
| EDIT-01 | MUST | 0.1 | editor-ux.md |  |
| EDIT-02 | MUST | 0.1 | editor-ux.md |  |
| EDIT-03 | MUST | 0.1 | editor-ux.md |  |
| EDIT-04 | MUST | 0.1 | editor-ux.md |  |
| EDIT-05 | MUST | 0.1 | editor-ux.md |  |
| EDIT-06 | SHOULD | later | editor-ux.md | Live mode: D-15 |
| EDIT-07 | SHOULD | later | editor-ux.md | Live mode: D-15 |
| EDIT-08 | SHOULD | 0.2 | editor-ux.md |  |
| EDIT-09 | MUST | 0.1 | editor-ux.md |  |
| EDIT-10 | MUST | 0.1 | editor-ux.md |  |
| EDIT-11 | MUST | 0.1 | editor-ux.md |  |
| EDIT-12 | MUST | 0.1 | editor-ux.md |  |
| EDIT-13 | MUST | 0.1 | editor-ux.md |  |
| EDIT-14 | MUST | 0.1 | editor-ux.md |  |
| EDIT-15 | MUST | 0.1 | editor-ux.md | extension budget: C-08 |
| EDIT-16 | COULD | later | editor-ux.md |  |
| EDIT-17 | MUST | 0.1 | editor-ux.md |  |
| EDIT-18 | MUST | 0.1 | editor-ux.md |  |
| EDIT-19 | MUST | 0.1 | editor-ux.md | uses the DX-19 upload seam |
| EDIT-20 | MUST | 0.1 | editor-ux.md |  |
| EDIT-21 | SHOULD | 0.2 | editor-ux.md |  |
| EDIT-22 | SHOULD | 0.2 | editor-ux.md |  |
| EDIT-23 | SHOULD | 0.2 | editor-ux.md |  |
| EDIT-24 | SHOULD | 0.2 | editor-ux.md | extension budget: C-08, D-11 |
| EDIT-25 | MUST | 0.1 | editor-ux.md |  |
| EDIT-26 | MUST | 0.1 | editor-ux.md |  |
| EDIT-27 | MUST | 0.1 | editor-ux.md |  |
| EDIT-28 | MUST | 0.1 | editor-ux.md |  |
| EDIT-29 | MUST | 0.1 | editor-ux.md |  |
| EDIT-30 | MUST | 0.1 | editor-ux.md | word rule: C-02 |
| EDIT-31 | MUST | 0.1 | editor-ux.md | word rule: C-02 |
| EDIT-32 | SHOULD | later | editor-ux.md |  |
| EDIT-33 | MUST | 0.1 | editor-ux.md |  |
| EDIT-34 | MUST | 0.1 | editor-ux.md |  |
| EDIT-35 | MUST | 0.1 | editor-ux.md |  |
| EDIT-36 | MUST | 0.1 | editor-ux.md |  |
| EDIT-37 | MUST | 0.1 | editor-ux.md |  |
| EDIT-38 | MUST | 0.1 | editor-ux.md |  |
| EDIT-39 | SHOULD | later | editor-ux.md | Live mode: D-15 |
| EDIT-40 | MUST | 0.1 | editor-ux.md |  |
| EDIT-41 | MUST | 0.1 | editor-ux.md | same work as RAILS-34: C-14 |
| EDIT-42 | COULD | later | editor-ux.md |  |
| EDIT-43 | COULD | later | editor-ux.md |  |
| RENDER-01 | MUST | 0.1 | render-and-viewer.md | superset of DX-10; locale default: C-22 |
| RENDER-02 | MUST | 0.1 | render-and-viewer.md | no upper bound: C-16, D-04 |
| RENDER-03 | MUST | 0.1 | render-and-viewer.md | conflicts with DX-21: C-07 |
| RENDER-04 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-05 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-06 | SHOULD | 0.1 | render-and-viewer.md |  |
| RENDER-07 | MUST | 0.1 | render-and-viewer.md | freeze needs an upper bound: C-16 |
| RENDER-08 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-09 | SHOULD | 0.3 | render-and-viewer.md | Mermaid delivery: C-20, D-10 |
| RENDER-10 | MUST | 0.1 | render-and-viewer.md | no sanitize opt-out: C-21 |
| RENDER-11 | COULD | later | render-and-viewer.md |  |
| RENDER-12 | SHOULD | 0.3 | render-and-viewer.md |  |
| RENDER-13 | COULD | later | render-and-viewer.md |  |
| RENDER-14 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-15 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-16 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-17 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-18 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-19 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-20 | MUST | 0.1 | render-and-viewer.md | replaces DX-20's passes: C-06 |
| RENDER-21 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-22 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-23 | SHOULD | 0.1 | render-and-viewer.md | effective MUST for 0.1 (PAPYRO-09): C-06 |
| RENDER-24 | SHOULD | 0.1 | render-and-viewer.md |  |
| RENDER-25 | SHOULD | 0.2 | render-and-viewer.md |  |
| RENDER-26 | MUST | 0.1 | render-and-viewer.md | slugger hook: C-12 |
| RENDER-27 | SHOULD | 0.1 | render-and-viewer.md | effective MUST for PAPYRO-10: C-12 |
| RENDER-28 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-29 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-30 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-31 | SHOULD | 0.1 | render-and-viewer.md | effective MUST for DX-14's cache hit: C-01 |
| RENDER-32 | SHOULD | 0.1 | render-and-viewer.md | same event as RAILS-09 |
| RENDER-33 | SHOULD | 0.2 | render-and-viewer.md |  |
| RENDER-34 | COULD | later | render-and-viewer.md |  |
| RENDER-35 | SHOULD | 0.1 | render-and-viewer.md | effective MUST for 0.1: C-02 |
| RENDER-36 | SHOULD | 0.2 | render-and-viewer.md |  |
| RENDER-37 | MUST | 0.1 | render-and-viewer.md | word rule input: C-02 |
| RENDER-38 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-39 | COULD | later | render-and-viewer.md |  |
| RENDER-40 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-41 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-42 | MUST | 0.3 | render-and-viewer.md | Mermaid delivery: C-20 |
| RENDER-43 | MUST | 0.3 | render-and-viewer.md |  |
| RENDER-44 | MUST | 0.3 | render-and-viewer.md |  |
| RENDER-45 | MUST | 0.1 | render-and-viewer.md | diagram case lands in 0.3, as RAILS-27; 0.1 covers heading links and the lightbox |
| RENDER-46 | MUST | 0.1 | render-and-viewer.md | diagram parts land in 0.3 |
| RENDER-47 | SHOULD | 0.2 | render-and-viewer.md |  |
| RENDER-48 | SHOULD | 0.3 | render-and-viewer.md |  |
| RENDER-49 | COULD | later | render-and-viewer.md |  |
| RENDER-50 | COULD | later | render-and-viewer.md |  |
| RENDER-51 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-52 | MUST | 0.1 | render-and-viewer.md |  |
| RENDER-53 | SHOULD | 0.2 | render-and-viewer.md |  |
| RENDER-54 | MUST | 0.1 | render-and-viewer.md | upper bound: D-04 |
| THEME-01 | MUST | 0.1 | theming-and-customization.md |  |
| THEME-02 | MUST | 0.1 | theming-and-customization.md |  |
| THEME-03 | MUST | 0.1 | theming-and-customization.md |  |
| THEME-04 | MUST | 0.1 | theming-and-customization.md |  |
| THEME-05 | SHOULD | 0.2 | theming-and-customization.md |  |
| THEME-06 | MUST | 0.1 | theming-and-customization.md |  |
| THEME-07 | MUST | 0.1 | theming-and-customization.md | wins over PRIOR-22: C-13 |
| THEME-08 | SHOULD | 0.2 | theming-and-customization.md |  |
| THEME-09 | MUST | 0.1 | theming-and-customization.md |  |
| THEME-10 | MUST | 0.1 | theming-and-customization.md |  |
| THEME-11 | SHOULD | 0.3 | theming-and-customization.md | Mermaid delivery: C-20 |
| THEME-12 | SHOULD | 0.2 | theming-and-customization.md | theme presets, not field presets: C-15 |
| THEME-13 | MUST | 0.2 | theming-and-customization.md |  |
| THEME-14 | MUST | 0.2 | theming-and-customization.md |  |
| THEME-15 | MUST | 0.1 | theming-and-customization.md |  |
| THEME-16 | MUST | 0.1 | theming-and-customization.md | same work as DX-17, PRIOR-08; preset layer is PRIOR-07's (C-15) |
| THEME-17 | MUST | 0.1 | theming-and-customization.md | extension budget: C-08 |
| THEME-18 | MUST | 0.1 | theming-and-customization.md | owns key-rename policy: C-14 |
| THEME-19 | SHOULD | 0.2 | theming-and-customization.md |  |
| THEME-20 | COULD | later | theming-and-customization.md |  |
| THEME-21 | SHOULD | 0.2 | theming-and-customization.md |  |
| AGENT-01 | MUST | 0.4 | agent-layer.md | macro name D-02; check timing: C-18 |
| AGENT-02 | MUST | 0.4 | agent-layer.md |  |
| AGENT-03 | MUST | 0.4 | agent-layer.md | LF ids: C-03 |
| AGENT-04 | MUST | 0.4 | agent-layer.md |  |
| AGENT-05 | MUST | 0.4 | agent-layer.md |  |
| AGENT-06 | MUST | 0.4 | agent-layer.md |  |
| AGENT-07 | MUST | 0.4 | agent-layer.md |  |
| AGENT-08 | MUST | 0.4 | agent-layer.md | settled by RAILS-07: C-03 |
| AGENT-09 | SHOULD | 0.4 | agent-layer.md |  |
| AGENT-10 | MUST | 0.4 | agent-layer.md |  |
| AGENT-11 | MUST | 0.4 | agent-layer.md |  |
| AGENT-12 | MUST | 0.4 | agent-layer.md |  |
| AGENT-13 | MUST | 0.4 | agent-layer.md |  |
| AGENT-14 | SHOULD | 0.4 | agent-layer.md |  |
| AGENT-36 | MUST | 0.4 | agent-layer.md |  |
| AGENT-15 | MUST | 0.4 | agent-layer.md | Phlex component via VIEWS-04: C-05 |
| AGENT-16 | MUST | 0.4 | agent-layer.md |  |
| AGENT-17 | MUST | 0.4 | agent-layer.md |  |
| AGENT-18 | MUST | 0.4 | agent-layer.md |  |
| AGENT-19 | MUST | 0.4 | agent-layer.md |  |
| AGENT-20 | MUST | 0.4 | agent-layer.md |  |
| AGENT-21 | SHOULD | 0.4 | agent-layer.md |  |
| AGENT-22 | SHOULD | 0.4 | agent-layer.md |  |
| AGENT-23 | COULD | later | agent-layer.md |  |
| AGENT-24 | MUST | 0.4 | agent-layer.md | one authorization hook: C-09, D-05 |
| AGENT-25 | MUST | 0.4 | agent-layer.md |  |
| AGENT-26 | MUST | 0.4 | agent-layer.md |  |
| AGENT-27 | MUST | 0.4 | agent-layer.md |  |
| AGENT-28 | SHOULD | 0.4 | agent-layer.md |  |
| AGENT-29 | SHOULD | 0.4 | agent-layer.md |  |
| AGENT-30 | SHOULD | 0.4 | agent-layer.md |  |
| AGENT-31 | COULD | later | agent-layer.md |  |
| AGENT-32 | SHOULD | 0.4 | agent-layer.md | macro name: C-04; added only with the agent layer: C-25 |
| AGENT-33 | MUST | 0.4 | agent-layer.md |  |
| AGENT-34 | MUST | 0.4 | agent-layer.md |  |
| AGENT-35 | COULD | later | agent-layer.md |  |
| PRIOR-01 | MUST | 0.1 | prior-art-teardown.md | same work as RAILS-07: C-03 |
| PRIOR-02 | MUST | 0.1 | prior-art-teardown.md | same work as EDIT-10 |
| PRIOR-03 | MUST | 0.1 | prior-art-teardown.md | same work as DX-01 |
| PRIOR-04 | MUST | 0.1 | prior-art-teardown.md |  |
| PRIOR-05 | MUST | 0.1 | prior-art-teardown.md |  |
| PRIOR-06 | MUST | 0.1 | prior-art-teardown.md |  |
| PRIOR-07 | SHOULD | 0.1 | prior-art-teardown.md | effective MUST for THEME-16's preset layer (C-15) |
| PRIOR-08 | SHOULD | 0.1 | prior-art-teardown.md | same work as DX-17, THEME-16 |
| PRIOR-09 | MUST | 0.1 | prior-art-teardown.md | shim pins: C-11 |
| PRIOR-10 | MUST | 0.1 | prior-art-teardown.md | same work as ASSETS-05 |
| PRIOR-11 | MUST | 0.1 | prior-art-teardown.md |  |
| PRIOR-12 | SHOULD | 0.2 | prior-art-teardown.md | via a DOM event, not a registry: C-08, D-11 |
| PRIOR-13 | SHOULD | 0.2 | prior-art-teardown.md |  |
| PRIOR-14 | MUST | 0.1 | prior-art-teardown.md |  |
| PRIOR-15 | MUST | 0.1 | prior-art-teardown.md |  |
| PRIOR-16 | MUST | 0.1 | prior-art-teardown.md | authorization: C-09, D-06 |
| PRIOR-17 | MUST | 0.1 | prior-art-teardown.md | mechanism of RENDER-20, RENDER-21; no sanitize opt-out: C-21 |
| PRIOR-18 | MUST | 0.1 | prior-art-teardown.md |  |
| PRIOR-19 | SHOULD | 0.1 | prior-art-teardown.md |  |
| PRIOR-20 | SHOULD | later | prior-art-teardown.md |  |
| PRIOR-21 | MUST | 0.1 | prior-art-teardown.md | same suite as RAILS-24 to RAILS-27 |
| PRIOR-22 | MUST | 0.1 | prior-art-teardown.md | dark default follows THEME-07: C-13 |
| PRIOR-23 | MUST | 0.1 | prior-art-teardown.md |  |
| PRIOR-24 | MUST | 0.2 | prior-art-teardown.md | same work as RAILS-17; URLs per C-23 |
| PRIOR-25 | SHOULD | later | prior-art-teardown.md | needs a dialect addition: C-19 |
| PRIOR-26 | COULD | later | prior-art-teardown.md |  |
| PRIOR-27 | MUST | 0.1 | prior-art-teardown.md | same work as EDIT-12 |
| PRIOR-28 | SHOULD | 0.1 | prior-art-teardown.md |  |
| PRIOR-29 | SHOULD | 0.2 | prior-art-teardown.md |  |
| PRIOR-30 | COULD | later | prior-art-teardown.md |  |
| PRIOR-31 | MUST | 0.1 | prior-art-teardown.md | same work as RAILS-34: C-14 |
| PRIOR-32 | MUST | 1.0 | prior-art-teardown.md | Chromium job from 0.1 |
| PRIOR-33 | SHOULD | 1.0 | prior-art-teardown.md |  |
| PRIOR-34 | MUST | 0.1 | prior-art-teardown.md | same policy as DX-26 |
| PRIOR-35 | MUST | 0.1 | prior-art-teardown.md |  |
| PRIOR-36 | MUST | 0.1 | prior-art-teardown.md | same work as EDIT-14 |
| PAPYRO-01 | MUST | 0.1 | papyro-as-consumer.md | Papyro step 0, tracked as #352 |
| PAPYRO-02 | MUST | 0.1 | papyro-as-consumer.md |  |
| PAPYRO-03 | MUST | 0.1 | papyro-as-consumer.md | CRLF: C-03 |
| PAPYRO-04 | MUST | 0.1 | papyro-as-consumer.md |  |
| PAPYRO-05 | SHOULD | 0.1 | papyro-as-consumer.md |  |
| PAPYRO-06 | MUST | 0.1 | papyro-as-consumer.md |  |
| PAPYRO-07 | MUST | 0.1 | papyro-as-consumer.md | reads Papyro's macro under its D-02 name |
| PAPYRO-08 | MUST | 0.1 | papyro-as-consumer.md | through DX-19 |
| PAPYRO-09 | MUST | 0.1 | papyro-as-consumer.md | through RENDER-23 |
| PAPYRO-10 | MUST | 0.1 | papyro-as-consumer.md | slugger hook: C-12, D-14 |
| PAPYRO-11 | MUST | 0.1 | papyro-as-consumer.md | word rule: C-02 |
| PAPYRO-12 | SHOULD | 0.1 | papyro-as-consumer.md |  |
| PAPYRO-13 | SHOULD | 0.1 | papyro-as-consumer.md |  |
| PAPYRO-14 | MUST | 0.1 | papyro-as-consumer.md |  |
| PAPYRO-15 | MUST | 0.1 | papyro-as-consumer.md | locale default: C-22 |
| PAPYRO-16 | MUST | 0.4 | papyro-as-consumer.md | first mounted gem endpoint is AGENT's |
| PAPYRO-17 | MUST | 0.1 | papyro-as-consumer.md | met through render_in: C-05 |
| PAPYRO-18 | MUST | 0.1 | papyro-as-consumer.md |  |
| PAPYRO-19 | MUST | 0.1 | papyro-as-consumer.md |  |
| PAPYRO-20 | MUST | 0.1 | papyro-as-consumer.md |  |
| PAPYRO-21 | MUST | 0.1 | papyro-as-consumer.md |  |
| PAPYRO-22 | SHOULD | 0.1 | papyro-as-consumer.md |  |
| PAPYRO-23 | SHOULD | 0.1 | papyro-as-consumer.md |  |
| PAPYRO-24 | SHOULD | 0.4 | papyro-as-consumer.md |  |
| PAPYRO-25 | SHOULD | 0.1 | papyro-as-consumer.md |  |
| PAPYRO-26 | COULD | later | papyro-as-consumer.md |  |
