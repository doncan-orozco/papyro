# RAILS: Rails framework integration requirements for the Md gem

This area covers how the Md gem plugs into the Rails framework: which Rails and Ruby versions it supports, how a
markdown attribute lives in Active Record, how it coexists with and migrates from Action Text, how uploads ride on
Active Storage, how the editor and the viewer survive Turbo Drive, frames, streams and morphs, and which engine and
Zeitwerk conventions keep the gem invisible until it is used. It matters because the gem's first priority is developer
experience. A Rails developer judges a gem by whether it uses the framework they already know (a `text` column, Active
Storage, Turbo, I18n) or makes them learn a parallel one. Every integration point below names the Rails API it relies
on and how stable that API is, so the implementation knows where it stands on documented ground and where it does not.

## Scope

This doc decides:

- the supported Rails x Ruby matrix and the support policy;
- the Active Record contract: plain column, optional model macro, storage adapters, dirty tracking, newline
  normalization, rendered-HTML caching;
- coexistence with Action Text and the migration path from Trix or Lexxy HTML to markdown;
- the Active Storage contract for uploads: direct uploads, authorization, the URL form stored in the markdown, private
  services, variants, orphan cleanup;
- the Turbo lifecycle contract of the editor and the viewer (Drive cache, restoration visits, morphing, frames,
  streams);
- engine, Zeitwerk, routing, load-hook, I18n and Action Cable conventions.

It leaves to other areas: JavaScript and CSS delivery (importmap, jsbundling, Propshaft, Sprockets) to ASSETS; form
builder methods, view helpers and Phlex or ViewComponent wrappers to VIEWS; the final public API names and the install
generator to DX; the render pipeline, dialect and sanitizer to RENDER; the upload UX (paste, drag, alt-text prompt) to
EDIT; the suggestion and revision tables to AGENT; Papyro's own adoption steps to PAPYRO.

