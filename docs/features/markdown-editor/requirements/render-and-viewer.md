# RENDER: rendering pipeline and viewer requirements for the Md gem

This area covers the two bottom layers of the gem: the **render core**, which turns a markdown string into safe HTML
plus metadata (table of contents, plain text, excerpt, reading time), and the **viewer**, which shows that HTML with
prose styles, code highlighting and lazily loaded diagrams and math. Every other layer depends on them. The editor's
preview, the published page, feeds, email and the agent review UI all call the same render core. If it is unsafe,
the gem ships stored XSS to every app that installs it, and if it disagrees with itself, writers stop trusting the
preview. The benchmark already settled the big choices: markdown is the only source of truth, rendering uses commonmarker 2.x
with raw HTML off, and one sanitized pipeline serves every surface
(`../reports/Markdown editor benchmark.md`, sections "Fix first" and "commonmarker 2.x and a pinned GitHub-compatible
dialect"). This doc turns those choices into a pipeline, a dialect contract, an allowlist, an extension API and a
test corpus that the gem can be built and audited against.

## Scope

This doc decides:

- the render entry point, its options and the `Md::Document` it returns;
- the commonmarker options the gem pins, and the order of the pipeline stages;
- the versioned dialect (v1, v2, rejected syntax) and how a dialect version is selected and frozen;
- the sanitizer allowlist, URL protocol policy and link policy;
- the extension API for app-defined syntax;
- heading anchors, the table of contents, footnote ids and id collisions;
- cache keys and instrumentation;
- locale-aware typography, word count and reading time;
- the output variants the gem renders;
- the viewer's markup contract, code highlighting, lazy Mermaid and KaTeX, Turbo behaviour and accessibility;
- the hostile-input corpus and the parser-abuse budget the gem's CI enforces.

Other areas own these topics, and this doc only points at them:

- `THEME` owns the names of the design tokens that the prose and highlight styles read.
- `ASSETS` owns how the viewer's JavaScript, Mermaid and KaTeX reach the browser (importmap pins, the npm package,
  Propshaft and Sprockets).
- `VIEWS` owns the helper, Phlex component and ViewComponent surfaces that wrap the viewer markup defined here.
- `RAILS` owns storage of rendered HTML in columns, Action Text adapters and the model validators.
- `EDIT` owns the editor and its preview UX; the preview calls the render core defined here.
- `AGENT` owns how pending suggestions render inert URLs; it reuses this pipeline with a stricter link policy.
- `PAPYRO` owns Papyro's migration from Redcarpet, including its lightbox and anchors.

