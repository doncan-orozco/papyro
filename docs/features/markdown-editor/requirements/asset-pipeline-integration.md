# ASSETS: JavaScript and CSS delivery requirements for the Md gem

This doc covers how the gem's JavaScript and CSS reach a Rails app, whichever asset setup the app has: importmap-rails, the
jsbundling-rails bundlers (esbuild, Rollup, Bun, webpack), Vite Ruby, Shakapacker, Propshaft or Sprockets, and
cssbundling-rails or tailwindcss-rails for CSS. Delivery is the first thing a newcomer meets: an editor that needs ten pins, a
CDN round trip or a CSP exception before it renders fails the gem's first priority, developer experience. The numbers below were
measured on 2026-11-03 in a throwaway Rails 8.1.4 app and in esbuild builds outside the repository. Only the findings are committed.

## Scope

This doc decides:

- the delivery artifacts: vendored ESM files in the gem, an npm package, or both, and how their versions stay in sync;
- how CodeMirror 6, KaTeX and Mermaid are packaged, pinned and lazy-loaded in each pipeline;
- what each option costs in pins, gzipped bytes and install steps;
- what the gem needs to work under a strict Content-Security-Policy with nonces;
- how the CSS reaches apps with and without Tailwind.

Other areas decide the rest: the install generator, the doctor command and the configuration API (`DX`), the design tokens and
theme (`THEME`), Turbo behaviour of the Stimulus wrapper (`RAILS`), editor features (`EDIT`), server-side diagram SVG, the
sanitizer and the viewer's diagram mode (`RENDER`), and Papyro's own adoption (`PAPYRO`).