Out of scope (WON'T, for now):

- Registering Md as an Action Text editor (`config.action_text.editor`). Action Text editors write HTML into
  `ActionText::RichText`. Md stores markdown, so taking that slot would promise a storage format it does not have.
- Supporting Rails 7.2 or 8.0, or Ruby 3.2 (see the matrix below; an open decision can revisit it).
- Patching or subclassing `ActionText::RichText`, or defining constants in the `ActionText` namespace.
- Creating database tables from the core gem. Only optional layers do, through their generators (benchmark design
  rule 3).
- Real-time co-editing over Action Cable (Yjs). The benchmark puts it in phase 3.
- Server-proxied multipart uploads as the default path. They stay available as a fallback (RAILS-17).

## Questions

1. Which Rails and Ruby versions does the gem support, and what does each choice cost?
2. How does a markdown attribute live in Active Record: plain column or model macro, dirty tracking, normalization, and
   where the rendered HTML is cached?
3. How does the gem coexist with `has_rich_text`, plug into the Writebook and Papyro style `ActionText::Markdown`
   record, and what does a migration from Action Text rich text (Trix or Lexxy HTML) to markdown look like for an
   existing app?
4. How do uploads work with Active Storage direct uploads on any storage service (Disk, S3, GCS, Azure), and what URL
   ends up in the markdown text?
5. How does the editor survive Turbo navigation, cache restores, frames, streams and page morphs without leaks or lost
   text?
6. Which engine and Zeitwerk conventions does the gem follow, and how does it reach Action Cable and I18n?
7. For every integration point: which Rails API does it rely on, and how stable is that API?

## Findings

### 1. Rails and Ruby versions on 2026-11-03

The Rails maintenance policy gives each minor series bug fixes for one year and security fixes for two years after its
first release. When no new minor ships within a year, the previous series is extended until the next one
([rubyonrails.org/maintenance](https://rubyonrails.org/maintenance)). On the access date the page lists only two
series, 8.1 and 8.0:

| Series | Latest release | Required Ruby | Bug fixes until | Security fixes until |
|---|---|---|---|---|
| 8.1 | 8.1.4 (2026-09-24) | >= 3.2.0 | 2026-10-10, extended by the policy while 8.2 is unreleased | 2027-10-10 |
| 8.0 | 8.0.5.1 (2026-07-29) | >= 3.2.0 | ended 2026-05-07 | **2026-11-07** |
| 7.2 | 7.2.4 (2026-09-24) | >= 3.1.0 | not listed | not listed (the series is no longer on the page) |
| main | 8.2.0.alpha | **>= 3.3.5** | unreleased | unreleased |

Release numbers and Ruby floors come from the RubyGems versions API and the Rails gemspec on `main`
([RubyGems](https://rubygems.org/api/v1/versions/rails.json),
[rails.gemspec](https://raw.githubusercontent.com/rails/rails/main/rails.gemspec)). Ruby's branch page lists 4.0
(released 2025-12-25) and 3.4 in normal maintenance, 3.3 in security maintenance until 2027-03-31, and 3.2 end of life
since 2026-04-01 ([ruby-lang.org branches](https://www.ruby-lang.org/en/downloads/branches/)). commonmarker, the render
core's native dependency beyond the Nokogiri that Rails already brings, requires Ruby `>= 3.2, < 5`
([commonmarker.gemspec](https://raw.githubusercontent.com/gjtorikian/commonmarker/main/commonmarker.gemspec)).

Consequences:

- Rails 8.0 leaves security support four days after this doc's date, long before gem 0.1. Supporting it would add a CI
  column for a series nobody patches.
- Rails 7.2 is still in many apps (and got a 7.2.4 in September 2026), but it is off the maintenance page. Supporting it
  means a second code path wherever 8.x changed an API the gem touches (an inference: this doc did not diff the 7.2 and
  8.1 APIs). One known difference is the cache default: the Caching guide names Solid Cache as the default store of new
  Rails 8 apps ([Caching guide](https://guides.rubyonrails.org/caching_with_rails.html)). The adoption gain is real, but
  it lands on an unpatched framework.
- Ruby 3.2 is end of life, and the next Rails already requires 3.3.5. A `>= 3.3` floor costs nothing on Rails 8.1 and
  is looser than Rails `main`'s 3.3.5.
- Ruby 3.4 and 4.0 are what new apps run. Papyro runs Ruby 4.0.0 with Rails 8.1.4 (`.ruby-version`, `Gemfile.lock`).

#### Support matrix (proposed)

| Rails \ Ruby | 3.2 | 3.3 | 3.4 | 4.0 | Reason |
|---|---|---|---|---|---|
| 7.2 | no | no | no | no | Off the maintenance page; older defaults (no Solid Cache) and unaudited API differences would need a second code path |
| 8.0 | no | no | no | no | Security support ends 2026-11-07, before gem 0.1 |
| 8.1 | no | **CI** | **CI** | **CI** | Supported series until 2027-10-10; Ruby 3.2 is end of life |
| 8.2 (when released) | n/a | **CI** | **CI** | **CI** | Rails `main` requires Ruby >= 3.3.5 |
| main (edge) | n/a | allowed failure | allowed failure | allowed failure | Early warning for `to_markdown` and the Action Text editor changes |

The matrix costs three required CI cells today (Rails 8.1 by three Rubies) and six once 8.2 ships, plus an edge row.
Each extra Rails series adds three cells and the conditional code its API differences need.

### 2. Active Record: column, macro, dirty tracking, caching

Two storage shapes exist in the wild:

- **A plain `text` column.** Marksmith stores the field "as plain text in the database" and needs no model code
  ([Marksmith](https://github.com/avo-hq/marksmith)). Dirty tracking (`body_changed?`, `saved_change_to_body?`),
  validations, `normalizes` and JSON serialization work unchanged, because the attribute is a String.
- **A separate polymorphic record.** This is the Writebook pattern that Papyro copied. `has_markdown :body` declares
  `has_one :markdown_body, class_name: "ActionText::Markdown", as: :record, autosave: true, dependent: :destroy`
  (abridged: the real declaration carries more options) plus `with_markdown_body` preload scopes.
  `ActionText::Markdown < ActionText::Record` stores `content`, `name` and the polymorphic `record` in
  `action_text_markdowns`, with `touch: true` (`lib/rails_ext/action_text_has_markdown.rb`,
  `lib/rails_ext/action_text_markdown.rb` and `db/schema.rb` on Papyro's `main`). The parent's `body` reader always
  returns a record (it builds one when none exists), dirty state lives on that child (`markdown_body.content_changed?`),
  and every list view must preload or pay one query per row. Papyro runs Bullet for that reason. The research notes
  trace the pattern to Writebook (`publishing_platforms.md`, "Writebook").

Two findings shape the macro:

- **Name clashes are real.** Papyro already defines `has_markdown` on every Active Record model (through
  `ActiveSupport.on_load :active_record`) and `markdown_area` on `FormBuilder`. A gem that added the same names
  globally would silently replace its first consumer's code at boot, or be replaced by it, depending on load order.
- **Browsers submit textarea values with CRLF line breaks.** The HTML standard normalizes a textarea's API value to LF
  ([HTML standard, textarea](https://html.spec.whatwg.org/multipage/form-elements.html#the-textarea-element)). When it
  builds the submitted form data it then replaces every lone LF or CR with CR LF, for both URL-encoded and multipart
  bodies ([HTML standard, form submission](https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#converting-an-entry-list-to-a-list-of-name-value-pairs)).
  An editor that shows LF text while the server stores CRLF breaks the byte-exact contract at the centre of the
  benchmark's design: an agent's `old_str` copied from the editor would not match the stored text. Rails 7.1+
  `normalizes` is the documented place to fix it on assignment.

The benchmark settles the rendered-HTML cache key: content digest + locale + `RENDERER_VERSION`, with the Studio
preview skipping the cache. This doc adds the dialect and a digest of the app's render configuration (RAILS-08), so an
app that tightens its sanitizer does not keep serving HTML cached under the old allowlist. The research notes record
that Papyro renders on every request with no cache today (`rendering_and_syntax.md`). The Rails options are:

| Option | Rails API | Cost | When it fits |
|---|---|---|---|
| Render on read | none | 1-4 ms per 2-10 KB article (`rendering_and_syntax.md`) | previews, tiny apps |
| `Rails.cache.fetch` keyed by digest | `Rails.cache`, `ActiveSupport::Digest` | no schema change; Solid Cache is the Rails 8 default store ([Caching guide](https://guides.rubyonrails.org/caching_with_rails.html)) | default |
| Record cache key (`cache_key_with_version`) | `ActiveRecord::Integration` | invalidates on any column change, misses for unsaved previews, duplicates identical text | not recommended |
| Persisted `body_html` column | a migration in the app | schema change; must re-render when `RENDERER_VERSION` changes (Dev.to's stale Liquid HTML, per the benchmark) | feeds, search indexes, very hot pages |

A content-addressed key also serves previews of unsaved text and shares one entry between identical texts, such as
translations that have not diverged yet.

### 3. Action Text: coexistence and migration

`has_rich_text :content` stores HTML in `action_text_rich_texts` (polymorphic `record`, serialized `body`). It embeds
Active Storage blobs as `action-text-attachment` elements with signed GlobalIDs, preloads with
`with_rich_text_content_and_embeds`, and renders Trix through `form.rich_textarea`
([Action Text guide](https://guides.rubyonrails.org/action_text_overview.html)). Lexxy writes "the same canonical HTML
format", and on Rails 8.0 and 8.1 it replaces Trix in the rich text helper by setting `config.action_text.editor`
([Lexxy](https://github.com/basecamp/lexxy), [Lexxy docs](https://lexxy.dev/docs/)). Nothing in that stack conflicts
with a markdown attribute on another column or record, as long as the gem leaves `ActionText` alone. Papyro shows what
a gem must not ship: it defines `ActionText::Markdown`, `ActionText::HasMarkdown` and `ActionText::TagHelper#markdown_area`
inside Rails' namespace. That works for one app, but in a gem it would collide with the app's own copy (Papyro's) or
with a future Rails constant.

Rails is adding the migration tool itself. PR #56858, "Add `to_markdown` to Action Text, mirroring `to_plain_text`",
was merged into `main` on 2026-02-24. It converts headings, inline formatting, block quotes, code blocks, nested lists,
links, tables and `details`/`summary`, and checks link schemes against Loofah's allowed protocols. The built-in
attachables (`RemoteImage`, `ContentAttachment`, `ActiveStorage::Blob`, `MissingAttachable`) implement
`attachable_markdown_representation`; an `ActiveStorage::Blob` becomes a link with its caption or filename, and an app's
own attachables (mentions, embeds) are not covered, so the migration reports them. The author tested it by hand against
Trix and Lexxy markup ([rails/rails#56858](https://github.com/rails/rails/pull/56858)). The entry sits in the unreleased
section of `actiontext/CHANGELOG.md` on `main`, next to "Deprecate Trix-specific classes, modules, and methods" and
editor-element changes for Lexxy
([Action Text CHANGELOG](https://raw.githubusercontent.com/rails/rails/main/actiontext/CHANGELOG.md)). The PR has no
milestone, so the inference is that it ships with the next release cut from `main` (8.2.0.alpha today), not in an
8.1.x patch; RAILS-15's feature check does not depend on which release that is. On Rails 8.1 the common converter is
`reverse_markdown` 3.0.2 (2026-01-20, 106M downloads, depends on Nokogiri, **WTFPL** licence)
([RubyGems](https://rubygems.org/api/v1/gems/reverse_markdown.json)).

A migration for an existing app therefore looks like this:

1. Add the target (a `text` column, or the association adapter's record) in one schema-only migration, so
   `strong_migrations`-style checks pass.
2. Backfill in batches (`find_each` over `with_rich_text_content_and_embeds`). Convert with `to_markdown` when the
   running Rails has it, and with the fallback converter otherwise.
3. Rewrite attachments. An image blob becomes `![caption](stable upload URL)` and is attached to the record's uploads
   (Rails' default turns blobs into plain links, which loses the image). Remote images keep their URL. Unknown
   attachables are reported.
4. Write a report per record: elements that do not survive (colours, alignment, galleries, mentions) and a rendered
   diff count. The original rich text stays untouched.
5. Switch reads and forms to the markdown attribute. Drop `has_rich_text` and purge the rich text rows only in a later,
   separate step, after someone has reviewed the report. The purge removes the rich text's `embeds` attachments, so it
   must leave the blobs that step 3 attached to the record untouched.

### 4. Active Storage: uploads on any service

The documented browser-to-service path is `DirectUpload` from `@rails/activestorage`: `new DirectUpload(file, url)`,
then `upload.create((error, blob) => ...)`, where `url` is `rails_direct_uploads_url`. It emits progress and error
events (`direct-upload:progress`, `direct-upload:error` and others). S3 needs a CORS rule that allows `PUT` with
`Content-Type`, `Content-MD5` and `Content-Disposition` from the app's origins. GCS takes the same rule in its own keys,
and Disk needs none because it is same-origin. The guide does not cover Azure
([Active Storage guide](https://guides.rubyonrails.org/active_storage_overview.html)). Marksmith's `upload_url`
defaults to `rails_direct_uploads_url`, and Lexxy needs `@rails/activestorage` for attachments
([Marksmith](https://github.com/avo-hq/marksmith), [Lexxy docs](https://lexxy.dev/docs/)).

Points that decide the design:

- **The stock endpoint has no authorization.** `ActiveStorage::DirectUploadsController#create` calls
  `ActiveStorage::Blob.create_before_direct_upload!` with the client's metadata and returns a signed id and the upload
  URL. Nothing in it checks the user
  ([source](https://github.com/rails/rails/blob/8-1-stable/activestorage/app/controllers/active_storage/direct_uploads_controller.rb)).
  A gem that points its editor at it lets anyone who can load the form create blobs of any type and size.
- **What goes into the text matters more than how the file got there.** `url_for(blob)` gives
  `/rails/active_storage/blobs/redirect/:signed_id/:filename`. That URL is permanent and redirects to a service URL
  valid for five minutes. Proxy mode (`rails_storage_proxy_path`, or `resolve_model_to_route = :rails_storage_proxy`)
  streams the file through the app and suits CDNs. `public: true` services serve permanent bucket URLs (same guide). The
  guide calls signed ids permanent. The inference is that they stay valid only while the secret that signs them stays
  the same, so stored markdown full of signed-id URLs would break when that secret changes or the content moves to
  another app (RAILS-19 tests this). A public bucket URL ties the text to one host. Papyro keeps signed ids out of the
  text but not the app's host. Its upload endpoint (`ActionText::Markdown::UploadsController#create`) finds the record
  by signed GlobalID, authorizes `update?` with Pundit, and attaches the file, sent as a server-proxied multipart post
  and offered only on persisted records, to `has_many_attached :uploads` on the `ActionText::Markdown` child. Its JSON
  returns an absolute URL on `config.x.public_host` (`<public_host>/u/<slug>`), which the editor writes into the text,
  and `MarkdownRenderer#normalize_upload_url` strips the host back to `/u/<slug>` at render time. The `show` action
  skips authentication and authorization (`allow_unauthenticated_access only: :show`, `skip_authorization`) and
  redirects to the permanent stock `/rails/active_storage/blobs/redirect/:signed_id/...` URL with a one-year public
  cache header. Anyone with a slug can read any upload, and the redirect hands out a signed-id URL that never expires
  (Papyro `main`). An app with private records cannot accept that.
- **Ownership needs attachments.** Attaching the blob to the record (`has_many_attached`) gives purge on destroy, a way
  to find what a text references, and Rails' own preloading. Uploads from abandoned forms stay unattached. The guide's
  cleanup is a task over `ActiveStorage::Blob.unattached`, and it warns that the query is slow on big tables.
- **Variants only from trusted options.** `variant`, `representation` and `preprocessed: true` are the documented
  image APIs, and the guide says to pass only trusted transformation options. Markdown text and URL query strings are
  untrusted, so sizes must come from gem configuration. An app without `image_processing` must still render the
  originals.

### 5. Turbo: cache, morphing, frames and streams

- **Drive cache.** Turbo snapshots the page with `cloneNode(true)` before it renders the next one. That keeps the DOM
  and drops the listeners. Restoration visits show the snapshot, and application visits show it as a preview while
  they fetch. `turbo:before-cache` is the documented place to tear down third-party widgets, `data-turbo-temporary`
  removes elements from the snapshot, and `data-turbo-preview` on `html` marks a preview
  ([Turbo handbook: building](https://turbo.hotwired.dev/handbook/building)). A CodeMirror view left in the snapshot
  comes back as dead markup next to the textarea, and a controller that mounts again on `connect()` doubles the editor.
  The research notes record this pitfall (`editor_libraries.md`, Q3).
- **Stimulus lifecycle.** `connect()` and `disconnect()` always alternate and reuse the same controller instance. A new
  `body` from a Turbo visit, a frame update and a stream replace all disconnect the controller
  ([Stimulus lifecycle](https://stimulus.hotwired.dev/reference/lifecycle-callbacks)). So `disconnect()` must release
  everything `connect()` created, or each visit leaks one editor.
- **Morphing.** With `turbo-refresh-method` set to `morph`, Turbo 8 uses idiomorph to update only the nodes that
  changed. An element with `data-turbo-permanent` is not morphed, frames can refresh with `refresh="morph"`, and the
  `broadcasts_refreshes` model method of `turbo-rails`, plus `turbo_stream_from`, refreshes every open page when a
  record changes ([Turbo handbook: page refreshes](https://turbo.hotwired.dev/handbook/page_refreshes)). Calling
  `preventDefault()` on `turbo:before-morph-element` or `turbo:before-morph-attribute` keeps an element or an attribute
  as it is ([Turbo events](https://turbo.hotwired.dev/reference/events)). Without that, a broadcast refresh while a
  writer types would morph the server's older value into the textarea, and morphing the editor's own DOM would
  desynchronize CodeMirror from its state.
- **Frames and streams.** An editor rendered into a frame or by `turbo_stream.replace` gets only Stimulus callbacks:
  `turbo:load` and `DOMContentLoaded` do not fire for it (an inference from the Stimulus lifecycle page and Turbo's
  page-level `turbo:load`; RAILS-28 tests it). Viewer enhancements (Mermaid, KaTeX, heading links, lightbox) run again
  on reconnect and after a morph, so they must be idempotent.

### 6. Engine, Zeitwerk, routes, I18n, Action Cable

- `isolate_namespace` keeps an engine's controllers, helpers, routes and table names under its module. Engine routes
  live on their own route set. The host reaches them through the engine's route proxy, and code inside the engine
  reaches host routes through `main_app`. Engine `config/locales` load automatically, and settings that name host
  classes take strings that the engine resolves with `constantize` at call time
  ([Engines guide](https://guides.rubyonrails.org/engines.html)). Papyro's helper shows why the proxy matters: it
  branches on `respond_to?(:main_app)` to build its upload URL both from host views and from the papyro_studio engine,
  under a subdomain-constrained route set (`lib/rails_ext/action_text_tag_helper.rb`).
- Initializers run once, so they must not cache reloadable constants. `config.to_prepare` runs again after each reload,
  and objects that framework code caches belong in once-loaded paths. `bin/rails zeitwerk:check` verifies the naming
  ([Autoloading guide](https://guides.rubyonrails.org/autoloading_and_reloading_constants.html)). A gem loads its own
  `lib` with `Zeitwerk::Loader.for_gem`, which uses Zeitwerk's `GemInflector`
  ([Zeitwerk](https://github.com/fxn/zeitwerk)). The inference is that an app's Active Support `inflect.acronym "MD"`
  rule cannot rename the gem's constants. RAILS-29 tests that inference.
- `ActiveSupport.on_load` hooks (`:active_record`, `:action_view`, `:action_controller`, `:active_storage_blob`) let a
  gem extend the framework without loading it at boot, the way Action Text adds `has_rich_text`. Papyro uses one for
  its markdown record (`ActiveSupport.on_load :active_storage_attachment`).
- The core does not need Action Cable, because preview is a request, not a subscription. Only morph refreshes
  (`turbo-rails`) and the optional agent layer's live suggestion updates (AGENT) use it, and both are the app's choice.

### 7. Integration points and the stability of the APIs they use

| Integration point | Rails or Hotwire API | Stability |
|---|---|---|
| Plain column, dirty tracking | `ActiveModel::Dirty`, attribute methods | Public, stable for a decade |
| Newline normalization | `ActiveRecord::Base.normalizes` | Public since 7.1 |
| Model macro | `ActiveSupport.on_load(:active_record)`, `class_methods` in `ActiveSupport::Concern` | Public, stable |
| Association adapter | `has_one ... as:`, `autosave:`, `touch:`, `strict_loading:`, preload scopes | Public, stable |
| Papyro/Writebook record | `ActionText::Record` as a base class | Semi-private: Action Text's abstract base, not documented for app subclasses; the adapter must not depend on it |
| HTML cache | `Rails.cache.fetch`, `ActiveSupport::Digest.hexdigest` | Public, stable |
| Instrumentation | `ActiveSupport::Notifications.instrument` | Public, stable |
| Rich text migration (8.2+) | `ActionText::Content#to_markdown`, `attachable_markdown_representation` | New and unreleased on 2026-11-03; used behind a feature check |
| Rich text migration (8.1) | `ActionText::RichText#body`, Nokogiri, optional `reverse_markdown` | Public; the converter is third-party |
| Action Text editor slot | `config.action_text.editor` | New and changing on `main`; not used (see Scope) |
| Direct uploads (browser) | `DirectUpload` from `@rails/activestorage`, `direct-upload:*` events | Public, documented in the guide |
| Direct uploads (server) | `ActiveStorage::Blob.create_before_direct_upload!`, `Blob#signed_id`, `Blob.find_signed` | Public methods, stable since Rails 6 |
| Serving files | `rails_blob_path`, `rails_storage_proxy_path`, `resolve_model_to_route` | Public, documented |
| Ownership | `has_many_attached`, `ActiveStorage::Blob.unattached`, `purge_later` | Public, documented |
| Variants | `variant`, `representation`, `variable?`, `preprocessed:` | Public; `preprocessed` since 7.1 |
| Record lookup for uploads | `to_signed_global_id`, `GlobalID::Locator.locate_signed` | Public, stable (Papyro uses them) |
| Drive cache | `turbo:before-cache`, `data-turbo-temporary`, `data-turbo-preview` | Public, documented |
| Morphing | `turbo-refresh-method`, `turbo:before-morph-element`, `turbo:morph-element`, `data-turbo-permanent` | Public since Turbo 8 (turbo-rails 2.0) |
| Lifecycle | Stimulus `connect` and `disconnect` | Public, stable |
| Engine | `Rails::Engine`, `isolate_namespace`, route proxy, `main_app` | Public, stable |
| Reloading | `config.to_prepare`, `Zeitwerk::Loader.for_gem`, `zeitwerk:check` | Public, stable |
| I18n | engine `config/locales`, `I18n.t` | Public, stable |
| Migration and maintenance tasks | `ActiveRecord::Batches#find_each`, Rake tasks in the engine's `lib/tasks` | Public, stable |
| Orphan cleanup job | `ActiveJob::Base`, `ActiveStorage::Blob.unattached` | Public, documented; the app picks the queue adapter |
| Morph refresh broadcasts | `broadcasts_refreshes`, `turbo_stream_from` (turbo-rails), Action Cable | Public, in the page-refreshes handbook; the app's choice, not the core's |
| Generators | `Rails::Generators::Base`, `railties:install:migrations` | Public, stable (Engines guide) |

The "since" versions in this table (7.1, Rails 6, Turbo 8) come from the frameworks' release history and were not
re-fetched for this doc; the CI matrix (RAILS-01) is what verifies them.

## Requirements

The requirements are grouped by framework component. Names such as `Md::Document` and the `md.` key prefix follow the
placeholder gem name; DX owns the final names.

### Versions and dependencies

- **RAILS-01** (MUST) The gem supports Rails 8.1 and every later released minor series on Ruby 3.3, 3.4 and 4.0, and
  its gemspec says so (`required_ruby_version` `>= 3.3`, `railties` `>= 8.1`). Acceptance: CI runs the dummy-app suite
  on every required cell of the support matrix for each released Rails series (three cells while 8.1 is the only one),
  every cell is green, and the gemspec bounds match the matrix.
- **RAILS-02** (SHOULD) CI also runs the suite against Rails `main` on every Ruby of the matrix as an allowed failure.
  Acceptance: the CI config has an edge job on Rails `main` that reports its result without blocking merges.
- **RAILS-03** (MUST) The README states the support policy: a Rails series is dropped when rubyonrails.org ends its
  security support and a Ruby branch when ruby-lang.org marks it end of life, only in a minor release, announced in the
  CHANGELOG. Its first screen names the minimum Rails and Ruby, so an app on Rails 7.2 or 8.0 learns it before Bundler
  fails. Acceptance: the README has a "Supported versions" section with the matrix and this policy, its opening
  section names the minimum Rails and Ruby, and the CHANGELOG entry of every release that drops a version names it.
- **RAILS-04** (MUST) Active Record, Active Storage, Action Text and Action Cable are optional Rails frameworks: the
  gem depends only on `railties`, `actionpack` and `actionview`, and enables each integration from that framework's
  load hook when the app loads it. Acceptance: an app booted with only `action_controller/railtie` can call
  `Md.render` and render the editor field, and its boot loads none of the optional frameworks.

### Active Record

- **RAILS-05** (MUST) A plain `text` (or `string`) column works with no model code: the form field, the preview and
  `Md.render` accept any attribute value. Acceptance: a dummy model with a bare `body` column and no macro saves
  through the editor and renders on its show page.
- **RAILS-06** (SHOULD) An optional model macro declares a markdown attribute without changing its type: the reader
  still returns the stored String, dirty tracking stays Rails' own, and the macro adds one reader for the rendered
  document (`body_document`, returning `Md::Document`). Acceptance: with the macro, `post.body` is a String,
  `post.body_changed?` behaves as it does without the macro, and `post.body_document.html` is HTML-safe.
- **RAILS-07** (MUST) Markdown is stored with LF line breaks: the macro uses `normalizes` to turn CRLF and lone CR into
  LF on assignment, and the README shows the same one-liner for apps without the macro. Acceptance: assigning text with
  CRLF line breaks stores LF only, and saving through the editor form then reloading produces no diff against the
  editor's text.
- **RAILS-08** (MUST) Rendered HTML is cached through `Rails.cache` with no schema change, under a key made of the
  content digest, the locale, the dialect, the renderer version and a digest of the app's render configuration
  (sanitizer allowlist, filters, options; RENDER owns which settings exist), never the record's cache key. The preview
  path skips the cache. Acceptance: rendering the same text twice performs one render; changing the renderer version,
  the locale or the sanitizer allowlist misses the cache; and a test with the null store still renders.
- **RAILS-09** (SHOULD) Every render emits an `ActiveSupport::Notifications` event (`render.md`) carrying the byte
  size, the locale and whether the cache hit. Acceptance: a subscriber in the dummy app receives one event per render
  with those payload keys.
- **RAILS-10** (MUST) Storage goes through a small documented adapter with two built-ins: the column (the default) and
  an association adapter for a separate record that holds the text (the Writebook and Papyro `ActionText::Markdown`
  shape), configured by association name and text attribute. Acceptance: Papyro's existing `action_text_markdowns` rows
  read and write through the association adapter with no migration, and the README documents the adapter interface.
- **RAILS-11** (MUST) The association adapter never adds one query per record: it defines a preload scope (the
  equivalent of `with_rich_text_body`), respects `strict_loading`, and the rendered-document reader uses the preloaded
  record. Acceptance: rendering a list of twenty records through the preload scope adds one query, and Bullet reports
  nothing in the dummy app.
- **RAILS-12** (COULD) An opt-in persisted HTML column stores the rendered HTML with the renderer version, and is
  re-rendered when the text or the renderer version changes. Acceptance: bumping the renderer version and running the
  provided task re-renders every stale row and leaves current ones untouched.

### Action Text

- **RAILS-13** (MUST) The gem coexists with Action Text: it defines no constant in the `ActionText` namespace, never
  patches `ActionText::RichText`, never changes `config.action_text.editor`, and works on a model that also has
  `has_rich_text` (with Trix or Lexxy). Acceptance: a dummy model with `has_rich_text :summary` and a markdown `body`
  saves both through one form, and `ActionText.constants` is identical with and without the gem loaded.
- **RAILS-14** (MUST) A migration task converts an Action Text attribute to a markdown attribute in batches. Its dry
  run writes a per-record report of lost elements and changed attachments, and the task leaves the rich text rows
  untouched until a separate purge step. Acceptance: on a fixture corpus of Trix and Lexxy HTML the dry run writes only
  the report, the real run fills the markdown attribute, a second run changes nothing, and the rich text rows are still
  there afterwards.
- **RAILS-15** (MUST) The migration converts with `ActionText::Content#to_markdown` when the running Rails defines it,
  and on Rails 8.1 with a fallback converter that is not a runtime dependency of the gem. When neither is available it
  stops before any write and prints the exact Gemfile line to add. Acceptance: the task's tests pass on Rails 8.1 and
  on Rails `main`, on Rails 8.1 without the fallback the task exits non-zero and prints that line, and the gemspec's
  runtime dependencies list no HTML-to-markdown converter.
- **RAILS-16** (MUST) The migration turns image attachments into markdown images that point at stable upload URLs and
  attaches their blobs to the record's uploads, instead of the plain link that Rails' default blob representation
  gives. Acceptance: an image `action-text-attachment` in the fixture corpus becomes image syntax whose URL serves the
  same blob, the blob is attached to the migrated record, and after the separate purge step the image URL still serves
  the blob.

### Active Storage

- **RAILS-17** (MUST) Uploads go from the browser to the storage service through Active Storage direct uploads
  (`DirectUpload` from `@rails/activestorage`, pointed at the gem's endpoint of RAILS-18) and work on Disk, S3, GCS and
  Azure with no gem setting beyond the service's CORS rule, which the README shows per service. A server-proxied
  upload stays available for services without CORS. Acceptance: a system test uploads an image on the Disk service,
  and the release checklist records an upload on S3 (or a MinIO container in CI), on GCS and on Azure (or an Azurite
  container in CI).
- **RAILS-18** (MUST) The gem's direct-upload endpoint authorizes before it creates a blob. It calls one app-supplied
  hook with the user, the record (found by signed GlobalID when persisted, or a new instance of the signed record
  class on a new-record form), the attribute and the action (`:upload` here, `:read` in RAILS-21). It enforces a
  configurable content-type allowlist and byte limit on the declared metadata, rechecks the content type after the
  upload (a blob that fails the recheck is purged and never attached), and with no hook configured it refuses every
  upload with 403 and logs a message that shows the block to add. The editor never posts to the unauthenticated stock
  `rails_direct_uploads_url`. Acceptance: a request the hook rejects gets 403 and creates no blob, an app with no hook
  gets 403 and that log line, a file over the limit or of a declared type outside the allowlist gets 422, and a file
  declared as `image/png` whose bytes are HTML is purged and never attached.
- **RAILS-19** (MUST) The markdown text stores a stable, app-relative upload URL served by a gem route. The URL embeds
  no signed id, host, service hostname or expiring token. The route answers with the blob's expiring service URL
  (redirect mode) or streams the file (proxy mode) as `resolve_model_to_route` says, and never redirects to the
  permanent stock `/rails/active_storage/blobs/...` routes. Acceptance: after changing the secret that signs blob ids,
  and after moving blobs from Disk to S3 with a mirror service, every image URL in the stored fixture texts still
  serves its file, and no response's `Location` header is a `/rails/active_storage/` URL.
- **RAILS-20** (MUST) Uploaded blobs are attached to the owning record and purged when it is destroyed. On a new-record
  form, which has no GlobalID yet, the endpoint returns the blob's signed id, the form carries it in a hidden field,
  and the record attaches it on create only if the same user uploaded it (Papyro today offers uploads only on
  persisted records). Acceptance: an upload on a new-record form is attached after the first save, a signed id from
  another user's upload is rejected on save, and destroying the record enqueues its purge.
- **RAILS-21** (MUST) Reading an upload calls the authorization hook with the `:read` action (RAILS-18), so uploads of
  private records stay private: their responses carry `Cache-Control: private` and never expose a permanent signed-id
  URL. A long public cache header is sent only when the hook allows a signed-out `:read` and the response does not
  point at an expiring URL (proxy mode or a public service); a redirect to an expiring service URL is never cached
  longer than that URL lives. Acceptance: a signed-out visitor gets 404 for an image of a private record, a signed-in
  reader's response is `private` and any `Location` it has expires, and a public record's image in proxy mode carries
  a public cache header.
- **RAILS-22** (SHOULD) A provided job purges blobs that the gem's upload endpoint created and that are still
  unattached after a configurable age (two days by default). An optional reconciliation detaches uploads that the saved
  text no longer references. Acceptance: the job purges a blob created three days ago and never attached, and keeps one
  created an hour ago.
- **RAILS-23** (SHOULD) The viewer serves resized images through `representation`, with sizes taken only from gem
  configuration and never from the markdown text or the URL, and it falls back to the original when the blob is not
  variable or `image_processing` is missing. Acceptance: with `image_processing` absent the page renders originals
  without error, and a size passed in the upload URL's query string is ignored.

### Turbo and the Stimulus lifecycle

- **RAILS-24** (MUST) The editor survives the Drive cache: on `turbo:before-cache` it writes its text into the real
  textarea and removes its own DOM, so the snapshot holds only the textarea, and `connect()` always rebuilds from the
  textarea value. Acceptance: a system test that types, visits another page, then goes back and forward ten times ends
  with exactly one editor instance showing the typed text and no console errors.
- **RAILS-25** (MUST) `disconnect()` releases everything `connect()` created: the editor view, listeners, observers,
  timers and pending preview requests. Acceptance: after twenty Turbo visits between two pages with an editor, the
  gem's test-mode instance counter reads one, and a heap snapshot shows no detached editor views.
- **RAILS-26** (MUST) During a morph refresh the editor element is not morphed while it holds unsaved changes (the
  editor cancels `turbo:before-morph-element` for it), and it re-syncs from the server value when it is pristine.
  Acceptance: a `broadcasts_refreshes` refresh triggered from another session while a writer types keeps the typed
  text, and the same refresh on an untouched editor shows the new server value.
- **RAILS-27** (MUST) Viewer enhancements (diagrams, math, heading links, lightbox) are idempotent across reconnects and
  morphs. Acceptance: after a morph refresh and a back-forward visit, an article with one Mermaid fence shows exactly
  one rendered diagram.
- **RAILS-28** (SHOULD) The editor and the viewer work when rendered inside a Turbo Frame or by a Turbo Stream action,
  relying only on Stimulus callbacks and never on `turbo:load` or `DOMContentLoaded`. Acceptance: in a system test, an
  editor inserted by a stream replace mounts, uploads and submits.

### Engine, Zeitwerk, routes, I18n and Action Cable

- **RAILS-29** (MUST) The gem is a Rails engine with `isolate_namespace Md`. It loads its `lib` with its own Zeitwerk
  loader, keeps every constant under `Md`, and reaches Rails only through `ActiveSupport.on_load` hooks, so requiring
  it loads no framework early. Acceptance: `bin/rails zeitwerk:check` passes in a dummy app that has an
  `inflect.acronym "MD"` rule, and a boot test shows that no Active Record load hook ran because of the gem.
- **RAILS-30** (MUST) Configuration is reload-safe: settings that name app code take strings or callables resolved at
  call time, and no initializer caches a reloadable constant. Acceptance: in development, an edit to the app's upload
  authorization hook or custom render filter takes effect on the next request without a server restart.
- **RAILS-31** (MUST) Every method the gem adds to `ActiveRecord::Base`, `FormBuilder` or the view helpers carries
  the gem's prefix (DX picks it), so it never takes a name an app may already define (Papyro defines `has_markdown`
  and `markdown_area`). If a method with the gem's name already exists, the gem refuses at boot to overwrite it, with
  a message that names the method and the fix. Acceptance: the gem loads into Papyro with its current `has_markdown`
  and `markdown_area` untouched, and a dummy app that predefines the gem's macro name gets the boot error.
- **RAILS-32** (SHOULD) The engine mounts itself at a configurable path with an opt-out for manual mounting, and every
  URL the gem's helpers build uses the engine's route proxy, so they work from host views, from inside another mounted
  engine and under subdomain constraints. Acceptance: the upload and preview URLs are correct when the field renders
  in a host view and in a view of a second engine mounted under a subdomain constraint.
- **RAILS-33** (MUST) The core gem ships no migrations; optional layers copy theirs with an install generator.
  Acceptance: `bin/rails railties:install:migrations` copies nothing from the core gem, and the agent layer's generator
  is the only source of Md tables.
- **RAILS-34** (MUST) Every user-facing string of the editor and the viewer comes from I18n keys under `md.` in the
  engine's `config/locales`, in English and Spanish. The JavaScript gets its strings from the server's I18n through
  data attributes, not from a second translation file. Acceptance: a test finds every key in both locales, and
  switching `I18n.locale` to Spanish changes the toolbar labels and the upload errors.
- **RAILS-35** (MUST) `Md.render` takes the content locale as `locale:`. When it is omitted it falls back to
  `I18n.locale`, and the README warns that this is the request's UI locale, so background jobs and translation views
  must pass the content's locale. Acceptance: rendering with `locale: :es` inside an English request passes `:es` to
  the render core's locale hook and caches under the Spanish key.
- **RAILS-36** (SHOULD) Each gem feature that relies on Action Cable (morph refreshes through `broadcasts_refreshes`,
  the agent layer's live suggestion updates) says so in the README, and the editor degrades to request-only behaviour
  when no cable consumer exists (RAILS-04 already makes Action Cable optional for the core). Acceptance: the README's
  Action Cable section names every such feature, and the editor page of a dummy app without `action_cable/engine`
  loads with no JavaScript error.

## Developer experience notes

What a newcomer pays for each group, from cheapest to most expensive:

- **Versions (RAILS-01 to RAILS-04).** Nothing to learn. The cost falls on the maintainers: three CI cells (six once
  8.2 ships) and an edge job. An app on Rails 7.2 or 8.0 cannot install the gem at all, so RAILS-03 puts that on the
  README's first screen instead of leaving Bundler to report a resolution error.
- **Active Record (RAILS-05 to RAILS-12).** The default path needs no model code: a `text` column and a form field.
  The macro is one line and changes nothing about the attribute; its only new surface is the `body_document` reader.
  The association adapter is for apps that already keep the text in a separate record (Papyro, Writebook-style apps),
  and it costs a configuration block, not a migration. Caching is invisible, but RAILS-09's `render.md` event name and
  payload keys are public API from 0.1, so renaming them later is a breaking change. The persisted column (RAILS-12)
  would cost a migration and a re-render task, so it stays a COULD.
- **Action Text (RAILS-13 to RAILS-16).** Coexistence costs nothing. The migration costs one command, with a dry run
  first. The error a developer will meet is "Rails 8.1 needs a converter", and RAILS-15 makes the task answer it with
  the exact Gemfile line to add.
- **Active Storage (RAILS-17 to RAILS-23).** The authorization hook (RAILS-18, RAILS-21) is the one piece of app code
  the gem requires, because the gem cannot guess who may upload. It is a block with four arguments (user, record,
  attribute, action): the agent layer's `|user, record, action|` hook (benchmark design rule 4) plus the attribute, so a
  Pundit, Action Policy or plain-Ruby app fills both in the same way. Without it the endpoint refuses with a message
  that shows the block to add (RAILS-18), never silently. The CORS rule is a copy-paste per service. Stable URLs
  (RAILS-19) add one gem route that the developer never calls directly. RAILS-22 adds one job and one age setting with a
  default, so a newcomer only schedules the job.
- **Turbo (RAILS-24 to RAILS-28).** No API at all: a developer should never have to write `turbo:before-cache` code
  for the editor. The whole cost sits in the gem's system tests.
- **Engine conventions (RAILS-29 to RAILS-36).** Invisible when they work. RAILS-31's boot error is the only message a
  developer may see, and it names the clashing method and how to rename it or opt out. RAILS-32 adds a mount-path
  setting and an opt-out that most apps never touch. RAILS-34's `md.` keys are overridable surface, so their names are
  a semver promise. RAILS-35's `locale:` keyword is the one trap: omitting it renders with the UI locale, so the
  README's first `Md.render` example passes it.

## Open decisions

- Version floor: Rails 8.1+ on Ruby 3.3+, or also Rails 8.0 (security support ends 2026-11-07) and Rails 7.2 (off the
  maintenance page) for wider adoption. Recommendation: Rails 8.1+ and Ruby 3.3+. Both older series are unpatched before
  gem 0.1 ships, and each adds three CI cells and conditional code. Revisit only if a real adopter on 7.2 asks.
- Macro name and loading: add the macro to every model through a load hook (like `has_rich_text`), or require an
  explicit `include` per model. Recommendation: a load hook with a name other than `has_markdown`, chosen together with
  the gem name in DX. Papyro can then move off its own `has_markdown` one model at a time, and newcomers get the
  `has_rich_text`-style one-liner they expect.
- URL form stored in the markdown text: the gem's stable route (RAILS-19), the blob redirect URL, or the service URL for
  public services. Recommendation: the stable route. It survives key rotation, service moves and exports, and it is the
  only form that can keep private records private (RAILS-21).
- HTML-to-markdown converter on Rails 8.1: `reverse_markdown` as an optional dependency (WTFPL licence, Nokogiri), a
  converter vendored in the gem, or a migration task that requires Rails 8.2. Recommendation: use `to_markdown` when it
  exists, and otherwise ask for `reverse_markdown` in the app's Gemfile once a maintainer accepts its licence. Do not
  vendor a converter that Rails 8.2 makes redundant.
- Persisted HTML column (RAILS-12): whether to offer it, and when. Recommendation: not in 0.1. The digest-keyed cache
  covers Papyro's pages, and the column can wait for an adopter that needs HTML in a feed or search index.
- Morph policy for a dirty editor whose server value changed (RAILS-26): keep the local text, take the server's, or
  show a conflict. Recommendation: keep the local text and let the `lock_version` conflict check on save report the
  clash, which matches the benchmark's optimistic-locking plan.
- Action Text editor slot on Rails 8.2: whether a later release registers Md with `config.action_text.editor` for apps
  that want markdown input with HTML storage. Recommendation: no. It contradicts markdown as the stored format, and
  Lexxy already serves that need.

## Sources

Benchmark inputs cited above: `docs/features/markdown-editor/reports/Markdown editor benchmark.md` and the research
notes in `docs/features/markdown-editor/research_notes/Markdown editor benchmark/` (`editor_libraries.md`,
`publishing_platforms.md`, `rendering_and_syntax.md`). Papyro code was read on `main` at 54f288e7.

- https://rubyonrails.org/maintenance (accessed 2026-11-03)
- https://rubygems.org/api/v1/versions/rails.json (accessed 2026-11-03)
- https://raw.githubusercontent.com/rails/rails/main/rails.gemspec (accessed 2026-11-03)
- https://raw.githubusercontent.com/rails/rails/main/RAILS_VERSION (accessed 2026-11-03)
- https://www.ruby-lang.org/en/downloads/branches/ (accessed 2026-11-03)
- https://raw.githubusercontent.com/gjtorikian/commonmarker/main/commonmarker.gemspec (accessed 2026-11-03)
- https://guides.rubyonrails.org/active_storage_overview.html (accessed 2026-11-03)
- https://github.com/rails/rails/blob/8-1-stable/activestorage/app/controllers/active_storage/direct_uploads_controller.rb (accessed 2026-11-03)
- https://guides.rubyonrails.org/action_text_overview.html (accessed 2026-11-03)
- https://github.com/rails/rails/pull/56858 (accessed 2026-11-03)
- https://raw.githubusercontent.com/rails/rails/main/actiontext/CHANGELOG.md (accessed 2026-11-03)
- https://rubygems.org/api/v1/gems/reverse_markdown.json (accessed 2026-11-03)
- https://guides.rubyonrails.org/caching_with_rails.html (accessed 2026-11-03)
- https://guides.rubyonrails.org/engines.html (accessed 2026-11-03)
- https://guides.rubyonrails.org/autoloading_and_reloading_constants.html (accessed 2026-11-03)
- https://github.com/fxn/zeitwerk (accessed 2026-11-03)
- https://turbo.hotwired.dev/handbook/building (accessed 2026-11-03)
- https://turbo.hotwired.dev/handbook/page_refreshes (accessed 2026-11-03)
- https://turbo.hotwired.dev/reference/events (accessed 2026-11-03)
- https://stimulus.hotwired.dev/reference/lifecycle-callbacks (accessed 2026-11-03)
- https://html.spec.whatwg.org/multipage/form-elements.html#the-textarea-element (accessed 2026-11-03)
- https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#converting-an-entry-list-to-a-list-of-name-value-pairs (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith (accessed 2026-11-03)
- https://github.com/basecamp/lexxy (accessed 2026-11-03)
- https://lexxy.dev/docs/ (accessed 2026-11-03)