Out of scope (WON'T, for every release this research plans):

- **Raw HTML passthrough.** Raw HTML in markdown is scrubbed by the parser and never trusted.
- **MDX, Liquid, Markdoc and generic directives** (`:::note`). These are dialect-specific syntaxes that hurt portability.
- **A WYSIWYG document model.** The rendered HTML is never edited and turned back into markdown.
- **Feed and email documents.** The gem renders the article body for them (the static variant). The app builds the
  RSS/Atom XML, the email layout and CSS inlining, and the meta tags.
- **Open Graph image generation, AMP and PDF output.**
- **Server-side diagram rendering in the core** (mermaid-cli, Kroki). The gem only offers a hook (RENDER-39).
- **A built-in remote-image proxy.** The gem offers a URL rewriter hook instead (RENDER-49).

## Questions

1. Which commonmarker 2.x options does the gem pin, and which may an app change?
2. Which syntax does each dialect version accept (v1, v2, rejected), and how does a document get pinned to one?
3. What does the sanitizer allow (tags, attributes, classes, URL protocols), where does it run, and what must it never allow?
4. What does the extension API look like for an app that adds its own syntax (mentions, embeds, a lightbox), and how
   does it stay safe and cacheable without regex over the source?
5. How are heading anchors and the table of contents built, and how do ids stay stable across locales and releases
   and unique when several documents share a page?
6. Which inputs make up the cache key, and what does the gem cache by itself?
7. How does locale-aware typography work for English and Spanish, and what is off by default?
8. Which output variants does the gem render, and which does it leave to the app?
9. What does the viewer ship: markup contract, highlighting, lazy diagrams and math, Turbo safety and accessibility?
10. Which XSS and parser-abuse cases does the corpus cover, and how does CI enforce them?

## Findings

### commonmarker 2.x is the parser, with a pinned option set

The benchmark and its research notes settle the parser choice. commonmarker ≥ 2.10.1 wraps comrak, which passes the
full CommonMark 0.31.2 and GFM suites. It scrubs raw HTML and dangerous links unless `unsafe` is set, and 2.10.1
fixed a native stack overflow on deeply nested input (GHSA-c4fj-h48v-9fxp) (`../research_notes/Markdown editor
benchmark/rendering_and_syntax.md` §2-3; commonmarker README and CHANGELOG). Its defaults are not CommonMark's,
though, and three of them changed between minor releases. So the gem pins every option rather than inheriting them:

| Option (group) | commonmarker default | Gem value | Why |
|---|---|---|---|
| `unsafe` (render) | `false` | `false`, not configurable | Raw HTML and `javascript:` links are scrubbed by the parser, before the sanitizer runs as a second line |
| `hardbreaks` (render) | `true` | `false` | CommonMark soft breaks; `true` turns every newline into `<br>` |
| `smart` (parse) | `false` | `false` | English-only quotes; locale typography is the gem's own pass (RENDER-33) |
| `header_ids` (extension) | `""` (on) | `nil` (off) | The anchor markup changed in 2.9.0 (`id` moved onto the heading, anchor moved to the end), so the gem owns its anchors (RENDER-26) |
| `max_nesting_depth` (parse) | `1000` | `1000`, configurable down | Raises `Commonmarker::NestingDepthExceededError`; the gem wraps it (RENDER-04) |
| `tasklist_classes` (render) | `false` | `true` | Gives task items a stable class |
| `alert_style` (render) | `"specific"` | `"specific"` | `div.markdown-alert` matches GitHub's classes; `"semantic"` emits `aside.admonition` |
| `footnotes`, `alerts` (extension) | `false` | `true` (v1) | Dialect v1 |
| `math_code` (extension) | `false` | `true` (v2) | ```` ```math ```` and ``$`…`$`` only |
| `math_dollars` (extension) | `false` | `false` | "$5 and $10" must stay prose (benchmark dialect table) |
| `shortcodes`, `table`, `tasklist`, `strikethrough`, `autolink` | `true` | `true` | GFM, as GitHub renders it |
| `syntax_highlighter` plugin | theme `base16-ocean.dark` | theme `""` (CSS classes) | Inline styles break a strict `style-src` CSP and ignore the app theme |

Sources: commonmarker README (options and plugins tables) and CHANGELOG (2.0.0 default merging, 2.0.3 alerts,
2.3.0 `tasklist_classes`, 2.9.0 anchor markup, 2.10.1 advisory). commonmarker also exposes the AST that the extension
API needs. The Ruby side has `walk`, `each`, `insert_before`/`insert_after`, `append_child`, `delete`,
`source_position`, `string_content` and writable `url`/`title`/`fence_info`/`alert_type`. The native extension also
defines a node constructor taking a type symbol and keyword arguments, for example `:link` with `url:` and `title:`,
`:text` with `content:`, `:alert` with `type:`, and `:raw` with `content:` (`ext/commonmarker/src/node.rs`). A `:raw`
node is emitted verbatim. Anything an extension emits must therefore pass the final sanitizer, which is why the
sanitizer runs last.

### Pipeline order

GitLab's Banzai design is the reference: parse, then HTML filters, then a database cache. html-pipeline 3 uses the
same order: text filters, then convert, then sanitize, then node filters (benchmark §"commonmarker 2.x";
html-pipeline README). html-pipeline runs its node filters *after* sanitizing, so a buggy node filter can add unsafe
markup. The gem reverses that order and sanitizes last:

1. **Guard.** Check the byte size against `max_bytes` and the encoding (UTF-8 only). comrak replaces NUL with U+FFFD.
2. **Parse** with the dialect's pinned options.
3. **Built-in AST passes**: heading anchors and the TOC, figures, the optional Obsidian alert aliases, marking
   Mermaid and math fences, footnote id prefixing, locale typography, and metadata (plain text, excerpt, word count,
   features used).
4. **App AST extensions**, in registration order.
5. **Render HTML** (commonmarker, highlighter theme `""`).
6. **HTML filters**: the built-in ones (link `rel`, lazy images, table wrapper, alignment classes), then the app's.
7. **Variant transform** (`:static` only).
8. **Sanitize**: the final allowlist, made of the base list plus additions the extensions declared and the gem validated.
9. **Wrap** in `Md::Document`. The HTML is marked `html_safe` here, and nowhere else.
10. **Cache** under `Document#cache_key`, when the caller asked for caching.

### Dialect versions

The benchmark fixed what v1 and v2 contain. GFM, footnotes, GitHub alerts and figures go in v1. Mermaid and math
fences go in v2. Directives, MDX, Liquid and raw HTML are rejected, because LLMs, GitHub, GitLab, Obsidian and comrak
share that subset (benchmark dialect table; research notes §1 and §6). This doc adds the rows the benchmark left open
and the rule that a released dialect is frozen. Notion versions its markdown API the same way (`markdown_version` in
the benchmark's agent section).

| Element | Syntax | Dialect | Render |
|---|---|---|---|
| CommonMark core | CommonMark 0.31.2, incl. setext headings | v1 | Soft breaks stay soft (`hardbreaks: false`) |
| Tables | GFM pipes | v1 | `table` wrapped in a scrollable, focusable region; alignment as `md-align-*` classes |
| Task lists | `- [ ]` / `- [x]` | v1 | Disabled checkboxes with `task-list-item` class |
| Strikethrough | `~~x~~` | v1 | `del` |
| Autolinks | GFM extended autolinks | v1 | Link policy applies (RENDER-17) |
| Footnotes | `[^1]` + `[^1]: …` | v1 | Section at the end; ids prefixed per render (RENDER-29) |
| Alerts | `> [!NOTE]`, TIP, IMPORTANT, WARNING, CAUTION | v1 | `div.markdown-alert`; title localized EN/ES (RENDER-46) |
| Obsidian callout aliases | `> [!info]`, `> [!danger]` … | v1 option, off by default | AST pass maps them onto the five GitHub types (RENDER-11) |
| Figures | Image alone in a paragraph; title becomes the caption | v1 | `figure` + `figcaption` |
| Heading anchors | Automatic | v1 | Gem-owned slug (RENDER-26) |
| Fenced code | Info string with language | v1 | Highlighted with CSS classes; unknown language stays escaped |
| Emoji shortcodes | `:+1:` | v1 | Unicode emoji (commonmarker `shortcodes`) |
| Mermaid | ```` ```mermaid ```` | v2 | Escaped source in `pre.md-diagram`; Mermaid 12 lazy, strict (RENDER-43) |
| Math | ```` ```math ````, ``$`…`$`` | v2 | Marked code; KaTeX lazy, `trust: false` (RENDER-44) |
| Dollar math | `$…$`, `$$…$$` | Rejected by default; app opt-in (RENDER-13) | Prices in prose would turn into math |
| Embeds | Bare URL alone on a line | v2 candidate, through an extension | Link card with click-to-load; no iframe in the HTML (RENDER-50) |
| Foldable callouts | `> [!note]-` | Later | `details`/`summary` |
| Superscript, subscript, underline, spoiler, `==highlight==`, `++insert++` | comrak extensions | Rejected | Not portable to GitHub or Obsidian |
| Description lists, wikilinks, `>>>` multiline quotes | comrak extensions | Rejected (an app can add wikilinks as an extension) | Not GFM |
| Front matter | `---` block | Rejected | Metadata lives in model fields; a block would render as a rule and text |
| Raw HTML | Any | Rejected | Scrubbed by the parser, then by the sanitizer |
| Directives, MDX, Liquid, Markdoc | `:::note`, `<Comp/>`, `{% tag %}` | Rejected | Dialect-specific |

A dialect version is a frozen option set plus a frozen list of built-in passes. Adding syntax creates a new version,
and v2 is a superset of v1. The renderer records the dialect in `Document#dialect` and in the cache key. Changing the
default dialect of an existing app is a migration, so the gem offers a diff task (RENDER-12) instead of silently
re-rendering every record.

### Sanitizer: allowlist draft and what must never be allowed

Rails' default SafeList drops tables, `id`s, task-list inputs, figures, footnote sections and every `aria-*`/`data-*`
attribute, as verified against rails-html-sanitizer 1.7.1 (research notes §0). A markdown gem therefore needs its own
list. The draft below lists only what the gem's own renderer and passes emit. Raw HTML is off, so nothing else can
legitimately appear.

| Tag | Attributes allowed | Emitted by |
|---|---|---|
| `br`, `hr`, `em`, `strong`, `del`, `blockquote`, `ul`, `li` | none | CommonMark/GFM |
| `p` | `class` (`markdown-alert-title` only) | Paragraphs, alert titles |
| `ol` | `start` | Ordered lists |
| `h1`-`h6` | `id` | Heading anchor pass |
| `a` | `href`, `title`, `rel`, `id`, `class`, `aria-label`, `data-footnote-ref`, `data-footnote-backref` | Links, anchors, footnotes |
| `img` | `src`, `alt`, `title`, `loading`, `decoding`, `width`, `height` | Images |
| `figure`, `figcaption` | none | Figure pass |
| `pre`, `code` | `class` (`language-*`, `md-diagram`), `data-math-style`, `data-md-diagram` | Code, Mermaid, math |
| `span` | `class` (highlighter classes only) | Syntax highlighter |
| `table`, `thead`, `tbody`, `tr` | none | Tables |
| `th`, `td` | `class` (`md-align-*`) | Tables; comrak's `align` becomes a class |
| `div` | `class` (`markdown-alert*`, `md-table`), `role` (`region`, `note`), `tabindex` (`0`), `aria-label` | Alerts, table wrapper |
| `input` | `type` (`checkbox` only), `disabled`, `checked`, `class` | Task lists |
| `section` | `class` (`footnotes`), `data-footnotes` | Footnotes |
| `sup` | `class` | Footnote references |
| `details`, `summary` | none (later dialect) | Foldable callouts |

The exact footnote, alert and task-list markup is pinned by fixtures taken from comrak's output in the spike, not
from memory. Allowed URL protocols are `http`, `https` and `mailto` for `href`, plus relative and fragment URLs. For
`src` only `http`, `https` and relative URLs are allowed, and no `data:` (rails-html-sanitizer 1.4.4 fixed a data-URI
bypass, CVE-2022-23518).

The gem must never allow these. The list doubles as the boot-time validation for extension additions (RENDER-15):

- `script`, `style` (tag and attribute), `iframe`, `object`, `embed`, `form`, `button`, `meta`, `base`, `link`, `srcdoc`, `formaction`, every `on*` attribute;
- `svg` and `math` (foreign content). rails-html-sanitizer 1.6.1 fixed foreign-content bypasses where disallowed
  tags were stripped instead of pruned (CVE-2024-53986, CVE-2024-53987). Version 1.7.1 fixed SVG `use` elements
  pointing at external documents (GHSA-cj75-f6xr-r4g7), and 1.7.2 fixed allowlists leaking between concurrent calls
  with different `tags:` (GHSA-h7wh-q2qr-458c). The gem therefore sanitizes in prune mode with a dedicated, frozen
  scrubber instance per configuration, and never passes per-call `tags:` to a shared sanitizer;
- `noscript`, `mglyph` and `malignmark`, which rails-html-sanitizer now rejects outright (CVE-2024-53988, CVE-2024-53989);
- `name`. It enables DOM clobbering of `document` named properties, and OWASP recommends removing or namespacing
  user-controlled `id`/`name` (DOM Clobbering Prevention Cheat Sheet).

Link policy is a post-render filter, not a renderer option, so the preview and the public page share it (research
notes §3). Google defines `rel="ugc"` for user-generated content and `nofollow` for links a site does not vouch for
(Google, qualify outbound links). The gem cannot know whether an author is trusted, so the default is
`nofollow ugc noopener`. An app relaxes it per call for trusted authors.

### The extension API: AST passes, not regex

The benchmark asks for an extension API for app-defined syntax (mentions, issue references, embeds, Papyro's
lightbox) built on AST passes rather than regex. Precedents:

| System | Extension unit | Runs on | Lesson for the gem |
|---|---|---|---|
| html-pipeline 3 | `TextFilter`, `ConvertFilter`, `NodeFilter` with a `Selma::Selector` and `handle_element` | Text, then HTML | Selector-based HTML filters are easy to write, but html-pipeline runs them after sanitizing, so they can reintroduce unsafe markup |
| Hugo render hooks | A template per element (`render-link.html`, `render-image.html`, `render-heading.html`, `render-codeblock.html`, `render-blockquote.html`, …), scoped per output format | One element type | Override rendering of one element, fall back to the default otherwise; per-output-format hooks match our variants |
| GitLab Banzai | Ordered filters with a DB cache | HTML | Ordered stages plus a cache keyed on the pipeline |
| commonmarker AST | `walk`, node constructors, `insert_before`/`append_child`, `delete` | Typed nodes | Text matching happens inside `:text` nodes only, so code spans, code blocks and URLs are never touched |

The gem's contract, with `Md` as the placeholder name:

```ruby
class MentionsExtension < Md::Extension
  extension_name :mentions
  version 1                                    # bump when output changes; part of the cache key
  allow "a", attributes: %w[data-user-id]      # validated at boot against the never-allow list

  def prepare(document, context)               # optional: collect first, so the app runs one query
    context[:handles] = context.scan_text(document, /@(\w{2,30})/).map { _1[1] }
  end

  def transform(document, context)
    users = context.fetch(:users).call(context[:handles])   # app-supplied lookup, batched
    context.replace_text(document, /@(\w{2,30})/) do |match|
      user = users[match[1]] or next                        # nil keeps the text as it was
      Commonmarker::Node.new(:link, url: "/@#{user.username}", title: user.name)
        .tap { _1.append_child(Commonmarker::Node.new(:text, content: match[0])) }
    end
  end
end

Md.configure { |config| config.extensions.use MentionsExtension }
Md.render(post.body, locale: :es, context: { users: ->(handles) { User.where(username: handles).index_by(&:username) } })
```

`context.replace_text` walks `:text` nodes only. It skips code spans, code blocks, math, link URLs and, by default,
text that is already inside a link, then splits the text node around each match and inserts the returned nodes.
Regex is therefore allowed only on the content of one text node, never on the source. It runs under a per-extension
`Regexp` timeout (Ruby's `Regexp.timeout`), so a catastrophic pattern raises instead of hanging a request. HTML-level
needs, such as Papyro's lightbox that wraps images in a link with `data-action`, use an `Md::HtmlFilter` with a CSS
selector, like html-pipeline's NodeFilter, but before the sanitizer. Each extension contributes its name, version and
allowlist additions to the cache key. An app extension cannot widen the allowlist with anything on the never-allow
list.

### Heading anchors, TOC and ids

GitHub's anchor slugs lowercase the text, turn spaces into hyphens, drop punctuation, keep non-ASCII letters ("Greek
Letter Θ!" becomes `greek-letter-θ`) and suffix duplicates with `-1`, `-2`. Papyro's `parameterize` drops Θ and turns
ñ into n, so its anchors do not match GitHub's (research notes §1). comrak's own anchor markup changed in
commonmarker 2.9.0. The gem therefore turns `header_ids` off and builds ids in an AST pass with a slug function it
owns, pins and tests. Ids are a security surface as well as a UX one. A user-controlled `id` can clobber `window`
named properties, and `name` can clobber `document` ones (OWASP). Two documents on one page also collide: Papyro's
Studio shows EN and ES side by side, and both have `fn-1`. Hence a per-render `id_prefix` for footnotes and, when
asked, headings (RENDER-29).

### Cache keys

GitLab caches rendered HTML after the filter pipeline. Dev.to's Liquid tags compile at save and stay stale until a
re-save, which is the trap a renderer version avoids (benchmark). commonmarker itself changed output in minor
releases (2.0.0 option merging, 2.9.0 anchors), so the cache key has to include the parser version as well as the
gem's own renderer version. An article of 2-10 KB renders in about 1-4 ms uncached (research notes §2), so caching is
an optimization. It is not required for correctness, and it stays opt-in.

### Locale-aware typography

comrak's `smart` option produces English curly quotes only (commonmarker README). The RAE's *Diccionario panhispánico
de dudas* prescribes angular quotes first in Spanish, then English quotes, then single quotes for nested quotes:
«Antonio me dijo: "Vaya 'cacharro' que se ha comprado Julián"» (RAE, comillas). Locale typography is therefore a gem
pass over text nodes keyed on `locale:`. It ships rules for `en` and `es` and leaves unknown locales untouched, since
English quotes would be wrong for them. The source markdown is never changed. Only the output changes, because
agents patch the source by exact string (benchmark).

### Output variants

| Variant | Gem renders | App does | Evidence |
|---|---|---|---|
| Web page, preview | `:web` (default): full markup, anchors, `data-*` hooks for the viewer | Layout, meta tags | Benchmark: preview parity is the main trust signal |
| RSS / Atom item body | `:static`: absolute URLs from `base_url:`, no anchor links, no `data-controller`, diagrams and math fall back to their source | The feed XML; RSS 2.0 `description` carries entity-encoded HTML | RSS 2.0 spec |
| Email body | `:static`, same as feeds | Layout and CSS inlining (for example premailer) | SVG works in about 40% of email clients, so client-rendered diagrams cannot be relied on (caniemail) |
| Open Graph / meta description | `Document#excerpt(length: 160)`: plain text from the first prose paragraphs | `og:description` and `meta name="description"` tags | OGP: "A one to two sentence description"; Google truncates snippets to the device width and wants unique descriptions |
| Plain text | `Document#plain_text`: from the AST, no markup | Search indexing, notifications | Research notes §4: excerpts from the AST, never truncated HTML |
| Markdown twin, `/llms.txt` | Nothing to render: the source is the twin | The routes (`PAPYRO`, `AGENT` areas) | Benchmark agent section |
| Server-side diagram or math images | A hook only (RENDER-39) | Jobs running mermaid-cli or Kroki | Headless Chromium is about 280 MB (research notes §5) |

### Viewer: lazy diagrams and math

The current Mermaid release is 12.3.0, loaded as ESM with `startOnLoad: false` and `mermaid.run({ nodes,
suppressErrors })`. Its `securityLevel` values are `strict` (the default: labels encoded, clicks disabled),
`antiscript`, `loose` and `sandbox`. The `secure` key list, whose default is `secure`, `securityLevel`, `startOnLoad`,
`maxTextSize`, `suppressErrorRendering` and `maxEdges`, can only be changed through `mermaid.initialize`. The config
schema says it exists to stop diagram directives from overriding a site's security defaults, and directives are
deprecated in favour of front-matter `config`; the corpus tests both routes (RENDER-43).
`maxTextSize` defaults to 50,000 and `maxEdges` to 500 (Mermaid usage, directives and config schema docs). The
current KaTeX release is 0.19.1. KaTeX's `trust` option defaults to `false`, which gates `\href`, `\url`,
`\includegraphics`, `\htmlClass`, `\htmlId`, `\htmlStyle` and `\htmlData`. `maxSize` defaults to `Infinity`, so
`\rule{500em}{500em}` is uncapped unless the gem sets it. `maxExpand` defaults to 1000, and `htmlAndMathml` output
(the default) adds MathML for screen readers (KaTeX options). KaTeX's auto-render scans text for delimiters and lists
`$$` and `\(`/`\[` by default (KaTeX auto-render). The gem must not use it: it would rescan prose for `$` and undo
the dialect's choice to keep "$5 and $10" as text. The viewer renders only the elements the parser marked as math.

### Hostile-input corpus

The corpus combines four sources. The first is the OWASP XSS filter evasion cheat sheet: scheme obfuscation with
case, entities, embedded tabs, newlines and NUL, plus `data:`, `vbscript:`, SVG, CSS `expression`/`url(javascript:)`,
malformed tags, attribute breakout, protocol-relative URLs, `META` refresh and `BASE`. The second is the cmark
pathological suite (25 cases). The third is the cmark-gfm advisories: table-parsing DoS (2020) and an integer
overflow in table parsing (2022), quadratic bracket, pointy-brace and emphasis handling (2023), and unbounded resource
exhaustion. The fourth is the bugs found in Papyro itself: unescaped `alt`/`title` interpolation and an unsanitized
public path (research notes §0).

| Category | Cases (each a markdown input plus the assertion) |
|---|---|
| A. Raw HTML | `script`, `iframe`, `object`/`embed`, `style`, `svg onload`, `img onerror`, `form`/`button formaction`, `meta` refresh, `base href`, comments and CDATA, `noscript` mXSS, `math`/`svg` namespace confusion, `<a name>` clobbering: none survives as markup |
| B. URL schemes | `javascript:` with mixed case, decimal/hex entities without semicolons, embedded tab, newline, NUL and zero-width characters, leading spaces; `vbscript:`; `data:text/html`; protocol-relative `//host`. Each appears in inline links, reference definitions, angle autolinks, extended autolinks, image `src` and link titles: no executable URL survives |
| C. Attribute breakout | Quotes and `>` in alt text, link titles, code-fence info strings (`ruby" onmouseover=`), heading text (into `id` and `aria-label`), footnote labels (into `id`), alert titles: one well-formed attribute each |
| D. Client renderers | Mermaid with HTML labels, `click` callbacks, an init directive or front-matter config setting `securityLevel: loose`, `</pre><script>` in the source; KaTeX `\href{javascript:…}`, `\htmlStyle`, `\rule{500em}{500em}`, macro bombs: strict rendering, no link, bounded size |
| E. Unicode | NUL bytes, invalid UTF-8, bidi overrides (U+202E) in link text and headings (Trojan Source, CVE-2021-42574), homoglyph schemes: no crash, a documented error or U+FFFD, no hidden scheme |
| F. Parser abuse | The 25 cmark pathological cases; nesting above `max_nesting_depth`; tables with thousands of columns; 10,000 footnotes and reference definitions; a single 1 MiB line; input exactly at and one byte over `max_bytes`: each completes inside the time budget or raises the documented error |
| G. Extension misuse | An extension emitting `on*` or `style` through a `:raw` node, an extension declaring `style` in `allow`, a catastrophic regex: stripped, refused at boot, timed out with a named error |
| H. Page-level | Two documents with footnotes on one page; a heading slug equal to a global (`location`, `name`): no duplicate ids, no `name` attribute |

## Requirements

Grouped by pipeline stage. "Corpus" means the hostile-input corpus of RENDER-51.

### Render core

- **RENDER-01** (MUST) `Md.render(text, locale:, dialect:, variant:, context:)` is the only render entry point and
  returns an `Md::Document` (`html`, `toc`, `headings`, `plain_text`, `excerpt`, `word_count`, `reading_time`,
  `features`, `dialect`, `cache_key`); preview, publish, public page, feeds and email all call it. Acceptance: in the
  dummy app, rendering the fixture corpus through the editor preview endpoint and through the public page gives
  byte-identical `html`.
- **RENDER-02** (MUST) The gem depends on commonmarker 2.10.1 or later and pins every parse, render and extension
  option per dialect as in the options table of this doc; an app cannot set commonmarker options directly.
  Acceptance: a test compares each dialect's option hash with the documented table, and the gemspec floor is 2.10.1.
- **RENDER-03** (MUST) The sanitizer is the last stage before `Md::Document` is built, and the gem calls `html_safe`
  in exactly one place, after it. Acceptance: a code search of the gem finds one `html_safe` call, inside
  `Md::Document` construction, and the corpus passes.
- **RENDER-04** (MUST) Input is bounded: `max_bytes` (default 1 MiB) and `max_nesting_depth` (default 1000)
  are checked, and exceeding either raises `Md::InputTooLarge` or `Md::RenderError` whose message names the limit and
  the config key to change; invalid UTF-8 raises `Md::InvalidEncoding`. Acceptance: inputs one byte over the
  limit, one level over the depth and with an invalid byte each raise the named error with the config key in the message.
- **RENDER-05** (MUST) The core render is a pure function of its inputs: no database, network, `Current` or other
  global state; app data reaches extensions only through `context:`. Acceptance: the corpus renders in a test
  with Active Record disconnected and outbound network blocked.
- **RENDER-06** (SHOULD) A 10 KB article renders uncached, sanitizer included, in under 10 ms on the CI runner, and
  a `md:bench` task reports the figure. Acceptance: the CI benchmark job fails when the median exceeds the budget.

### Dialect

- **RENDER-07** (MUST) Dialects are numbered and frozen: `config.dialect` sets the default, `Md.render(dialect:)`
  overrides it per call, `Document#dialect` reports it, and a released dialect's parse and render behaviour changes
  only by publishing a new dialect number. Acceptance: the committed fixture outputs of a released dialect fail CI
  on any change unless the dialect number in the fixture file changes too.
- **RENDER-08** (MUST) Dialect v1 is CommonMark 0.31.2 plus GFM tables, task lists, strikethrough and extended
  autolinks, footnotes, the five GitHub alert types, figures, gem-owned heading anchors, highlighted fenced code and
  emoji shortcodes, as in the dialect table. Acceptance: the CommonMark and GFM spec examples pass (raw-HTML examples
  must render scrubbed, as listed in a documented exception file), plus fixtures for footnotes, alerts and figures.
- **RENDER-09** (SHOULD) Dialect v2 is v1 plus Mermaid fences and `math_code` math (```` ```math ```` and
  ``$`…`$``), each rendered as escaped source marked for the viewer. Acceptance: the v2 fixtures produce
  `pre.md-diagram` and `data-math-style` markup, and the same input under v1 renders plain code blocks.
- **RENDER-10** (MUST) No configuration turns raw HTML into trusted output: the only raw-HTML setting,
  `config.raw_html = :sanitized`, still runs the full allowlist, and `unsafe: true` is never passed without it.
  Acceptance: the corpus passes under every combination of dialect, variant and `raw_html` setting.
- **RENDER-11** (COULD) An opt-in AST pass maps Obsidian callout types onto the five GitHub types (`info` to NOTE,
  `danger` to CAUTION, unknown to NOTE). Acceptance: with the option on, `> [!info]` renders as a note alert, and with it
  off it renders as a blockquote.
- **RENDER-12** (SHOULD) A `md:dialect:diff` task renders a set of records under two dialects and lists the records
  whose HTML changes, so a dialect switch is a reviewed migration. Acceptance: running it from v1 to v2 over the
  fixture corpus lists exactly the documents containing Mermaid or math fences.
- **RENDER-13** (COULD) Dollar math (`math_dollars`) is available only as an explicit app opt-in, documented with
  the prose-price hazard. Acceptance: by default "$5 and $10" renders as text, and with the opt-in on, `$x$` renders as math.

### Sanitizing and links

- **RENDER-14** (MUST) The final sanitizer is an HTML5-parser allowlist in prune mode built from the allowlist draft
  of this doc: `http`, `https`, `mailto`, relative and fragment URLs for `href`, `http`, `https` and relative URLs for
  `src`, nothing else. Acceptance: a test enumerates the configured allowlist and protocols and compares them
  with the documented table, and the corpus passes.
- **RENDER-15** (MUST) The never-allow list (`script`, `style` tag and attribute, `iframe`, `object`, `embed`, `form`,
  `button`, `meta`, `base`, `link`, `svg`, `math`, `noscript`, `mglyph`, `malignmark`, `name`, `srcdoc`, `formaction`,
  `on*`) is enforced at boot: an extension declaring any of them raises `Md::UnsafeAllowlist`. Acceptance: a
  test extension declaring `allow "div", attributes: %w[style]` fails `Md.configure` with that error.
- **RENDER-16** (MUST) Rendered HTML contains no inline `style` attributes and no inline scripts: table alignment and
  code highlighting use classes, so the output works under a strict CSP. Acceptance: no corpus or fixture
  output contains a `style=` attribute or a `script` element.
- **RENDER-17** (MUST) A post-render link policy adds `rel` tokens to external links (default `nofollow ugc noopener`),
  leaves relative and same-host links untouched, sets no `target` by default, and can be relaxed per call
  (`links: { rel: %w[noopener] }`) for trusted authors. Acceptance: fixtures show the default `rel` on an
  external link, none on a relative link, and the relaxed set when the per-call option is given.
- **RENDER-18** (MUST) Output never contains a `name` attribute, and every `id` comes from a gem pass (headings,
  footnotes) and never equals a configurable list of reserved names (default: the `window` and `document`
  properties the app's JavaScript reads); a colliding slug gets a suffix. Acceptance: a heading titled
  "location" renders with id `location-1`, and `<a name="x">` in the source yields no `name` attribute.
- **RENDER-19** (MUST) Every attribute the gem or its passes generate (`alt`, `title`, `href`, `src`, `id`,
  `aria-label`, `class` from info strings) is built through node accessors or a DOM API, never by string
  interpolation. Acceptance: the corpus's attribute-breakout cases each produce exactly one well-formed attribute.

### Extension API

- **RENDER-20** (MUST) Apps add syntax with `Md::Extension` subclasses (`extension_name`, `version`, optional
  `prepare`, `transform(document, context)`) registered through `config.extensions.use`; they run after the built-in
  AST passes and before HTML rendering, and match text only through `context.replace_text`/`context.scan_text`, which
  visit `:text` nodes outside code, math and link URLs. Acceptance: the mentions example of this doc works in the
  dummy app, and `@name` inside a code span or a link URL stays literal.
- **RENDER-21** (MUST) An extension emits markup only as nodes (`:link`, `:image`, `:text`, `:raw`, …), every node's
  output passes the final sanitizer, and allowlist additions are declared on the extension with `allow` and validated
  by RENDER-15. Acceptance: an extension emitting `<span onclick="x">` through a `:raw` node renders a `span` without
  `onclick`.
- **RENDER-22** (MUST) Each registered extension contributes its name, version and allowlist additions to the
  configuration fingerprint used by the cache key. Acceptance: bumping an extension's `version` changes
  `Document#cache_key` for the same text.
- **RENDER-23** (SHOULD) `Md::HtmlFilter` subclasses (CSS `selector` plus `call(element, context)`) cover HTML-level
  changes such as Papyro's image lightbox, and run before the sanitizer. Acceptance: a lightbox filter wraps each
  image in a link carrying its declared `data-action`, and the attribute survives sanitizing only when declared.
- **RENDER-24** (SHOULD) Text matchers run under a per-extension regex timeout (default 100 ms), and any exception or
  timeout inside an extension raises `Md::ExtensionError` naming the extension and the node's source position.
  Acceptance: a test extension with a catastrophic pattern raises that error within the timeout, and the message names
  the extension.
- **RENDER-25** (SHOULD) The gem ships test helpers: `Md::Testing.assert_renders(markdown, html)` and
  `Md::Testing.run_corpus(config)`, which runs the hostile corpus against the app's own configuration and
  extensions. Acceptance: a test generated by the install generator runs the corpus against the app config and passes
  on a fresh app.

### Anchors, TOC and ids

- **RENDER-26** (MUST) Heading ids come from a gem-owned slug function, not comrak's `header_ids`: GitHub-compatible
  (lowercase, spaces to hyphens, punctuation dropped, non-ASCII letters kept, duplicates suffixed `-1`, `-2`), stable for
  the life of a dialect, with a heading link whose accessible name is localized. Acceptance: fixtures render
  "Greek Letter Θ!" as `greek-letter-θ`, "¿Qué es?" as `qué-es`, and two "Intro" headings as `intro` and `intro-1`.
- **RENDER-27** (SHOULD) `config.slug = :ascii` transliterates slugs for apps that must keep existing anchors.
  Acceptance: with `:ascii`, "Introducción" becomes `introduccion`.
- **RENDER-28** (MUST) `Document#toc(max_level:)` returns a nested list of headings with level, plain text and the
  same id as the rendered HTML, and `Document#headings` returns the flat list. Acceptance: for every corpus
  document each TOC id exists exactly once in `html`.
- **RENDER-29** (MUST) `Md.render(id_prefix:)` prefixes every footnote id and fragment link (and heading ids when
  `prefix_headings: true`), so several documents can share a page. Acceptance: an English and a Spanish document with
  footnotes rendered on one page with prefixes `en-` and `es-` have no duplicate ids, and every footnote link resolves.

### Caching and instrumentation

- **RENDER-30** (MUST) `Document#cache_key` digests the text, dialect, locale, variant, `Md::RENDERER_VERSION`,
  the commonmarker version and the configuration fingerprint (options, extensions, allowlist, typography, link
  policy, `base_url`, `id_prefix`). Acceptance: a property test changes each input in turn and gets a new key,
  and identical inputs give the same key in two processes.
- **RENDER-31** (SHOULD) `Md.render(cache: Rails.cache)` (or any `ActiveSupport::Cache::Store`) fetches and stores the
  document under its cache key; with no `cache:` nothing is cached, and column storage stays with the app. Acceptance:
  the second render of the same text with a cache store reports a cache hit and skips parsing.
- **RENDER-32** (SHOULD) Each render emits an `ActiveSupport::Notifications` event `render.md` with bytes,
  dialect, variant, duration and cache hit. Acceptance: a subscriber in a test receives the event with those
  keys.

### Typography and reading metrics

- **RENDER-33** (SHOULD) `typography: true` runs a locale-keyed pass over text nodes outside code, math and URLs:
  `en` uses curly quotes, `es` uses « » with “ ” and ‘ ’ for nested quotes (RAE), plus ellipses and dashes;
  unknown locales stay untouched, and the source markdown never changes. Acceptance: with `locale: :es`,
  `"hola"` renders as «hola», and the same text inside a code span stays unchanged.
- **RENDER-34** (COULD) Typography rules are a per-locale table an app can extend, for example French spaces before
  `;:!?`. Acceptance: registering a `fr` rule set adds a narrow no-break space before `?` in a fixture.
- **RENDER-35** (SHOULD) `Document#word_count` counts Unicode words of the plain text, and `reading_time` uses a
  words-per-minute setting per locale. Acceptance: the English and Spanish fixtures report the expected counts,
  and changing the Spanish rate changes only Spanish reading times.

### Output variants

- **RENDER-36** (SHOULD) `variant: :static` renders feed and email bodies: absolute URLs from `base_url:`, no
  heading links or `data-*` hooks, Mermaid and math as their escaped source, task checkboxes as ☐/☑ characters, and
  alerts as blockquotes with a bold localized title. Acceptance: the static output of the corpus contains no
  relative URL, no `input`, no `data-` attribute and no `class` the email needs to style.
- **RENDER-37** (MUST) `Document#plain_text` is derived from the AST: block text joined by newlines, footnote markers
  dropped, image alt text kept, no markup. Acceptance: the plain text of every corpus document contains no
  angle-bracket markup and matches its fixture.
- **RENDER-38** (MUST) `Document#excerpt(length: 160)` takes plain text from the first prose paragraphs, skipping
  headings, alerts, code, tables and images, and cuts at a word boundary with an ellipsis, for `og:description` and
  meta descriptions. Acceptance: a document starting with a heading and an alert returns its first paragraph,
  at most 160 characters, ending on a whole word.
- **RENDER-39** (COULD) `config.static_renderers[:mermaid]` and `[:math]` accept app callables that return an image
  URL for the static variant, so an app can render diagrams in a job (mermaid-cli, Kroki) without the core depending
  on them. Acceptance: with a configured callable, the static output shows an `img` with the returned URL in place of
  the diagram source.

### Viewer

- **RENDER-40** (MUST) The viewer markup contract is one root element with class `md-prose`, the viewer's Stimulus
  controller and a `data-md-features` list from `Document#features`; all gem classes are prefixed `md-` (except the
  GitHub-compatible `markdown-alert*`, `footnotes`, `task-list-item`, `language-*`), and styles read CSS variables
  whose names the `THEME` area defines. Acceptance: the ERB helper and the Phlex component produce identical markup
  for the corpus.
- **RENDER-41** (MUST) Code highlighting emits classes (`theme: ""`), the gem ships a highlight stylesheet for light
  and dark schemes built on theme tokens, and an unknown language renders as escaped plain code. Acceptance: a
  Ruby fence renders with highlight classes and no inline style, and a fence tagged `nosuchlang` renders as plain
  escaped code.
- **RENDER-42** (MUST) Mermaid and KaTeX load through dynamic `import()` only when `data-md-features` includes them,
  and a page without diagrams or math downloads neither. Acceptance: the network log of a dummy-app page without
  diagrams or math shows no Mermaid or KaTeX request, and a page with one diagram shows exactly one Mermaid load.
- **RENDER-43** (MUST) Mermaid is initialized with `securityLevel: "strict"`, `startOnLoad: false` and the default
  `secure` key list, and runs on the marked nodes only with `suppressErrors`; a diagram that fails keeps its source
  visible with a localized error note. Acceptance: a corpus diagram with an init directive or front matter
  setting `securityLevel: "loose"` and a `click` callback renders without a clickable callback.
- **RENDER-44** (MUST) Math renders per marked element with `katex.render` (never auto-render), `trust: false`,
  a bounded `maxSize`, `maxExpand` 1000, `throwOnError: false` and `htmlAndMathml` output. Acceptance:
  `\href{javascript:alert(1)}{x}` renders as an error-colored command with no link, and "$5 and $10" in prose stays
  plain text on the same page.
- **RENDER-45** (MUST) Client enhancement is idempotent and Turbo-safe: it runs on controller connect, cleans up on
  disconnect, survives cache restores and morphs, and never renders an element twice. Acceptance: a system test
  visits a page with a diagram, navigates away and back through the Turbo cache, and finds exactly one SVG per diagram.
- **RENDER-46** (MUST) Viewer output meets WCAG 2.2 AA: heading links and footnote back-links have localized
  accessible names, tables sit in a focusable, named scroll region, diagrams expose `role="img"` with the
  diagram's `accTitle` or a localized fallback and keep their source in a disclosure, task checkboxes are disabled,
  and alert titles are translated in English and Spanish. Acceptance: an axe-core system test over the corpus page
  reports no violations in either locale.
- **RENDER-47** (SHOULD) Images get `loading="lazy"` and `decoding="async"`, and an app hook can supply `width` and
  `height` (for example from Active Storage metadata) to avoid layout shift. Acceptance: fixture images carry the
  lazy attributes, and with the hook configured they carry the returned dimensions.
- **RENDER-48** (SHOULD) Diagrams take their colors from the theme's CSS variables and re-render when the color
  scheme changes. Acceptance: toggling dark mode in a system test re-renders a diagram with the dark colors.
- **RENDER-49** (COULD) `config.image_url_rewriter` lets an app send remote image URLs through its own proxy for
  privacy. Acceptance: with a rewriter configured, a remote image's `src` is the rewritten URL in every variant.
- **RENDER-50** (COULD) Embeds come from provider extensions that turn a bare URL alone on a line into a link card
  with click-to-load; the sanitized HTML never contains an `iframe`. Acceptance: a YouTube URL line renders as a
  card with no `iframe` until a reader activates it.

### Corpus and CI

- **RENDER-51** (MUST) The gem repository holds the hostile-input corpus with categories A-H of this doc, and CI runs
  it on every pull request against every dialect and variant; a surviving payload fails the build. Acceptance:
  the CI `corpus` job exists, covers every category, and turns red when a test payload's marker is allowed through.
- **RENDER-52** (MUST) Every parser-abuse case (the 25 cmark pathological cases, depth, wide tables, many footnotes,
  long lines, the size boundary) completes within 2 seconds each or raises its documented error. Acceptance: the
  CI job times each case and fails above the budget.
- **RENDER-53** (SHOULD) A fuzz job renders randomly generated markdown and asserts the invariants: no `script`,
  no `on*` attribute, no `style` attribute, no `javascript:` URL, valid UTF-8, and only documented errors. Acceptance:
  a scheduled job runs at least 100,000 inputs per week and stores any failing input as a new corpus case.
- **RENDER-54** (MUST) Security floors track advisories: the gemspec requires commonmarker 2.10.1 or later and
  rails-html-sanitizer 1.7.2 or later, and CI runs `bundler-audit` on the gem and the dummy app. Acceptance:
  the gemspec floors match the latest advisories listed in this doc, and the audit job is part of CI.

## Developer experience notes

The newcomer's path is one call: `Md.render(post.body)` with no configuration. It uses dialect v1, `I18n.locale`, the
`:web` variant and no cache, and returns a document whose `html` can be output directly. Everything else is opt-in,
one keyword or setting at a time. Here is what each surface costs a newcomer:

- **Entry point and Document (RENDER-01, 28, 37, 38).** One method and one value object. The metadata replaces code
  apps write today (Papyro's presenter computes reading time itself), so it removes work rather than adding concepts.
- **Pinned options (RENDER-02, 10).** No commonmarker options to learn. The cost is flexibility: an app that wants
  `hardbreaks` cannot have it without a new dialect. The error raised for an attempt should say so and point at the
  dialect docs.
- **Dialect (RENDER-07-13).** One setting, `config.dialect`. The concept of a frozen dialect needs a short guide
  page, and the `md:dialect:diff` task (RENDER-12) is what makes upgrading safe without reading the changelog.
- **Limits and errors (RENDER-04, 24).** Error classes name the limit and the config key, so a developer hitting
  `Md::InputTooLarge` in a form submission knows what to change. The `RAILS` area should pair them with a model
  validator.
- **Allowlist (RENDER-14-16).** There is no free-form `config.sanitizer.allow`. Additions exist only on extensions and
  are validated at boot. That blocks the most common way apps reintroduce XSS, at the cost of writing a small
  extension when an app needs an extra attribute.
- **Extension API (RENDER-20-25).** This is the one advanced surface: a class with `transform`, plus `allow` and
  `version`. The cost is learning commonmarker's node API. The guide should lead with the mentions example and the
  lightbox `HtmlFilter`, which cover most needs, and `Md::Testing.run_corpus` lets an extension author prove safety
  without knowing the corpus.
- **Anchors (RENDER-26, 27, 29).** Zero configuration. Apps migrating from transliterated anchors set one option.
  `id_prefix:` is needed only when several documents share a page, which the `VIEWS` helpers can do automatically.
- **Caching (RENDER-30-32).** One keyword (`cache: Rails.cache`). The key is computed by the gem, so apps never write
  cache-busting code. Instrumentation is free to ignore.
- **Typography (RENDER-33-35).** One boolean. Off by default, because quote changes surprise authors of technical text.
- **Variants (RENDER-36, 39).** One keyword plus `base_url:`. The guide must state plainly that feeds and email
  still need the app's XML and CSS inlining.
- **Viewer (RENDER-40-48).** One helper or component (shape owned by `VIEWS`) and one stylesheet. Mermaid and KaTeX
  cost nothing until a document uses them; how their packages are pinned is the `ASSETS` area's cost.

## Open decisions

- Sanitizer engine: rails-html-sanitizer (Loofah and Nokogiri, HTML5 parser) or Selma (the lol-html based sanitizer
  html-pipeline 3 uses). Recommendation: rails-html-sanitizer 1.7.2 or later. Every Rails app already has it, its
  advisories are tracked by Rails security, and adding a second Rust native gem next to commonmarker raises install
  cost on platforms without prebuilt binaries. Revisit Selma only if RENDER-06's budget fails because of the sanitizer.
- Heading id namespace: plain ids (`#intro`) or GitHub's `user-content-` prefix with JavaScript to resolve fragments.
  Recommendation: plain ids with the reserved-name suffix of RENDER-18. Shareable URLs stay readable and work without
  JavaScript, and DOM clobbering is limited because raw HTML is off and `name` is never emitted.
- Default slug style: Unicode, GitHub-compatible (RENDER-26), or ASCII transliteration. Recommendation: Unicode by
  default. It matches GitHub, Obsidian and what agents expect, and an app that must keep old anchors sets
  `config.slug = :ascii`. Papyro decides its own migration in the `PAPYRO` area.
- External-link default `rel`: `nofollow ugc noopener` or only `noopener`. Recommendation: the full set. The gem
  cannot tell whether an author is trusted, Google defines `ugc` for exactly this content, and trusted-author apps
  relax it in one call.
- Emoji shortcodes in dialect v1: on, as on GitHub, or off. Recommendation: on. LLM and GitHub-authored text uses them,
  and comrak only expands known names, so times like "10:30:00" are safe. Keep a fixture to prove it.
- Feed and email: one `:static` variant, or separate `:feed` and `:email` variants. Recommendation: one `:static`
  variant for 0.x. Both need the same thing (absolute URLs, no client enhancement), and splitting later is additive.
- When v2 ships: in 0.1 with v1, or in a later 0.x. Recommendation: v1 in 0.1 and v2 in the following 0.x, matching
  the benchmark's phases. Mermaid and KaTeX delivery (`ASSETS`) and the strict-mode tests (RENDER-43, 44) are the
  bulk of the viewer work and should not hold back the security fix the render core carries.

## Sources

- https://github.com/gjtorikian/commonmarker (accessed 2026-11-03)
- https://raw.githubusercontent.com/gjtorikian/commonmarker/main/CHANGELOG.md (accessed 2026-11-03)
- https://github.com/gjtorikian/commonmarker/blob/main/ext/commonmarker/src/node.rs (accessed 2026-11-03)
- https://github.com/gjtorikian/commonmarker/blob/main/lib/commonmarker/node.rb (accessed 2026-11-03)
- https://github.com/kivikakk/comrak (accessed 2026-11-03, via the research notes)
- https://spec.commonmark.org/ (accessed 2026-11-03, via the research notes)
- https://github.com/rails/rails-html-sanitizer (accessed 2026-11-03)
- https://github.com/rails/rails-html-sanitizer/blob/main/CHANGELOG.md (accessed 2026-11-03)
- https://github.com/gjtorikian/html-pipeline (accessed 2026-11-03)
- https://gohugo.io/render-hooks/introduction/ (accessed 2026-11-03)
- https://docs.gitlab.com/development/gitlab_flavored_markdown/ (accessed 2026-11-03, via the benchmark report)
- https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax (accessed 2026-11-03, via the research notes)
- https://mermaid.js.org/config/usage.html (accessed 2026-11-03)
- https://mermaid.js.org/config/directives.html (accessed 2026-11-03)
- https://mermaid.js.org/config/schema-docs/config.html (accessed 2026-11-03)
- https://katex.org/docs/autorender (accessed 2026-11-03)
- https://katex.org/docs/options (accessed 2026-11-03)
- https://cheatsheetseries.owasp.org/cheatsheets/XSS_Filter_Evasion_Cheat_Sheet.html (accessed 2026-11-03)
- https://cheatsheetseries.owasp.org/cheatsheets/DOM_Clobbering_Prevention_Cheat_Sheet.html (accessed 2026-11-03)
- https://github.com/commonmark/cmark/blob/master/test/pathological_tests.py (accessed 2026-11-03)
- https://github.com/github/cmark-gfm/security/advisories (accessed 2026-11-03)
- https://trojansource.codes/ (accessed 2026-11-03)
- https://docs.ruby-lang.org/en/master/Regexp.html (accessed 2026-11-03)
- https://www.rae.es/dpd/comillas (accessed 2026-11-03)
- https://ogp.me/ (accessed 2026-11-03)
- https://developers.google.com/search/docs/appearance/snippet (accessed 2026-11-03)
- https://developers.google.com/search/docs/crawling-indexing/qualify-outbound-links (accessed 2026-11-03)
- https://www.rssboard.org/rss-specification (accessed 2026-11-03)
- https://www.caniemail.com/features/html-svg/ (accessed 2026-11-03)
- https://developers.forem.com/frontend/liquid-tags (accessed 2026-11-03, via the benchmark report)
- `docs/features/markdown-editor/reports/Markdown editor benchmark.md` (benchmark report)
- `docs/features/markdown-editor/research_notes/Markdown editor benchmark/rendering_and_syntax.md` (research notes)
