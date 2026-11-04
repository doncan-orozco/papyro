# PAPYRO: Papyro as the first consumer: requirements for the Md gem

Papyro is the gem's first and most demanding consumer, the same relationship it has with chadcn. This doc maps every
Papyro code path that touches markdown today onto the future gem (placeholder name `Md`, helpers `md:`): what the gem
replaces, what Papyro keeps and wraps, what moves into the `papyro_studio` engine, in which order, and how the team proves
that no article changes by accident. It also lists what Papyro asks of the gem so that adoption fits its conventions:
operations around every write, Pundit through an authorization hook, Phlex views, importmap, chadcn theme tokens. The
generic needs found here become gem requirements; the editorial ones stay in Papyro.

## Scope

This doc decides:

- the destination (gem, host, engine, or deletion) of each file that renders, stores, edits or uploads markdown today;
- the migration order from the current Redcarpet and House stack to the gem, and how each step is verified;
- the integration contract Papyro needs from the gem (the `PAPYRO-NN` requirements below).

Other areas own the details: the dialect and sanitizer profile belong to `render-and-viewer.md` (RENDER), the editing
surface to `editor-ux.md` (EDIT), the suggestion model and MCP to `agent-layer.md` (AGENT), the pin and package strategy
to `asset-pipeline-integration.md` (ASSETS), the token contract to `theming-and-customization.md` (THEME), the ERB and
Phlex front doors to `view-and-form-integration.md` (VIEWS). This doc states only what Papyro needs from those areas.