Out of scope (WON'T):

- loading anything from a public CDN at runtime by default (a host may opt in, see ASSETS-12);
- React, Vue or other view-framework builds;
- Sprockets below 4, and Sass/SCSS pipelines (chadcn's decision, cited below, applies here as well);
- webpacker (retired; Shakapacker is its successor).

## Questions

1. Should the gem publish an npm package, vendor ESM files, or both, and how do versions stay in sync?
2. How many importmap pins and gzipped bytes do the editor and the viewer cost, measured in a scratch Rails app?
3. How does the gem work under a strict CSP with nonces and no `'unsafe-inline'`?
4. What does the install look like in each pipeline (importmap, jsbundling, Vite Ruby, Shakapacker, Propshaft, Sprockets, cssbundling, tailwindcss-rails v4)?
5. How are Mermaid and KaTeX lazy-loaded so pages without diagrams or math pay nothing?

## Findings

The benchmark report already settles the stack: CodeMirror 6 for the editor, client-side Mermaid 12 (`securityLevel: 'strict'`)
and KaTeX lazy-loaded by a Stimulus controller, both JS pipelines supported, and importmap pins that resolve to one copy of
`@codemirror/state` and `@codemirror/view` (`../reports/Markdown editor benchmark.md`, "Source-of-truth libraries beat doc-model editors for an agent-edited corpus" and the "What the gem provides" table with "Both JS pipelines";
`../research_notes/Markdown editor benchmark/editor_libraries.md` Q3; `rendering_and_syntax.md` §5). That research left one open
item: "No measured importmap payloads". This doc measures them.

Versions measured: rails 8.1.4, importmap-rails 2.2.3, propshaft 1.3.2, jsbundling-rails 1.3.1, `@codemirror/view` 6.43.15,
`@codemirror/state` 6.7.6, `@codemirror/lang-markdown` 6.5.2, `@lezer/markdown` 1.8.1, mermaid 12.3.0, katex 0.19.1, lexxy 1.0.3,
marksmith 0.6.0. Sizes are bytes divided by 1024, compressed with `gzip -9`. The browser checks ran in Chromium.

### F1. Editor cost: pins and bytes

| Editor build | Delivery | Files (pins) | Raw | Gzip |
|---|---|---|---|---|
| `@codemirror/{state,view,commands,language,lang-markdown}` via `bin/importmap pin` (jspm) | 21 vendored files | 21 | 614.2 KiB | 211.3 KiB |
| Same editor, one esbuild bundle, minified | 1 vendored file | 1 | 497.6 KiB | 171.6 KiB |
| Lean editor: own `Language` over `@lezer/markdown` + GFM, no `lang-markdown` | 1 esbuild file, minified | 1 | 308.1 KiB | **100.5 KiB** |
| Lean editor as individual jspm pins (sum of the same jspm files) | 11 vendored files | 11 | n/a | 127.7 KiB |
| Prior art: Lexxy 1.0.3 `lexxy.min.js` (Lexical, prebuilt) | 1 file in the gem | 1 | 642.0 KiB | 196.1 KiB |
| Prior art: Marksmith 0.6.0 controller (`-no-stimulus.esm.js`, textarea) | 1 file in the gem | 1 | 103.7 KiB | 20.8 KiB |

- `@codemirror/lang-markdown` statically imports `@codemirror/lang-html`, which pulls in `lang-css`, `lang-javascript`,
  `autocomplete`, `streamparser`, the grammars `@lezer/html`, `@lezer/css` and `@lezer/javascript`, and the `@lezer/lr` parser
  runtime. With `lang-markdown` itself these are 10 of the 21 pins, all there for HTML blocks and nested code.
  `@lezer/javascript` alone is 29 KiB gzipped. A language built directly on `@lezer/markdown` with the GFM extensions keeps
  markdown highlighting and drops those 10 packages: the minified editor goes from 171.6 KiB to 100.5 KiB gzipped (−41%).
- Every jspm-vendored file imports bare specifiers (`@codemirror/state`, `@lezer/common`, …). The import map has one entry per
  specifier, so the map itself guarantees a single copy of `@codemirror/state` and `@codemirror/view`. The risk the benchmark
  names (two versions of a pin) can come only from a host pinning a second version under the same name, and then the host's pin
  replaces the gem's (importmap-rails 2.2.3 `lib/importmap/engine.rb` appends the app's `config/importmap.rb` after the paths
  engines add and draws them in order, and a later `pin` of the same name overwrites the earlier one). The doctor check in the
  DX notes therefore detects a host pin named `@codemirror/state` instead of relying on it.
- A single prebuilt file is the Lexxy pattern: one pin, nothing for `bin/importmap` to resolve, and the same bytes in every app.
  The cost is that host code can only reuse that copy of CodeMirror through re-exports from the gem's file. Importing
  `@codemirror/view` separately would load a second instance.
- The esbuild metafile of the lean build shows `@codemirror/view` as its largest input: 154.9 KiB of the 308.1 KiB raw output.

### F2. Viewer cost: core, KaTeX and Mermaid

| Viewer piece | Loaded when | Files | Gzip |
|---|---|---|---|
| Viewer Stimulus controller (heading links, lazy loader) | every page with a markdown view | 1 pin | not measurable yet (no gem); budget in ASSETS-08 |
| KaTeX (`katex` via jspm, minified ESM) | page has a math node | 1 pin | 74.9 KiB |
| KaTeX CSS (`katex.min.css`) | page has a math node | 1 | 3.4 KiB |
| KaTeX fonts | glyphs used | up to 20 woff2 files (296 KiB on disk) | only the fonts used are fetched |
| Mermaid 12.3.0 npm ESM dist, first flowchart | page has a diagram | 25 | 212.0 KiB |
| Mermaid rebuilt with esbuild `--splitting`, `.digested` chunks, first flowchart | page has a diagram | 26 (108 in the build, 5.3 MB on disk) | 186.9 KiB |

- **`bin/importmap pin mermaid` fails.** jspm answers "Couldn't find any packages in ["mermaid"]", and so does `--from jsdelivr`.
  Asking the jspm generator API directly returns `Unable to resolve https://ga.jspm.io/npm:mermaid@12.3.0/`. An importmap host
  therefore cannot get Mermaid by the normal route. The gem has to vendor it.
- **The raw Mermaid dist breaks under Propshaft in production.** Propshaft rewrites only CSS `url()` and the JS
  `RAILS_ASSET_URL()` pseudo-function. After `assets:precompile`, the chunks of the vendored `mermaid.esm.min.mjs` get digested
  names (`abnfDiagram-7WIW2FYK-e1d935de.mjs`), but the entry still imports `./chunks/mermaid.esm.min/flowDiagram-MIYXRJYK.mjs`,
  which is no longer in `public/assets`, so the request 404s.
- **A `.digested` rebuild works.** Propshaft leaves files named `-[digest].digested.js` untouched. An esbuild rebuild
  (`--bundle --format=esm --splitting --minify --chunk-names='[name]-[hash].digested'`) precompiles correctly: the entry gets
  a digest (`mermaid-75f9435f.js`), the 107 chunks keep their names, and the relative imports resolve. A host can pin it as
  `pin "mermaid", to: "mermaid/mermaid.js", preload: false`.
- Only Propshaft was measured. Whether Sprockets 4 leaves `.digested` chunks undigested in production is not verified, so it
  is an acceptance check (ASSETS-11), not a finding. Under Sprockets the 108 Mermaid files also join the precompile list
  (ASSETS-07).
- A page with no diagram and no math pays only for the viewer controller, as long as the heavy modules are imported lazily
  (see F3).
- Viewer cost per page under importmap: a plain article loads the viewer controller only; a math page adds 2 files (78.3 KiB
  gzipped, plus the fonts it uses); a diagram page adds 26 files (186.9 KiB gzipped).

### F3. Lazy loading differs per pipeline unless the gem controls it

- Under importmap, a dynamic `import("katex")` resolves through the map at runtime. `preload: false` keeps the pin out of the
  `modulepreload` links, and importmap-rails can also limit preloading to named entry points.
- The jsbundling-rails default configs **inline dynamic imports**. The esbuild script runs `--format=esm` without `--splitting`,
  the Rollup config sets `inlineDynamicImports: true`, and the webpack config limits output to one chunk (`maxChunks: 1`). In the
  default esbuild build, a literal `import("katex")` put KaTeX into the main bundle (about 550 KB raw, decimal as logged). An
  `import(url)` whose argument is a variable is left alone (93 bytes of output).
- So the gem loads Mermaid and KaTeX with `import(/* webpackIgnore: true */ /* @vite-ignore */ this.mermaidUrlValue)`, where
  the URL is rendered server-side with `asset_path`. Measured: under importmap and the default jsbundling esbuild build the
  module stays out of the host bundle (93 bytes). Not measured: Rollup, Bun, webpack (jsbundling and Shakapacker) and Vite
  Ruby. webpack turns a non-literal `import()` into a context module unless `webpackIgnore` is set, and Vite warns about it
  unless `@vite-ignore` is set, so both comments are part of the loader contract and the per-bundler behaviour is an
  acceptance check (ASSETS-10), not a finding.

### F4. CSP: what each library does under a strict policy

Test policy (meta tag): `script-src 'self' 'nonce-…'; style-src 'self' 'nonce-…'`, no `'unsafe-inline'`. Violations were
counted with a `securitypolicyviolation` listener.

| Library and call | Violations | Result |
|---|---|---|
| CodeMirror without `EditorView.cspNonce` | 1 `style-src-elem` | editor unstyled (`.cm-editor` is `display: block`, not flex) |
| CodeMirror with `EditorView.cspNonce.of(nonce)` | 0 | styled; its `<style>` element carries the nonce |
| KaTeX `katex.render(tex, element)` | 0 | correct (styles are set through the CSSOM, which CSP allows) |
| KaTeX `element.innerHTML = katex.renderToString(tex)` | 13 `style-src-attr` | struts and sizes lost |
| Mermaid `mermaid.run()`, `securityLevel: "strict"` | ~60 `style-src-attr`, 3 `style-src-elem` | SVG renders unstyled (node fill black) |
| Mermaid `mermaid.render()` to a string, shown as `<img src="blob:…">` | 37 during measuring | diagram legible (the SVG's own styles apply inside the image document) |

- CodeMirror's `style-mod` uses `adoptedStyleSheets` only for shadow roots. For a normal document it appends a `<style>` element,
  so the nonce must reach `EditorView.cspNonce`. Rails already prints it in `csp_meta_tag`, so the controller can read
  `meta[name="csp-nonce"]` with no new API.
- importmap-rails already adds `request.content_security_policy_nonce` to the import map, module and `modulepreload` tags, so the
  gem's pins inherit the nonce.
- Mermaid has no nonce option. Strict hosts have three choices: allow inline styles for attributes and elements, use image mode
  (still noisy in CSP reports), or use server-side SVG served as an image (the `RENDER` area; benchmark report, rendering section).
- Papyro's current policy allows `'unsafe-inline'` for `style-src`, `style-src-elem` and `style-src-attr`, and uses a nonce only for
  `script-src` (`config/initializers/content_security_policy.rb`). So Papyro works today, and the strict case is what other
  host apps need.

### F5. CSS delivery

- tailwindcss-rails (4.3.0 and newer) bundles an engine's `app/assets/tailwind/<engine_name>/engine.css` into
  `app/assets/builds/tailwind/<engine_name>.css`. The host opts in by importing it. chadcn uses this, with an `@source` relative
  to `engine.css` so Tailwind 4 scans the installed gem wherever it lives (chadcn `app/assets/tailwind/chadcn/engine.css`).
- A gem whose markup uses its own semantic class names (`.md-prose`, `.md-editor`) built on CSS custom properties needs no
  `@source` scan and works without Tailwind: a plain stylesheet served by Propshaft or Sprockets is enough. Marksmith does this
  (`stylesheet_link_tag "marksmith"`).
- Propshaft rewrites `url()` inside CSS to digested paths, so KaTeX's `url(fonts/…)` works if the fonts sit next to the CSS on
  the asset path. Sprockets does not rewrite `url()` in plain `.css`. Whether KaTeX fonts load under Sprockets in production
  has not been verified, so it is an acceptance check (ASSETS-20), not a finding.

### F6. Prior art for delivery

- **chadcn** (sibling repository) supports Propshaft + importmap, Propshaft + esbuild and Sprockets 4 + importmap, each covered by
  a CI smoke. Under Sprockets the engine declares its pinned files in `config.assets.precompile`, because the host's
  `manifest.js` cannot link files inside a gem. For esbuild apps, chadcn chose a generator that copies the JavaScript into the
  app and adds the npm dependencies to `package.json`, rather than publishing an npm package: publishing needs a maintainer and
  lockstep versions (chadcn `dev/decisions/js-bundlers.md`, `sprockets.md`).
- **Lexxy** ships prebuilt `lexxy.js` and `lexxy.min.js` in the gem for importmap (the host adds `pin "lexxy", to: "lexxy.js"`) and the npm
  package `@37signals/lexxy` for bundlers.
- **Marksmith** publishes `@avo-hq/marksmith` to npm (also pinnable with `bin/importmap pin`) and ships its CSS in the gem.
- Not measured (docs only): Vite Ruby compiles only entrypoints under the app's source directory unless `additionalEntrypoints` and
  `watchAdditionalPaths` are configured. For a gem, an npm package resolved from `node_modules` is the straightforward route,
  and the same goes for Shakapacker (webpack or rspack).

### F7. Install steps per pipeline (proposed)

`md` and `@md/rails` are placeholders until the naming decision lands.

| Pipeline | JavaScript | CSS | Steps after `bundle add md` |
|---|---|---|---|
| importmap + Propshaft | engine pins (no `bin/importmap pin`) | `stylesheet_link_tag "md"` | `bin/rails g md:install` (adds the import and the link tag) |
| importmap + Sprockets 4 | engine pins; engine adds them to `config.assets.precompile` | `stylesheet_link_tag "md"` | same generator; no `manifest.js` edit |
| jsbundling (esbuild, Rollup, Bun, webpack) | `@md/rails` from npm, `import "@md/rails"` | `stylesheet_link_tag "md"` (gem) or the package's CSS | generator adds `@md/rails` at the gem's version with the app's package manager (yarn, pnpm, bun or npm, chosen by the lock file) |
| Vite Ruby | `@md/rails` from npm | gem stylesheet, or `import "@md/rails/md.css"` | same generator; no `vite.json` change expected (not measured) |
| Shakapacker | `@md/rails` from npm | gem stylesheet, or the package's CSS | same generator |
| tailwindcss-rails v4 (CSS only) | n/a | optional `@import "../builds/tailwind/md";` | generator adds the import only when tailwindcss-rails ≥ 4.3.0 is present |
| cssbundling-rails (CSS only) | n/a | `@import "@md/rails/md.css";` | same generator |

In every row the lazy Mermaid and KaTeX files come from the gem's assets through `asset_path` (F3), not from npm.

## Requirements

Grouped by delivery, size, lazy loading, CSP and CSS. Each acceptance check runs in a fresh Rails 8.1 app unless it says otherwise.

### Delivery

- **ASSETS-01** (MUST) In an importmap app the engine adds its own pins through `config.importmap.paths`, so the host never runs
  `bin/importmap pin` for the gem. Acceptance: a fresh importmap app renders the editor and the viewer after `bundle add` and
  the install generator, with no other step.
- **ASSETS-02** (MUST) The CodeMirror code the editor uses ships as one prebuilt, minified ESM file in the gem that also
  re-exports the CodeMirror modules (`state`, `view`, `language`, `commands`), so host extensions share the same single copy.
  Acceptance: `bin/importmap json` lists one CodeMirror pin from the gem, and a host extension imported from the gem's re-export
  attaches to the editor without the "multiple instances of @codemirror/state" error.
- **ASSETS-03** (MUST) The editor's default markdown language is built on `@lezer/markdown` with GFM and does not statically
  import `@codemirror/lang-html` or other nested-language grammars. Acceptance: the built editor file contains no
  `@lezer/javascript`, `@lezer/css` or `@lezer/html` code (checked from the esbuild metafile).
- **ASSETS-04** (MUST) Bundler apps (jsbundling with esbuild, Rollup, Bun or webpack, Vite Ruby, Shakapacker) get the same
  Stimulus controllers and identifiers without a machine-specific gem path: from the npm package, or from generator-managed
  copies until it is published (see Open decisions), with CodeMirror as an npm dependency the host's bundler deduplicates.
  Acceptance: a CI smoke with the default jsbundling esbuild config renders the editor, and `npm ls @codemirror/state` shows
  one version.
- **ASSETS-05** (MUST) The JavaScript a bundler app runs is versioned with the gem: the npm package version equals
  `Md::VERSION` and both publish from one tag by one release workflow, or each managed copy carries the gem version in its
  header. Acceptance: the release workflow fails when `package.json` and `Md::VERSION` differ, and the doctor (`DX`) fails
  with the exact install command when the installed JavaScript version differs from the gem.
- **ASSETS-06** (SHOULD) Vite Ruby and Shakapacker are supported through the npm package alone, with an install snippet each and
  no gem-side configuration. Acceptance: the README has both snippets, and a Vite Ruby smoke runs in CI before 1.0.
- **ASSETS-07** (MUST) Under Sprockets 4 the engine declares every pinned and lazily loaded file in `config.assets.precompile`,
  so the host edits no `manifest.js`. Acceptance: a CI smoke with sprockets-rails + importmap runs `assets:precompile` in
  production mode and renders the editor and a math block.

### Size budgets

- **ASSETS-08** (MUST) Gem CI enforces gzip budgets: editor file (with the ASSETS-02 re-exports) at most 110 KiB, viewer
  controller at most 10 KiB, and no growth over 5% between minor releases without a CHANGELOG note. Acceptance: a CI job
  measures `gzip -9` sizes of the built files, fails above the budget, and fails on growth over 5% against the last release's
  recorded sizes unless the CHANGELOG names the file.
- **ASSETS-09** (SHOULD) The editor pin is not `modulepreload`ed on pages that render no editor (public article pages).
  Acceptance: the HTML of a viewer-only page has no `modulepreload` link to the editor file.

### Lazy loading

- **ASSETS-10** (MUST) Mermaid and KaTeX load only when the page has a diagram or math node, through `import(url)` with the
  URL rendered from `asset_path` into a Stimulus value, so bundlers never inline them. Acceptance: a page without diagrams or
  math makes no request for Mermaid or KaTeX, and in CI smokes for jsbundling esbuild, jsbundling webpack and Vite Ruby a math
  page renders while the host bundle size is the same with math on or off.
- **ASSETS-11** (MUST) The vendored Mermaid is a Propshaft-safe build whose chunks are named `[name]-[hash].digested.js`,
  regenerated by a gem rake task on every Mermaid upgrade. Acceptance: after `RAILS_ENV=production bin/rails
  assets:precompile` in Propshaft and Sprockets apps, rendering a flowchart triggers no 404.
- **ASSETS-12** (SHOULD) A host can point Mermaid and KaTeX at its own URL (including a CDN), or turn either feature off
  (option names are DX's to settle). Acceptance: `Md.configure { it.mermaid_url = false }` removes the diagram loader from the rendered page, and a custom URL
  appears in the Stimulus value.

### Content-Security-Policy

- **ASSETS-13** (MUST) The editor works under a strict CSP with nonces and no `'unsafe-inline'`: the controller reads the nonce
  from `meta[name="csp-nonce"]` and passes it to `EditorView.cspNonce`. Acceptance: a system test with `style-src 'self'
  'nonce-…'` records zero `securitypolicyviolation` events while the editor loads and the user types.
- **ASSETS-14** (MUST) Math is typeset with `katex.render` on DOM nodes, never `renderToString` followed by `innerHTML`.
  Acceptance: the strict-CSP system test with a math block records zero violations.
- **ASSETS-15** (MUST) The gem emits no inline `<script>` without the request nonce, no inline event-handler attributes, no
  `style` attributes and no `javascript:` URLs. Acceptance: a test renders every gem view and helper and finds no `script`
  without a nonce, no `on*` or `style` attribute and no `javascript:` URL.
- **ASSETS-16** (SHOULD) Diagrams offer an image mode (Mermaid's SVG rendered to a string and shown as `<img>` with a blob
  URL) for hosts whose `style-src` forbids inline styles. Acceptance: under the strict test policy a flowchart renders legibly
  in image mode.
- **ASSETS-17** (MUST) The README lists the CSP directives each feature needs (editor, math, inline diagrams, image diagrams,
  uploads), and the doctor warns when inline diagrams are enabled under a policy that blocks inline style attributes, naming the options
  (`style-src-attr 'unsafe-inline'`, image mode when ASSETS-16 ships, server-side SVG from `RENDER`).
  Acceptance: the README table exists, and a doctor test with a strict policy and inline diagrams prints the warning.

### CSS

- **ASSETS-18** (MUST) The gem ships prebuilt plain CSS on custom properties under its own class names, served by Propshaft
  or Sprockets with `stylesheet_link_tag`, so a host needs neither Tailwind nor an `@source` scan of the gem. Acceptance: a
  fresh app without Tailwind renders a styled viewer and editor.
- **ASSETS-19** (SHOULD) Tailwind 4 apps can take the gem's CSS through a tailwindcss-rails engine entry
  (`app/assets/tailwind/md/engine.css`), and cssbundling apps through the npm package's exported `md.css`, both producing the
  same rules as the plain stylesheet. Acceptance: a tailwindcss-rails app that imports `builds/tailwind/md` and a cssbundling app
  that imports `@md/rails/md.css` render the same viewer as the plain-CSS app.
- **ASSETS-20** (MUST) KaTeX's CSS and fonts are served from the gem's assets with working font URLs under both Propshaft and
  Sprockets in production. Acceptance: after production `assets:precompile` in both pipelines, a math page loads its KaTeX
  fonts with no 404.

## Developer experience notes

- **No new API for the common path.** ASSETS-01, 07, 13 and 18 need nothing from the developer beyond the install generator
  (`DX`). A newcomer never learns what a pin, a nonce facet or a precompile list is.
- **ASSETS-02** adds one concept: extensions import CodeMirror from the gem's re-export, not from `@codemirror/*`. That is one
  documented import path, and the doctor can detect the mistake (a host pin named `@codemirror/state`).
- **ASSETS-04 and 05** add an npm step (or managed copies) for bundler apps. The generator runs it with the app's package manager, and the doctor
  catches drift after `bundle update`, the most common upgrade trap (chadcn's copy approach has the same failure mode and solves
  it the same way).
- **ASSETS-12 and 16** add configuration (`mermaid_url`, `katex_url`, diagram mode). The defaults work, so only CSP-strict or
  CDN-minded hosts touch them.
- **ASSETS-17** turns a silent failure (an unstyled diagram) into a readable doctor message, which is the main DX gain of the CSP work.
- The budgets (ASSETS-08, 09) are invisible to developers but protect their readers: the public page stays as light as the
  viewer controller.

## Open decisions

- Ship the JavaScript as vendored files in the gem, as an npm package, or both? Recommendation: both, built from one source
  by one release workflow. Vendored files serve importmap, which is the Rails default and Papyro's setup, and the lazy
  Mermaid and KaTeX loads in every pipeline. The npm package serves bundlers, where it is what Vite Ruby and Shakapacker users
  expect. If publishing to npm cannot be ready for 0.1, ship chadcn's generator-copy approach for jsbundling first and switch
  without changing any DOM or identifiers. ASSETS-04 and ASSETS-05 hold under either answer.
- Under importmap, deliver CodeMirror as one prebuilt file (1 pin, 100.5 KiB gzipped) or as individual vendored pins
  (11 pins, 127.7 KiB)? Recommendation: one prebuilt file with re-exports (ASSETS-02). It is smaller, it needs no jspm
  resolution at install or upgrade, and the single-copy guarantee becomes a property of the gem.
- Ship Mermaid (108 files, 5.3 MB on disk) inside the gem, in a companion gem, or only as a host-provided URL?
  Recommendation: a companion gem (placeholder `md-mermaid`) that registers the vendored build. The core gem stays small,
  diagrams are one Gemfile line away, and Mermaid upgrades ship on their own schedule.
- Default diagram mode for hosts whose CSP blocks inline styles: inline SVG or image? Recommendation: inline SVG by default
  (selectable text, working links), with the doctor's warning (ASSETS-17) steering strict hosts to image mode or to
  server-side SVG from `RENDER` (shared with `RENDER`, which owns the viewer's diagram mode).
- Should the default editor highlight code inside fenced blocks (HTML, JS, CSS grammars, +71 KiB gzipped)? Recommendation: no
  for 0.1 (ASSETS-03). Add nested languages later as lazily loaded extensions, so prose writers never pay for them.
- Budget values in ASSETS-08 (110 KiB editor, 10 KiB viewer). Recommendation: accept them as starting points measured on
  2026-11-03, and revisit at 1.0 with real controller code. The 100.5 KiB build exports only what the editor uses; re-measure
  with the ASSETS-02 re-exports before fixing the editor budget.

## Sources

- https://github.com/rails/importmap-rails (accessed 2026-11-03)
- https://github.com/rails/propshaft (accessed 2026-11-03)
- https://github.com/rails/tailwindcss-rails (accessed 2026-11-03)
- https://github.com/rails/jsbundling-rails/tree/v1.3.1/lib/install (accessed 2026-11-03; the default esbuild, Rollup, Bun and webpack configs, read from the 1.3.1 gem)
- https://vite-ruby.netlify.app/guide/development.html (accessed 2026-11-03)
- https://codemirror.net/docs/ref/ (accessed 2026-11-03; `EditorView.cspNonce`, also in `@codemirror/view` 6.43.15 `dist/index.d.ts`)
- https://registry.npmjs.org/mermaid (accessed 2026-11-03; mermaid 12.3.0 package measured)
- https://registry.npmjs.org/katex (accessed 2026-11-03; katex 0.19.1 package measured)
- https://api.jspm.io/generate (accessed 2026-11-03; the generator error for mermaid 12.3.0)
- https://lexxy.dev/docs/ (accessed 2026-11-03)
- https://github.com/basecamp/lexxy (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith (accessed 2026-11-03)
- https://mermaid.js.org/config/usage.html (accessed 2026-11-03, through the rendering research note)
- `../reports/Markdown editor benchmark.md` and `../research_notes/Markdown editor benchmark/` (`editor_libraries.md`, `rendering_and_syntax.md`)
- chadcn repository decisions: `dev/decisions/js-bundlers.md`, `dev/decisions/sprockets.md`, `docs/compatibility.md` (doncan-orozco/chadcn)