Out of scope (WON'T in this epic):

- Writing the renderer hardening itself. It is a Papyro bug fix that precedes the gem (see Findings, "Renderer hardening
  is a prerequisite"), tracked outside this epic.
- Schema changes. Papyro keeps `action_text_markdowns` and `article_translations.content` as they are.
- Moving translation content into per-locale `ActionText::Markdown` records, agent tokens, the audit log, `.md` twins and
  `/llms.txt`. These are Papyro features built on the gem, planned after it ships.
- Any change to Papyro or engine code. This item is research only.

## Questions

1. Which Papyro files does the gem replace, which does Papyro wrap, and which does it keep as they are?
2. What is the migration path, and how is stored and rendered content verified unchanged at each step?
3. Which Papyro needs are generic (the gem should serve every Rails app) and which are editorial (Papyro keeps them)?
4. What is the file-by-file map, with gem, host or engine as the destination of each file?
5. What does the renderer hardening still need before adoption, and why is it a prerequisite outside this epic?
6. What must the gem offer so that Papyro's conventions (operations, Pundit, Phlex, importmap, chadcn tokens) hold?
7. Which choices only a maintainer can make, and what does this research recommend for each?

## Findings

All code facts below were read on `main` at `54f288e7` (host) and `5958f43` (engine) on 2026-11-03. The benchmark report
(`../reports/Markdown editor benchmark.md`) and its research notes (`../research_notes/Markdown editor benchmark/`)
settle the direction (markdown text as the only source of truth, commonmarker 2.x, CodeMirror 6, four gem layers); this
section does not research those choices again.

### Papyro's markdown stack today

Papyro runs a Writebook-style stack (the pattern is described in
[Exploring Rails codebases: Writebook](https://kemenaran.winosx.com/posts/exploring-rails-codebases-writebook)):

- **Storage.** `has_markdown :body` (`lib/rails_ext/action_text_has_markdown.rb`) gives `Article` a polymorphic
  `has_one :markdown_body` on an `ActionText::Markdown` record (`action_text_markdowns.content`, a `text` column). The
  original locale's body lives there. Every other locale's body lives in `article_translations.content`, a plain `text`
  column next to the Mobility table-backend attributes (`title`, `slug`, `excerpt`, `cover_image_caption`). Body
  translations are therefore not Mobility attributes: `Articles::Operation::Update`, `Translate` and
  `Articles::Presenter::Show#content_markdown` read and write `translations.find_or_initialize_by(locale:)` by hand.
- **Editor.** The Studio "Write" tab is not a plain textarea, as the benchmark report says, but 37signals' House
  editor: `vendor/javascript/house.min.js` (24 KB, pinned as `house` in the host importmap and imported by
  `application.js`), a `house-md` custom element rendered by `ActionText::TagHelper#markdown_area`
  (`lib/rails_ext/action_text_tag_helper.rb`) through `PapyroFormBuilder` (`as: :markdown_area`) and a
  `house-md-toolbar` element in `Views::Studio::Articles::Edit::EditorFormComponent`. House styles live in
  `app/assets/stylesheets/house.css`; the empty-state placeholder is `house_placeholder_controller.js`; the Studio
  autosave controller listens to `house-md:change`. House was never published as a package and its licence could not
  be verified (research note `editor_libraries.md`; 37signals moved on to Lexxy, per
  [Lexxy 1.0](https://dev.37signals.com/lexxy-1-0/)).
- **Uploads.** `ActionText::Markdown::Uploads` adds `has_many_attached :uploads` to the markdown record.
  `ActionText::Markdown::UploadsController#create` locates the record from a signed GlobalID, authorizes `update?` with
  Pundit and calls `ActionText::Markdown::Uploads::Operation::Create`; the JSON answer gives House a permanent
  `/u/*slug` URL (`ActiveStorage::Sluggable` adds a random `slug` column to every attachment). `#show` redirects a slug
  to the blob. Stored markdown therefore contains `/u/...` URLs that must keep resolving forever. Translations have no
  markdown record of their own, so their images point at the original body's uploads.
- **Rendering.** `MarkdownRenderer` (`lib/markdown_renderer.rb`) subclasses `Redcarpet::Render::HTML` with Rouge
  highlighting, heading ids from `String#parameterize` plus a `#` link, and an image hook that wraps every image in a
  lightbox link and rewrites `/u/` URLs to relative paths. Since #336, `MarkdownRenderer.build` and `.render` pass the
  output through `MarkdownRenderer::Scrubber`, a `Rails::HTML::PermitScrubber` that adds tables, `details`, `figure`,
  heading `id`s and the lightbox attributes to the Rails safe list
  ([rails-html-sanitizer](https://github.com/rails/rails-html-sanitizer)). `config/initializers/markdown.rb` installs
  it as `ActionText::Markdown.renderer`. Redcarpet extensions: autolink, fenced code, tables, strikethrough,
  `lax_spacing`, `no_intra_emphasis`; footnotes, task lists and alerts are off.
- **Four call sites.** The public page (`Articles::Presenter::Show#content_html`, output with `raw` by
  `Views::Articles::Show::Content`); the Studio preview (`PapyroStudio::ArticlePreviewsController#create`, wrapped in
  `Mobility.with_locale`, injected by `write_preview_controller.js`, which also rewrites `/u/` URLs with `?preview=1`);
  `Articles::Operation::Publish#validate_publishable` (`model.body&.to_html` for the blank-body check); and
  `Articles::Service::ContentAnalysis` (word count, reading time, search text; used by
  `Components::Landing::ArticleCard`, `CleanupEmptyDraftsJob` and the Studio editor presenter), which calls
  `ActionText::Markdown#to_html` for the original body and the renderer directly for a translation.
- **Translation.** `Articles::Operation::Translate` sends the original title and body to Gemini and overwrites the
  target locale's title and `translations.content` in one transaction, with no review step.
- **Tests.** `test/lib/markdown_renderer_test.rb` (19 tests, including the #336 XSS cases),
  `test/models/action_text_markdown_test.rb`, the uploads operation and controller tests, and the engine's
  `article_previews_controller_test.rb`. There is no corpus of real article bodies with expected HTML.

### Renderer hardening is a prerequisite, and half of it is still open

The benchmark found three defects. #336 fixed two of them (unsanitized output on the public page and in the Studio
preview; unescaped image attributes). The third, path disagreement, is still there. `ActionText::Markdown#to_html`
renders with the scrubbed renderer and then sanitizes again with the default `Rails::HTML5::SafeListSanitizer`, which
strips what the custom scrubber allowed. A run of both paths on one sample (`bin/rails runner`, test environment,
2026-11-03) gave:

| Input | Public page and Studio preview | `to_html` (Publish, content analysis) |
|-------|--------------------------------|----------------------------------------|
| `# Año Θeta` | `h1 id="ano-eta"` with an `aria-hidden` anchor | `h1` without `id` or `aria-hidden` |
| GFM table | `table`, `thead`, `tr`, `td` | bare cell text, no table tags |
| `![alt](/u/abc "t")` | lightbox `data-action` and `data-lightbox-url-value` | plain link, lightbox attributes stripped |
| `Text[^1]` | `<a href="note">^1</a>` (footnotes off, parsed as a link) | same |
| `- [ ] task`, `> [!NOTE]` | literal text | same |

Today the damage is limited because the `to_html` callers only extract text, but it means Papyro still has two
pipelines, and the gem adoption must start from one. The same run shows the heading-id rule drops non-Latin letters
(`Θ`) and folds `ñ` to `n`, which matters for the anchor decision below. Because these are live defects in Papyro and
the gem's render core is meant to be extracted from a proven service (benchmark, "Recommended direction and phased
roadmap", Phase 0), the hardening is a prerequisite of adoption and is done in Papyro outside this epic: one entry point
for all four call sites, and `ActionText::Markdown#to_html` delegating to it instead of sanitizing again.

### File-by-file map

Destinations: **gem** means the gem replaces the file and Papyro deletes it when adoption ends; **host** and
**engine** mean the file stays in that repo, possibly rewritten to call the gem (the "Action" column says which);
**delete** means the file goes away without a gem counterpart.

| File (repo) | Today | Destination | Action |
|-------------|-------|-------------|--------|
| `lib/markdown_renderer.rb` (host) | Redcarpet subclass, heading ids, image hook | gem | Replaced by `Md.render`; its image hook and heading slugger become Papyro extensions passed to the gem (PAPYRO-09, PAPYRO-10); a thin facade stays during migration |
| `lib/markdown_renderer/scrubber.rb` (host) | allowlist scrubber | gem | Replaced by the gem's sanitizer profile; Papyro adds only the lightbox attributes through the gem's extension point |
| `config/initializers/markdown.rb` (host) | sets `ActionText::Markdown.renderer` | host | Rewritten as `Md.configure` (dialect, extensions, cache store, authorization hook) |
| `lib/rails_ext/action_text_markdown.rb` (host) | `ActionText::Markdown` record, Redcarpet options, `to_html`, `Uploads` concern | host | Kept as Papyro's storage model; `to_html` delegates to the gem; Redcarpet constants deleted |
| `lib/rails_ext/action_text_has_markdown.rb` (host) | `has_markdown` macro | host | Kept; plugs into the gem through its storage adapter seam (PAPYRO-07) |
| `lib/rails_ext/action_text_tag_helper.rb` (host) | `markdown_area` helper and form builder method rendering `house-md`, House toolbar helpers | delete | Replaced by the gem's form field (`f.markdown_field`) and Phlex editor component |
| `lib/rails_ext/active_storage_sluggable.rb` (host) | `/u/*slug` permanent upload URLs | host | Kept; the gem's upload adapter returns these URLs (PAPYRO-08) |
| `app/concepts/action_text/markdown/uploads/operation/create.rb` (host) | attaches an upload to the markdown record | host | Kept as the operation behind the gem's upload adapter |
| `app/controllers/action_text/markdown/uploads_controller.rb` and `app/views/action_text/markdown/uploads/create.json.jbuilder` (host) | upload endpoint, slug redirect | host | Kept; the JSON shape is adapted to what the gem editor expects, or the gem accepts Papyro's shape (PAPYRO-08) |
| `app/models/article.rb` (host) | `has_markdown :body`, Mobility attributes | host | Unchanged |
| `app/concepts/articles/presenter/show.rb` (host) | `content_html` with `MarkdownRenderer.render`, translation lookup | host | Kept; calls the gem with an explicit `locale:` and returns the gem's document instead of an HTML string (PAPYRO-06) |
| `app/views/articles/show/content.rb` (host) | `raw @presenter.content_html` in `.article-prose` | host | Renders the gem's Phlex viewer component; `raw` disappears (PAPYRO-17) |
| `app/assets/tailwind/domains/articles/reader.css` (host) | `.article-prose` styles (103 lines) | gem | Replaced by the gem's token-based viewer styles; Papyro keeps only editorial overrides (PAPYRO-19) |
| `app/concepts/articles/service/content_analysis.rb` (host) | word count, reading time, search text through `to_html` | host | Kept; reads `word_count`, `reading_time` and plain text from the gem's document (PAPYRO-11) |
| `app/concepts/articles/operation/publish.rb` (host) | blank-body check through `to_html` | host | Kept; checks the gem document's text (PAPYRO-11) |
| `app/concepts/articles/operation/update.rb` (host) | writes the body to the markdown record or the translation row | host | Unchanged; remains the only writer of article bodies (PAPYRO-14) |
| `app/concepts/articles/operation/translate.rb` (host) | Gemini overwrites the translation | host | Kept; later writes a pending suggestion through the gem's agent layer (PAPYRO-24) |
| `app/concepts/articles/validator/body.rb` (host) | 100,000-character limit | host | Kept; the gem must render that size within budget (PAPYRO-13) |
| `app/forms/papyro_form_builder.rb` (host) | `as: :markdown_area` branch | host | Branch rewritten to call the gem's field |
| `vendor/javascript/house.min.js`, `house` pin in `config/importmap.rb`, `import "house"` in `app/javascript/application.js` (host) | House editor | delete | Removed once the gem editor ships (PAPYRO-23) |
| `app/assets/stylesheets/house.css`, `app/javascript/controllers/house_placeholder_controller.js` (host) | House styles and placeholder | delete | Placeholder and empty state come from the gem editor (PAPYRO-23) |
| `app/javascript/controllers/lightbox_controller.js` (host) | image lightbox | host | Kept; the gem's image extension point emits its `data-action` (PAPYRO-09) |
| `app/controllers/papyro_studio/article_previews_controller.rb` (engine) | preview endpoint | engine | Kept as the Studio-mounted preview route, authorized with Pundit, rendering through the gem (PAPYRO-21; see open decisions) |
| `app/javascript/controllers/studio/articles/write_preview_controller.js` (engine) | Write/Preview tabs, `?preview=1` URL rewrite | engine | Reduced to Studio layout concerns; the preview fetch and injection come from the gem editor (PAPYRO-21) |
| `app/views/studio/articles/edit/editor_form_component.rb` (engine) | House toolbar and field | engine | Composes the gem's Phlex editor component with the title, tabs and autosave wiring (PAPYRO-17, PAPYRO-20) |
| `app/concepts/studio/articles/presenter/editor.rb` (engine) | autosave data actions (`house-md:change`), content analysis | engine | Listens to the gem editor's change event instead (PAPYRO-20) |
| `app/assets/stylesheets/papyro_studio/application.css` (engine) | `house-md .attachment` rule | engine | House rule deleted (PAPYRO-23) |
| `app/controllers/papyro_studio/translations_controller.rb` (engine) | runs `Translate` | engine | Unchanged until PAPYRO-24 |
| `test/lib/markdown_renderer_test.rb`, `test/models/action_text_markdown_test.rb` (host) | renderer and model tests | host | XSS and dialect cases move to the gem's suite; Papyro keeps tests of its extensions and the corpus check (PAPYRO-02) |

### Generic needs and editorial needs

| Need found in Papyro | Generic (gem) or editorial (host or engine) | Why |
|----------------------|---------------------------------------------|-----|
| One sanitized render path with an explicit locale, a document with HTML, headings, word count and reading time | gem | every app that shows user markdown needs it |
| Render cache keyed by digest, locale and renderer version | gem (Papyro picks the store) | generic; Solid Cache is Papyro's choice |
| Storage on a separate `ActionText::Markdown` record (`has_markdown`) | host, through a gem adapter seam | Writebook-specific pattern; the gem core works on any text attribute (benchmark design rule 3) |
| Body translations in `article_translations.content` | host | Papyro's data model |
| Image uploads to Active Storage from paste and drop | gem | every editor needs it ([Active Storage](https://guides.rubyonrails.org/active_storage_overview.html)) |
| Permanent `/u/*slug` upload URLs, signed GlobalID lookup | host, through the gem's upload adapter | Papyro's URL contract with already published articles |
| Lightbox around images | host extension on a gem image hook | Papyro's reader feature |
| Heading anchors with a `#` link | gem; Papyro may keep its legacy slugger through a hook | generic feature, Papyro-specific compatibility |
| Server preview identical to the public page | gem | the most cited trust signal (benchmark, "Writers converge") |
| Authorization of preview, upload and suggestion endpoints | host, through the gem's authorization hook | Papyro uses Pundit; other apps use other libraries |
| Publish, unpublish, schedule, trash, translation publishing | host | editorial workflow |
| Gemini translation and its prompt | host, writing through the gem's suggestion API | the gem never calls an LLM (benchmark design rule 4) |
| EN/ES side-by-side editing | engine, composing two gem editors | editorial layout |
| Prose and editor styles from theme tokens | gem | every themed app; Papyro supplies the chadcn tokens |

### Integration conventions Papyro must keep

- **Operations own writes.** `CLAUDE.md` and the `operation-pattern` skill require every mutation to go through an
  operation with explicit dependencies (`user:`, `locale:`), returning a payload hash. The gem's write APIs (upload,
  suggestion) must be plain Ruby calls that an operation can wrap, not logic that exists only inside a gem controller.
- **Explicit locale.** Papyro operations do not read `Current` or HTTP state; today the preview controller wraps the
  render in `Mobility.with_locale`, which the gem must not need ([Mobility](https://github.com/shioyama/mobility)).
- **Pundit.** Preview and uploads already call `authorize`; any gem endpoint mounted in Papyro must reach the same
  policies through a hook ([Pundit](https://github.com/varvet/pundit)).
- **Phlex.** Every Papyro and Studio view is Phlex; the gem must export Phlex components, not only ERB helpers
  ([Phlex](https://www.phlex.fun/)).
- **importmap.** Papyro and the engine use importmap without a JS bundler; the gem's controllers and CodeMirror pins
  must load that way ([importmap-rails](https://github.com/rails/importmap-rails)).
- **chadcn tokens.** The theme is one shadcn-format file (`app/assets/tailwind/theme/theme.css`); the viewer and editor
  must read its variables ([shadcn/ui theming](https://ui.shadcn.com/docs/theming)).

### Migration path

Each step leaves Papyro deployable, and no step rewrites stored markdown.

| Step | Where | Change | Verification |
|------|-------|--------|--------------|
| 0 | Papyro, outside this epic | Finish the hardening: one render entry point for the four call sites, `to_html` delegates to it | the #336 XSS tests plus a parity test (public page HTML equals `to_html` HTML for the same input) |
| 1 | Papyro | Capture the baseline: export every original body and every translation through the current renderer into a golden set, plus a curated fixture corpus (tables, images with `/u/` URLs, code, footnote-like text, raw HTML, Spanish text) | checksums of all content columns recorded; golden HTML, heading ids and word counts stored as test fixtures |
| 2 | gem 0.1, Papyro | Swap the render core behind the `MarkdownRenderer` facade and `Md.configure`; Papyro adds its image and slugger extensions | the corpus diff: every difference classified as an intended dialect change (footnotes, task lists, alerts, hardbreaks) or fixed; raw HTML usage counted before the switch, because commonmarker's `unsafe: false` drops it ([commonmarker](https://github.com/gjtorikian/commonmarker)) |
| 3 | gem 0.1, Papyro and engine | Public page and Studio preview render the gem's viewer component; `reader.css` shrinks to editorial overrides | preview HTML equals public HTML on the corpus; visual check in light and dark theme |
| 4 | gem 0.1, engine and host | Studio editor uses the gem's field over the real `article[body]` input; uploads go through Papyro's adapter; House is deleted | system tests: typing autosaves, paste and drop insert a `/u/` URL, EN and ES editors on one page; content checksums unchanged after a load-and-save of every fixture |
| 5 | gem 0.x, Papyro and engine | `Translate` writes a pending suggestion; Studio shows hunk-level review | operation test: an existing translation is unchanged until a human accepts |
| 6 | Papyro | Delete the facade, `lib/markdown_renderer*`, the tag helper and the Redcarpet and Rouge gems | the corpus check still green; `bin/ci` green |

Content is verified unchanged in three ways: stored bytes (checksums of `action_text_markdowns.content` and
`article_translations.content` before and after each deploy, since the gem never writes them on read), rendered output
(the golden corpus diff, with every difference explained), and derived text (word counts, reading times and heading ids
per article, compared to the baseline). GitLab's Banzai pipeline is the model for treating the renderer as a versioned
pipeline whose output changes only on purpose
([GitLab Flavored Markdown development guide](https://docs.gitlab.com/development/gitlab_flavored_markdown/)).

## Requirements

Grouped by migration need, then by convention. Each requirement is something Papyro needs from the gem, from its own
code, or from the migration; the owning area doc is named when the work is the gem's.

### Prerequisite and migration safety

- **PAPYRO-01** (MUST) Before adopting the gem, Papyro renders markdown through one sanitized entry point for the public
  page, the Studio preview, Publish and content analysis, and `ActionText::Markdown#to_html` delegates to it instead of
  sanitizing a second time; this hardening is done outside this epic. Acceptance: a test renders the same input through
  `to_html` and the public presenter and asserts equal HTML, including a table, a heading id and a lightbox image.
- **PAPYRO-02** (MUST) Papyro records a baseline before the swap: the current HTML, heading ids and word counts of a
  fixture corpus (tables, `/u/` images, code, raw HTML, footnote-like text, Spanish text such as `¿**Qué**?`) and of
  every stored body and translation. Acceptance: a rake task or test diffs the gem's output against the baseline and
  fails on any difference not listed as intended.
- **PAPYRO-03** (MUST) Adoption never rewrites stored markdown: reading, rendering, previewing or opening an article in
  the editor leaves `action_text_markdowns.content` and `article_translations.content` byte-identical until a person or
  an accepted suggestion changes them. Acceptance: checksums of both columns taken before and after a deploy and a
  load-and-save of every fixture in the editor are equal.
- **PAPYRO-04** (MUST) Raw HTML already present in stored articles is counted and resolved before the renderer swap,
  because the gem's safe default drops it. Acceptance: the baseline report lists every article that contains raw HTML,
  and each one is converted or accepted as changed before step 2 ships.
- **PAPYRO-05** (SHOULD) The swap to the gem's render core sits behind one configuration switch for its first release
  in production, so the previous renderer can come back without a data change. Acceptance: flipping the switch back
  restores the baseline HTML for the corpus.

### Storage, uploads and rendering hooks

- **PAPYRO-06** (MUST) The gem renders any string with an explicit locale (`Md.render(text, locale:)`), so Papyro's
  original body (an `ActionText::Markdown` record) and its translations (a plain column) take the same path. Acceptance:
  `Articles::Presenter::Show` renders an original body and a translation through the same gem call.
- **PAPYRO-07** (MUST) The gem's form field and editor work on Papyro's `has_markdown :body` through a storage adapter
  seam (read a string, write a string), without owning a table or changing Papyro's schema. Acceptance: the Studio editor
  saves an article body through `f.markdown_field :body` with no migration in the host.
- **PAPYRO-08** (MUST) The gem's upload support takes an app-supplied adapter, so Papyro keeps attaching files to the
  markdown record through `ActionText::Markdown::Uploads::Operation::Create`, authorizing with Pundit, and inserting
  permanent `/u/*slug` URLs. Acceptance: pasting an image in the Studio editor creates an attachment on the markdown
  record and inserts a `/u/` URL, and every `/u/` URL in the corpus still resolves.
- **PAPYRO-09** (MUST) The gem exposes an image extension point that lets Papyro keep its lightbox wrapper
  (`data-action` and `data-lightbox-url-value`) and relative `/u/` paths through the gem's sanitizer. Acceptance: a
  rendered `/u/` image carries the lightbox attributes and a relative `src`, and an injected `data-action` on other
  markup is still stripped.
- **PAPYRO-10** (MUST) The gem exposes a heading slugger hook, so Papyro can keep its current anchor ids (or migrate
  them on purpose, see the open decisions). Acceptance: the corpus's heading ids match the baseline when Papyro
  configures its legacy slugger.
- **PAPYRO-11** (MUST) The gem's rendered document gives plain text, word count and reading time, and Papyro's
  `Articles::Service::ContentAnalysis` and Publish's blank-body check use it instead of parsing HTML. Acceptance:
  content analysis tests pass and the corpus word counts equal the baseline or differ only where listed as intended.
- **PAPYRO-12** (SHOULD) The gem caches rendered documents by content digest, locale and renderer version through a
  store the app supplies, and Papyro wires it to Solid Cache. Acceptance: a second render of the same body is a cache
  hit, and a renderer version bump misses.
- **PAPYRO-13** (SHOULD) A body at Papyro's 100,000-character limit renders through the gem fast enough for a preview
  request. Acceptance: rendering a 100,000-character fixture takes under 100 ms on CI hardware.

### Papyro conventions the gem must respect

- **PAPYRO-14** (MUST) Every write the gem offers (upload, suggestion, apply) is a plain Ruby API with explicit
  arguments that a Papyro operation can wrap, and no Papyro controller calls a gem write API directly. Acceptance: in
  Papyro and the engine, calls to gem write APIs appear only under `app/concepts/**/operation/`.
- **PAPYRO-15** (MUST) Gem APIs take locale, user and record as arguments and never read `I18n.locale`,
  `Mobility.locale` or `Current`. Acceptance: rendering the same text with `locale: :es` inside
  `Mobility.with_locale(:en)` gives the Spanish result.
- **PAPYRO-16** (MUST) Every gem endpoint Papyro mounts (preview, upload, later suggestions) authorizes through an
  app-supplied hook that Papyro implements with its Pundit policies (`Studio::ArticlePolicy`). Acceptance: a request
  test shows a signed-in user without access gets the same refusal from the gem endpoint as from Papyro's own routes.
- **PAPYRO-17** (MUST) The viewer and the editor ship as Phlex components that Papyro's views and the engine's
  components render directly, with no ERB partial and no `raw` in Papyro code. Acceptance:
  `Views::Articles::Show::Content` and `Views::Studio::Articles::Edit::EditorFormComponent` render gem components, and
  a search for `raw @presenter.content_html` finds nothing.
- **PAPYRO-18** (MUST) The gem's JavaScript loads through importmap in both the host and the mounted engine, with one
  copy of `@codemirror/state` and `@codemirror/view` (the strategy is ASSETS's). Acceptance: `bin/importmap json` lists
  each CodeMirror core package once and `bin/importmap audit` passes.
- **PAPYRO-19** (MUST) The viewer and editor styles read the shadcn variables of Papyro's
  `app/assets/tailwind/theme/theme.css`, so Papyro drops `.article-prose` except for editorial overrides (the token
  contract is THEME's). Acceptance: `bin/rails theme:use` with another theme changes the viewer and editor colors with
  no Papyro CSS edit.
- **PAPYRO-20** (MUST) The gem editor keeps the real `article[body]` form field as its value and emits standard
  `input` and `change` events, so Studio autosave and Turbo navigation keep working. Acceptance: a system test types in
  the editor, waits for autosave, reloads, and finds the text.
- **PAPYRO-21** (MUST) The Studio preview uses the same render service and viewer as the public page, so preview and
  published HTML are equal; Papyro's `?preview=1` URL rewrite becomes a Papyro option of the viewer, not client code.
  Acceptance: for every corpus fixture, the preview response and the public article body have equal HTML apart from the
  preview URL parameter.
- **PAPYRO-22** (SHOULD) Several editor instances run on one page without shared global state, so the engine can show
  the EN/ES side-by-side view. Acceptance: a system test edits two locales on one page and each field saves its own
  text.

### Retirement and follow-on adoption

- **PAPYRO-23** (SHOULD) Papyro deletes the vendored House editor (`house.min.js`, its pin and import, `house.css`,
  the placeholder controller, the tag helper, the engine's House CSS rule) once the gem editor ships, and the gem
  contains no House code, since House's licence is unverified. Acceptance: a search for `house` under `app/`, `config/`,
  `lib/` and `vendor/` in both repos finds nothing markdown-related.
- **PAPYRO-24** (SHOULD) `Articles::Operation::Translate` writes the Gemini output as a pending, attributed suggestion
  through the gem's agent layer instead of overwriting the translation (the suggestion model is AGENT's). Acceptance: an
  operation test runs `Translate` on an article that has a translation and finds the stored translation unchanged plus
  one pending suggestion.
- **PAPYRO-25** (SHOULD) The gem's repository joins Papyro's flow workspace like chadcn: a `repos` entry in
  `.claude/workflow.yml` and a local bundle override to a sibling checkout. Acceptance: the flow `manifest check`
  passes with the gem listed.
- **PAPYRO-26** (COULD) Published articles get `.md` twins and an `/llms.txt` index built in Papyro on the gem's
  access to the stored markdown ([llms.txt](https://llmstxt.org/)). Acceptance: a GET on an article URL with `.md`
  returns the stored markdown of that locale with a `text/markdown` content type.

## Developer experience notes

Papyro is also the gem's first test of its newcomer cost: each seam Papyro needs is API surface every other app sees.

- PAPYRO-06 and PAPYRO-15 cost nothing new: `Md.render(text, locale:)` is the call a newcomer writes first anyway. An
  optional `locale:` with a documented default keeps the one-liner short for single-language apps.
- PAPYRO-07 (storage adapter) and PAPYRO-08 (upload adapter) add two extension points. A newcomer with a plain `text`
  column and Active Storage must never see them: the defaults handle that case, and the adapters are documented as
  "advanced" with Papyro's Writebook-style setup as the worked example.
- PAPYRO-09 and PAPYRO-10 (image and slugger hooks) are small blocks in `Md.configure`. They must fail loudly at boot
  (unknown hook name, wrong arity) rather than silently produce different HTML.
- PAPYRO-12 (cache) should work with `Rails.cache` by default, so an app gets caching without configuration.
- PAPYRO-16 (authorization hook) is the one hook every app with mounted endpoints must think about. The safe default is
  to deny until the hook is defined, with an error message that names the hook and shows a Pundit and a plain-Ruby
  example.
- PAPYRO-17 (Phlex components) must not push Phlex onto ERB users: the ERB helpers stay the documented front door
  (VIEWS owns that), and the Phlex classes are the same components exported for Phlex apps.
- PAPYRO-14, PAPYRO-18, PAPYRO-20 and PAPYRO-21 add no surface; they constrain how the gem is built.
- PAPYRO-02 to PAPYRO-05 are migration costs Papyro pays. Their tooling (export, diff, classify) is generic enough that
  the gem could ship a compare task for any app migrating from Redcarpet; that is a DX question for
  `developer-experience.md`, not a Papyro requirement.

## Open decisions

- Heading anchors: keep Papyro's current ids (`parameterize`, which drops `Θ` and folds `ñ`) through the slugger hook,
  or move to the gem's Unicode-preserving default and break `#fragment` links already shared. Recommendation: keep the
  legacy slugger during 0.x through PAPYRO-10, and decide at 1.0 with the baseline counts in hand, because a fragment
  cannot be redirected on the server and shared links are the cost.
- Where `ActionText::Markdown` and `has_markdown` live: in Papyro behind the storage adapter, or in the gem as an
  optional Writebook-style storage module. Recommendation: Papyro, because the gem core has no storage opinion (benchmark
  design rule 3) and the pattern is not a public Rails API; revisit if a second consumer asks for it.
- Body translations: keep `article_translations.content` as a plain column, or move each locale's body into its own
  `ActionText::Markdown` record with its own uploads. Recommendation: keep it for this migration, because PAPYRO-06 makes
  both shapes render the same way and a data migration adds risk with no reader-visible gain.
- When to delete House: with the gem editor's first release in Studio, or after a period with both editors behind a
  flag. Recommendation: with the first release, because two editors double the autosave and upload wiring, and the
  baseline checks of PAPYRO-03 cover the risk.
- Preview endpoint: keep `PapyroStudio::ArticlePreviewsController` calling the gem, or mount the gem's preview endpoint
  in the engine with the authorization hook. Recommendation: keep Papyro's controller, which keeps the Studio routes and
  Pundit call where they are and costs one line of rendering code.
- Raw HTML in existing articles: convert it by hand before the swap, or ask the gem for an opt-in raw HTML allowlist.
  Recommendation: convert by hand if the baseline count (PAPYRO-04) is small, because an opt-in raw HTML mode reopens
  the XSS surface the hardening closed.

## Sources

- https://github.com/gjtorikian/commonmarker (accessed 2026-11-03)
- https://github.com/rails/rails-html-sanitizer (accessed 2026-11-03)
- https://dev.37signals.com/lexxy-1-0/ (accessed 2026-11-03)
- https://kemenaran.winosx.com/posts/exploring-rails-codebases-writebook (accessed 2026-11-03)
- https://github.com/shioyama/mobility (accessed 2026-11-03)
- https://github.com/varvet/pundit (accessed 2026-11-03)
- https://www.phlex.fun/ (accessed 2026-11-03)
- https://github.com/rails/importmap-rails (accessed 2026-11-03)
- https://ui.shadcn.com/docs/theming (accessed 2026-11-03)
- https://guides.rubyonrails.org/active_storage_overview.html (accessed 2026-11-03)
- https://docs.gitlab.com/development/gitlab_flavored_markdown/ (accessed 2026-11-03)
- https://llmstxt.org/ (accessed 2026-11-03)
- `../reports/Markdown editor benchmark.md` (sections "Fix first", "commonmarker 2.x and a pinned GitHub-compatible
  dialect", "No Rails gem covers this", "Recommended direction and phased roadmap")
- `../research_notes/Markdown editor benchmark/rendering_and_syntax.md` and `editor_libraries.md` (House, Writebook)
