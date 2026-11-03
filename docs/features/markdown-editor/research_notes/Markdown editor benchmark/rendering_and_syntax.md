# Markdown Rendering and Extended Syntax: Landscape and Ruby/Rails Pipeline for Papyro (as of 2026-11-03)

Scope note: research run on 2026-11-03. Sources fetched in this session are cited normally. Items marked "(not re-fetched)" come from well-known primary URLs I did not reload in this session; the report writer should treat them as lower-confidence. Papyro code findings come from reading the repository and running `bin/rails runner` locally (primary evidence; file paths are given).

## 0. Papyro baseline (local code inspection, primary evidence)

### Takeaway
Papyro has three rendering paths that disagree. The public article page and the Studio preview output Redcarpet HTML **without sanitization** (`filter_html: false` plus `.html_safe`). `ActionText::Markdown#to_html`, used by the Publish operation and content analysis, runs Rails' default SafeList sanitizer, which **strips tables, heading `id`s, `aria-hidden` and `data-*` attributes**. Preview and public output can therefore differ from what Publish derives, and the public path is open to XSS.

### Cited Findings
- Gems: `redcarpet 3.6.1`, `rouge 4.7.0`, `rails-html-sanitizer 1.7.1`, `loofah 2.25.2`, Ruby 4.0.0. Sources: `Gemfile.lock`, `ruby -v` (local).
- Extensions: `autolink, highlight, no_intra_emphasis, fenced_code_blocks, lax_spacing, strikethrough, tables`. Renderer option: `filter_html: false`. Footnotes, task lists and heading-anchor extensions are not enabled. Source: `lib/rails_ext/action_text_markdown.rb`.
- `MarkdownRenderer < Redcarpet::Render::HTML` includes `Rouge::Plugins::Redcarpet`. It overrides `header` (parameterize-based unique ids plus a `#` link with `aria-hidden`) and `image`, which wraps the image in a lightbox `<a data-action="lightbox#open:prevent">`. The `image` override interpolates `url`, `alt_text` and `title` into attributes **without HTML-escaping**, so an alt text containing `"` can inject attributes. Source: `lib/markdown_renderer.rb`.
- Public page: `app/views/articles/show/content.rb:13` calls `raw @presenter.content_html`, and `Articles::Presenter::Show#content_html` returns `MarkdownRenderer.build.render(content_markdown).html_safe`. No sanitizer runs, so raw HTML in markdown, including `<script>` and `javascript:` links, reaches readers. Source: `app/concepts/articles/presenter/show.rb:20-22`.
- Studio preview: `PapyroStudio::ArticlePreviewsController#create` renders `MarkdownRenderer.build.render(...)` and returns `render html: preview_html.html_safe`. It is unsanitized, but it uses the same renderer as the public page. Source: `../papyro_studio/app/controllers/papyro_studio/article_previews_controller.rb`.
- `ActionText::Markdown#to_html` passes output through `Rails::HTML5::SafeListSanitizer.new.sanitize`. This path is used by `Articles::Operation::Publish` (`publish.rb:109`, `model.body&.to_html`) and by `Articles::Service::ContentAnalysis`. Source: `lib/rails_ext/action_text_markdown.rb`, `app/concepts/articles/...`.
- I verified the sanitizer defaults locally:
  - Allowed tags: `a abbr acronym address b big blockquote br cite code dd del dfn div dl dt em h1-h6 hr i img ins kbd li mark ol p pre samp small span strong sub sup time tt ul var`. There is **no `table/thead/tbody/tr/th/td`**, no `input` (task lists), no `figure/figcaption`, no `section` (footnotes) and no `svg`.
  - Allowed attributes: `abbr alt cite class datetime height href lang name src title width xml:lang`. There is **no `id`, `aria-*`, `data-*` or `style`**, so table alignment is lost too.
  - Test input `<h2 id="x">…<a … aria-hidden>…</a></h2><table>…<td style="text-align:right">1</td>…<a href="javascript:…" data-action=…>` came out as `<h2>T <a href="#x" class="heading__link">#</a></h2>1<a>x</a>`.
  - Source: local `bin/rails runner` against rails-html-sanitizer 1.7.1.
- Redcarpet gem releases: 3.6.1 (2025-02-25), 3.6.0 (2023-01-29), 3.5.1 (2020-12-15). — [rubygems redcarpet versions](https://rubygems.org/api/v1/versions/redcarpet.json)

### Inferences
- Any migration should end with one canonical `render(markdown, locale:) -> safe_html` service. The public page, the preview, Publish and the excerpt/reading-time code should all call it, with one explicit allowlist that adds tables, task-list inputs, `id`s, footnote sections and the lightbox `data-*` attributes.
- The XSS exposure is limited if only trusted Studio authors write markdown. Papyro has multiple authors and roles, though, so I would treat it as a real vulnerability.

### Gaps
- I did not check whether a CSP header mitigates inline-script XSS on the public site.

---

## 1. Extended syntax landscape and how platforms render each element

### Takeaway
By 2026 the de-facto portable core is **CommonMark 0.31.2 + GFM**: tables, task lists, strikethrough, autolinks and tagfilter, plus footnotes. **GitHub-style alerts (`> [!NOTE]`)** have become the de-facto callout syntax because they degrade gracefully to a blockquote, and Obsidian, comrak/commonmarker, GitLab and Hugo all accept them. **```` ```mermaid ```` fences** and **`$`/`$$` or ```` ```math ```` fences** are the de-facto conventions for diagrams and math. Directives (`:::note`), MDX components and Markdoc tags remain dialect-specific.

### Cited Findings
**Specs**
- The latest CommonMark spec is **0.31.2 (2024-01-28)**. The previous one was 0.30 (2021-06-19), and no 1.0 is announced. — [spec.commonmark.org](https://spec.commonmark.org/)
- comrak is "Compliant with CommonMark 0.31.2 by default", and its badges show 652/652 CommonMark and 670/670 GFM spec tests passing. — [kivikakk/comrak](https://github.com/kivikakk/comrak)
- GitLab's goal is for GLFM to be "100% compliant with CommonMark". GLFM = CommonMark core + GFM extensions + GitLab extras (math, multiline blockquotes, references). — [GitLab GLFM dev docs](https://docs.gitlab.com/development/gitlab_flavored_markdown/)
- The GFM spec is still the 0.29-gfm edition from 2019 (not re-fetched). — [github.github.com/gfm](https://github.github.com/gfm/)

**Alerts / callouts / admonitions**
- GitHub alerts start a blockquote with `> [!NOTE]`. There are five types: NOTE, TIP, IMPORTANT, WARNING, CAUTION. "Alerts cannot be nested within other elements", and GitHub advises one or two per article. — [GitHub basic formatting docs](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax)
- Obsidian callouts:
  - Syntax is `> [!type] Optional title`, with case-insensitive types.
  - `+`/`-` after the type makes the callout foldable (expanded/collapsed), and a title-only callout is allowed.
  - There are 13 types with aliases: note, abstract/summary/tldr, info, todo, tip/hint/important, success/check/done, question/help/faq, warning/caution/attention, failure/fail/missing, danger/error, bug, example, quote/cite.
  - Unknown types fall back to `note`, and callouts nest with extra `>`.
  - CSS hooks are `.callout[data-callout="x"]`, `--callout-color` and `--callout-icon`.
  - Source: [Obsidian help: Callouts](https://obsidian.md/help/callouts)
  - Obsidian syntax is a superset of GitHub's: all five GitHub types parse in Obsidian (IMPORTANT and CAUTION as aliases).
- Docusaurus admonitions:
  - Syntax is `:::note … :::`. Types are note, tip, info, warning and danger.
  - Titles go in brackets (`:::note[Title]`), and attributes as `{.class #id}`.
  - Nesting uses more colons on the parent (5 then 4). MDX components are allowed inside, and blank lines are needed around directives for Prettier.
  - It is implemented as a Remark plugin. The docs version is 3.10.2.
  - Source: [Docusaurus admonitions](https://docusaurus.io/docs/markdown-features/admonitions)
- commonmarker exposes an `alerts` extension (added in 2.0.3, 2025-01-21), `alert_type` node accessors (2.8.2, 2026-05-09) and an `alert_style` option (2.9.0, 2026-07-13). It also lists a `block_directive` extension and `multiline_block_quotes`. — [commonmarker README](https://github.com/gjtorikian/commonmarker), [CHANGELOG](https://raw.githubusercontent.com/gjtorikian/commonmarker/main/CHANGELOG.md)
- The generic directive proposal (`:name[content]{attrs}`, `::leaf`, `:::container`) has never been merged into the CommonMark spec. It is implemented by remark-directive and other tools (not re-fetched). — [talk.commonmark.org generic directives thread](https://talk.commonmark.org/t/generic-directives-plugins-syntax/444)

**Math**
- GitHub renders math with **MathJax**:
  - Inline: `$…$`, or ``$`…`$`` when the expression collides with markdown syntax.
  - Block: `$$…$$` on its own lines, or a ```` ```math ```` fence.
  - Literal dollars need `\$` inside math or `<span>$</span>` outside it.
  - Source: [GitHub math docs](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/writing-mathematical-expressions)
- commonmarker/comrak offer `math_dollars`, `math_code` (```` ```math ```` and ``$`…`$``) and, since 2.9.0, `math_latex`. These only *mark up* math (spans/code with `data-math-style`). Typesetting with KaTeX/MathJax is a separate step. — [commonmarker README](https://github.com/gjtorikian/commonmarker), [CHANGELOG](https://raw.githubusercontent.com/gjtorikian/commonmarker/main/CHANGELOG.md)

**Diagrams**
- GitHub renders ```` ```mermaid ```` fences in issues, PRs, discussions, wikis and .md files. Putting `info` in a mermaid block shows the Mermaid version GitHub uses. GitHub also renders `geojson`/`topojson` (maps) and `stl` (3D) fences. Its docs do not say whether rendering is client- or server-side. — [GitHub diagrams docs](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams)
- Mermaid docs currently show **v12.3.0**. The recommended loading is an ESM import (`mermaid@12/dist/mermaid.esm.min.mjs`) with `startOnLoad: false` plus `mermaid.run({querySelector|nodes, suppressErrors})`. `mermaid.init` is deprecated. — [mermaid.js.org usage](https://mermaid.js.org/config/usage.html)

**Footnotes, anchors, TOC, emoji**
- GitHub footnotes:
  - Syntax is `[^1]` for the reference and `[^1]: text` for the definition. References render as superscript numbers, and definitions are collected at the bottom.
  - GitHub wikis do not support footnotes.
  - Source: [GitHub basic formatting](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax)
- GitHub heading anchors:
  - The anchor slug is lowercased with spaces turned into hyphens. Punctuation and markup are removed, and non-ASCII letters are kept (example "…Greek Letter Θ!" becomes `#…-greek-letter-Θ`).
  - Duplicate slugs get `-1`, `-2`.
  - GitHub auto-generates an "Outline" TOC when there are 2+ headings, and custom anchors use `<a name>`.
  - Source: [same](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax)
  - Papyro uses `parameterize`, which transliterates Unicode ("Θ" is dropped and "ñ" becomes "n"), so anchors are not GitHub-compatible.
- Emoji shortcodes (`:+1:`, `:shipit:`) are supported on GitHub. — [same](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax). commonmarker enables `shortcodes` by default. — [commonmarker README](https://github.com/gjtorikian/commonmarker)

**Other elements available in the Ruby renderers**
- commonmarker supports:
  - Extensions: description lists, front matter (`front_matter_delimiter`), wikilinks, superscript/subscript, underline, spoiler, highlight (`==x==`) and insert (`++x++` → `<ins>`, 2.7.0).
  - Footnotes: classic and `inline_footnotes` (2.5.0).
  - Task lists: `tasklist_classes` (2.3.0).
  - Source: [commonmarker README](https://github.com/gjtorikian/commonmarker), [CHANGELOG](https://raw.githubusercontent.com/gjtorikian/commonmarker/main/CHANGELOG.md)
- Redcarpet supports tables, fenced code, autolink, strikethrough, footnotes, highlight, underline, superscript, quote, no_intra_emphasis and others. It has **no task lists, alerts, math, definition lists or front matter**. It ships HTML, XHTML, HTML_TOC and StripDown renderers plus SmartyPants. — [vmg/redcarpet](https://github.com/vmg/redcarpet)

### Inferences
- Platform matrix to verify (largely from prior knowledge, not re-fetched):
  - GitLab: GFM plus math, mermaid, PlantUML/Kroki and alerts.
  - HackMD: CommonMark-ish plus `:::info` containers, MathJax and mermaid.
  - Notion export: GFM tables, but callouts become `<aside>`/blockquotes and math becomes `$$`.
  - Hugo: Goldmark, with render hooks for code, images, headings and blockquote alerts.
  - Jekyll: kramdown with the GFM parser, footnotes, definition lists, abbreviations and `{: .class}` IALs.
  - Markdoc: `{% tag %}`.
  - MDX 3: JSX components.
- For an editorial app the safe core to support is CommonMark + GFM + footnotes + GitHub alerts + mermaid fences + math fences/dollars + figures/captions. Directive/MDX/Markdoc syntaxes hurt portability, because LLMs and other tools default to GFM output and GitHub-alert syntax.
- Image captions and figures have no standard. Common workarounds are the image title becoming a `<figcaption>`, an image alone in a paragraph becoming a `<figure>` (Hugo/Goldmark render hooks), or kramdown IALs. Papyro's existing `image` override is the natural hook.

### Gaps
- I did not fetch current HackMD, Notion-export, Hugo (Goldmark alerts render-hook version) or Jekyll/kramdown docs, so the per-platform rendering of definition lists, abbreviations and embeds is unverified this session.
- Code-fence filename and line-highlight meta (`title="x.rb" {1,3-5}`) is a Docusaurus/Expressive-Code/Shiki convention. The Docusaurus admonitions page did not cover it, and I found no CommonMark standard for it. Info-string meta is free-form per the spec.
- Embeds (YouTube/oEmbed): no standard markdown syntax was found. Platforms either auto-embed a bare URL alone on a line or use directives or shortcodes.

---

## 2. Ruby renderer options (maintenance, compliance, performance, adoption)

### Takeaway
**commonmarker 2.x** (Rust comrak via magnus/rb-sys) is the clear forward choice in 2026. It is actively released (10 releases in 2026, latest 2.10.1 on 2026-10-16), passes the full CommonMark 0.31.2 and GFM test suites, and covers every extension Papyro needs (alerts, footnotes, task lists, math markup, front matter, header IDs, syntect highlighting, AST walking). Redcarpet is 3-4x faster but not CommonMark-compliant and has had only one release since 2023, though it saw new commits in 2026.

### Cited Findings
- commonmarker versions:
  - 2026 releases: 2.10.1 (2026-10-16), 2.10.0 (2026-08-24), 2.9.0 (2026-07-14), 2.8.3 (2026-07-04), 2.8.2 (2026-05-09), 2.8.1/2.8.0 (2026-04), 2.7.0 (2026-03-14).
  - Source: [rubygems commonmarker versions](https://rubygems.org/api/v1/versions/commonmarker.json)
- commonmarker history:
  - v1.0.0 switched from cmark-gfm (C) to comrak (Rust) on 2023-12-24, with pre-releases from November 2022.
  - 2.0.0 (2024-11-25) changed option merging with defaults (breaking).
  - Ruby 4.0 support arrived in 2.6.1 (2026-01-06).
  - 2.9.0 bumped comrak to 0.54 and changed heading-anchor markup: the `id` now sits on the heading, and an anchor with `aria-label` and `data-heading-content` sits at the end.
  - 2.10.1 fixed a native stack overflow on deeply nested input (GHSA-c4fj-h48v-9fxp) and reuses the CSS highlighter across renders.
  - Source: [commonmarker CHANGELOG](https://raw.githubusercontent.com/gjtorikian/commonmarker/main/CHANGELOG.md)
- commonmarker defaults and options:
  - Extensions on by default: strikethrough, table, autolink, tasklist, shortcodes. `unsafe: false` by default, so raw HTML is not rendered, and `escape` is available.
  - `hardbreaks` **defaults to true**. This differs from CommonMark soft-break behaviour and needs care.
  - Other options: `github_pre_lang`, `sourcepos`, and `max_nesting_depth` (default 1000; raises `NestingDepthExceededError`).
  - AST: `walk`, `each`, `insert_before/after`, `append_child`, `delete`, `source_position`, editable `url/title/header_level/fence_info/alert_type`, and `to_commonmark` for round-tripping.
  - Syntax highlighting uses a syntect plugin. The default theme is `base16-ocean.dark` (others: InspiredGitHub, Solarized, base16-*). Custom `.tmTheme` files load from a path, `theme: ""` emits CSS classes instead of inline styles, and `nil` disables highlighting.
  - Source: [commonmarker README](https://github.com/gjtorikian/commonmarker)
- comrak:
  - Version 0.59 per README (needs Rust 1.89+), compliant with CommonMark 0.31.2.
  - **No extensions are enabled by default** in the Rust crate. commonmarker sets its own defaults.
  - Raw HTML and dangerous links are scrubbed unless `unsafe` is set, with ammonia recommended when it is. The GFM tagfilter extension was deprecated in 0.55 and removed in 0.56.
  - Users: crates.io, docs.rs, lib.rs, GitLab, Deno. The README admits it "is not and will not be the fastest".
  - Source: [kivikakk/comrak](https://github.com/kivikakk/comrak)
- GitLab:
  - Renders through the `gitlab-glfm-markdown` gem (comrak) inside the Banzai pipeline: preprocess, then markdown to HTML, then HTML filters for references and emoji, then cache in the DB, then the Tiptap rich editor. — [GitLab GLFM dev docs](https://docs.gitlab.com/development/gitlab_flavored_markdown/)
  - The move from cmark-gfm to comrak happened behind the `markdown_rust` feature flag. — [GitLab MR !139825](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139825), [gitlab-glfm-markdown README](https://rubydoc.info/gems/gitlab-glfm-markdown/file/README.md)
- Benchmarks (self-reported, 11,064,832-byte input):
  - commonmarker current README (Ruby 3.3.0 arm64), in iterations/second: Markly.render_html 15.6, Commonmarker::Node.to_html 5.1, Commonmarker.to_html 4.5, Kramdown 0.4. Markly is ~3-3.5x faster than commonmarker, and kramdown is ~41x slower than Markly. — [commonmarker README](https://github.com/gjtorikian/commonmarker)
  - An older README showed Redcarpet ~22.3 i/s against CommonMarker ~5.8 i/s (~3.8x), with kramdown ~68x slower. — [rossta/commonmarker fork README](https://github.com/rossta/commonmarker), [rubydoc commonmarkercomrak](https://rubydoc.info/gems/commonmarkercomrak/file/README.md)
  - A 2014 thread measured redcarpet 0.127 s, cmark native 0.188 s and kramdown 14.7 s on 10 MB. — [talk.commonmark.org](https://talk.commonmark.org/t/wip-ruby-wrapper-for-libcmark/929)
- Redcarpet maintenance:
  - Maintainers are Robin Dupret and Matt Rogers. The repo has 101 open issues and 24 open PRs, and the README makes no CommonMark compliance claim. — [vmg/redcarpet](https://github.com/vmg/redcarpet)
  - New commits landed on master after the 3.6.1 release, all **unreleased** as of 2026-11-03:
    - "Give code spans precedence over link brackets" (2026-07-22).
    - "Keep backslash-escaped pipes inside table cells" (2026-10-06, by flavorjones).
    - "HTML_TOC: omit the footnotes block" (2026-10-10, merged 2026-10-14).
  - Source: [GitHub API redcarpet commits](https://api.github.com/repos/vmg/redcarpet/commits?per_page=8)
- Markly is a cmark-gfm (C) binding, which explains its speed lead in the benchmark above. — [commonmarker README benchmark](https://github.com/gjtorikian/commonmarker)

### Inferences
- Even at 4.5 i/s on 11 MB (~2.4 MB/s), a typical 2-10 KB article renders in about 1-4 ms with commonmarker. The speed gap against Redcarpet is irrelevant once rendered HTML is cached.
- The fixes now landing in Redcarpet (code-span precedence, escaped pipes) are long-standing CommonMark divergences. Fixing them individually means Redcarpet output still won't match what GitHub-trained LLM agents and other editors expect.
- kramdown (pure Ruby) is only worth it for kramdown-only syntax (IALs, abbreviations, definition lists, `{::options}`). Its cost is ~40-70x slower parsing and a non-CommonMark dialect.
- Migration hazards with commonmarker 2.x:
  - Set `hardbreaks: false` explicitly.
  - Pin the anchor markup, which changed in 2.9.0.
  - Use `theme: ""` so code is highlighted with CSS classes (themable with Papyro's Tailwind theme tokens), or keep Rouge by walking `code_block` nodes and replacing them.

### Gaps
- I did not run a local Redcarpet-vs-commonmarker benchmark on Ruby 4.0 because commonmarker is not installed and installing gems was out of scope. Recommended follow-up: `bundle exec ruby bench.rb` on real Papyro articles.
- I found no maintained Ruby binding for markdown-it (only JS-in-Ruby via ExecJS/mini_racer, unverified).
- The current kramdown and kramdown-parser-gfm versions were not fetched.
- Which Rails apps beyond GitLab use which renderer is unverified. GitHub's server side reportedly still uses its cmark-gfm fork, but I did not re-verify this. The `ActionText::Markdown`/`has_markdown` pattern Papyro uses with Redcarpet resembles 37signals' Writebook. That attribution is unverified this session, and the 2026 Redcarpet commits by flavorjones (Mike Dalessio) may relate to it.

---

## 3. Sanitization and security

### Takeaway
Render with raw HTML disabled, either commonmarker `unsafe: false` or Redcarpet `escape_html`/`filter_html` plus `safe_links_only`. Then run a custom allowlist sanitizer (Loofah scrubber or `Rails::HTML5::SafeListSanitizer` with explicit tags and attributes) as the single final step, and mark the output `html_safe` only after that. Rails' default allowlist is too narrow for markdown: it drops tables, ids and task-list inputs (verified locally).

### Cited Findings
- Redcarpet options: `filter_html` removes user HTML. `escape_html` escapes it and overrides `no_styles/no_links/no_images/filter_html`. `safe_links_only` restricts link protocols. Papyro currently sets `filter_html: false` and none of the others. — [vmg/redcarpet](https://github.com/vmg/redcarpet); `lib/rails_ext/action_text_markdown.rb`
- commonmarker/comrak scrub raw HTML and "potentially dangerous links" (`javascript:` and similar) unless `unsafe: true`, and comrak recommends a sanitizer (ammonia) when raw HTML is enabled. — [commonmarker README](https://github.com/gjtorikian/commonmarker), [comrak](https://github.com/kivikakk/comrak)
- commonmarker 2.10.1 fixed a DoS: a native stack overflow on deeply nested input (GHSA-c4fj-h48v-9fxp), and `max_nesting_depth` defaults to 1000. Papyro should run ≥ 2.10.1. — [CHANGELOG](https://raw.githubusercontent.com/gjtorikian/commonmarker/main/CHANGELOG.md), [README](https://github.com/gjtorikian/commonmarker)
- Rails SafeList defaults (rails-html-sanitizer 1.7.1) strip `table*`, `input`, `figure`, `section`, `svg`, `id`, `aria-*`, `data-*` and `style`, and they neutralize `javascript:` hrefs. Verified with `bin/rails runner` (see section 0).
- Mermaid `securityLevel`:
  - `strict` (default) encodes HTML in labels and disables click handlers.
  - `antiscript` allows HTML but removes scripts.
  - `loose` allows HTML and clicks.
  - `sandbox` renders inside a sandboxed iframe, which disables interactivity.
  - Source: [mermaid usage docs](https://mermaid.js.org/config/usage.html)

### Inferences
- Recommended allowlist additions for Papyro:
  - Tags: `table thead tbody tr th td`, `input[type=checkbox][disabled][checked]`, `section`/`sup`/`ol` for footnotes, `figure figcaption`, `details summary` (foldable callouts).
  - Attributes: `id` on headings and footnotes, `aria-hidden`, `aria-label`, `data-footnote-ref`/`data-footnotes`, alert classes, and the lightbox `data-action`/`data-lightbox-url-value`.
  - Table alignment: allow `align`, or map comrak's `align` or `style` to classes in a post-filter.
- For links, add `rel="noopener nofollow ugc"` and `target="_blank"` to external links in a post-render Nokogiri/Loofah pass, not in the renderer. That way preview and public share it, and internal `/u/` uploads stay untouched.
- Escape every interpolated value in the custom `image` override with `ERB::Util.html_escape`, or build the tag via an AST/Nokogiri node.
- Keep Mermaid source as text inside `<pre class="mermaid">` in the stored HTML so the sanitizer never has to trust SVG. If SVG is server-generated, sanitize it with an SVG-aware allowlist or serve it as an `<img src>` file so its scripts cannot run.

### Gaps
- I did not fetch the rails-html-sanitizer or Loofah docs. The verified behaviour above comes from running the installed gems, not from documentation.

---

## 4. Rendering for SEO and performance (server HTML, caching, anchors, TOC, reading time, excerpts, Spanish typography)

### Takeaway
Render markdown to HTML on the server once per content version and cache it, either in a column or Solid Cache keyed by the content digest plus renderer version. Derive the TOC, reading time and OG excerpt from the AST or the rendered HTML in the same pass. Only diagrams and math need client-side enhancement, and their source text should remain in the HTML for crawlers. GitLab's Banzai pipeline is the reference architecture: parse, then HTML filters, then a DB cache.

### Cited Findings
- GitLab caches the rendered HTML in the database after the filter pipeline. — [GitLab GLFM dev docs](https://docs.gitlab.com/development/gitlab_flavored_markdown/)
- commonmarker exposes `header_ids` (anchor prefix) and AST walking, so the TOC can be built by walking `heading` nodes. `to_commonmark` and `string_content` support plain-text extraction for excerpts. — [commonmarker README](https://github.com/gjtorikian/commonmarker)
- Redcarpet ships `HTML_TOC` and `StripDown` (plain text) renderers plus `SmartyPants`. A 2026 unreleased commit makes HTML_TOC omit the footnotes block. — [redcarpet](https://github.com/vmg/redcarpet), [commits](https://api.github.com/repos/vmg/redcarpet/commits?per_page=8)
- commonmarker 2.10.1 reuses the CSS syntax highlighter across renders, a performance improvement for repeated rendering. — [CHANGELOG](https://raw.githubusercontent.com/gjtorikian/commonmarker/main/CHANGELOG.md)
- Papyro's `MarkdownRenderer.build` creates a new renderer per call, and `content_html` renders on every request with no cache (`app/concepts/articles/presenter/show.rb`). Reading time is computed from word count / `WORDS_PER_MINUTE` in the presenter.

### Inferences
- Suggested pipeline, mirroring Banzai:
  1. `Markdown::Parse` (commonmarker, `unsafe: false`, `hardbreaks: false`, extensions table, tasklist, strikethrough, autolink, footnotes, alerts, header_ids, math_code/math_dollars, front_matter).
  2. AST passes: collect headings for the TOC, rewrite images to figures and lightbox, tag mermaid and math fences.
  3. HTML render.
  4. Nokogiri post-filters: external link rel/target, `/u/` upload URL normalization, lazy `loading="lazy"` on images.
  5. Sanitize with the custom allowlist.
  6. Cache by `[content_digest, locale, RENDERER_VERSION]`.

  The Studio preview should call the exact same service, skipping only the cache, so preview equals publish.
- Spanish typography:
  - Redcarpet's SmartyPants and comrak's `smart` option produce English curly quotes ("…" and ‘…’), not Spanish angular quotes « ».
  - Locale-aware quotes (« » for es, " " for en) and non-breaking spaces need a custom text-node pass keyed on `locale:`, which already flows through Mobility.
  - The heading slug function should keep or transliterate ñ/á consistently across locales, since translated slugs affect anchors per locale.
- OG/meta excerpt: take the first paragraph's plain text from the AST, skip headings, alerts and code, and truncate to ~155-160 chars on a word boundary. Do not truncate HTML.

### Gaps
- I did not verify that comrak's `smart` punctuation option is exposed in commonmarker 2.10, or whether it supports locale-specific quotes. It likely does not, but that is unconfirmed.
- No source was fetched on Google's handling of client-rendered Mermaid/KaTeX content for indexing.

---

## 5. Diagram rendering options (mermaid-cli/server SVG, Kroki, client mermaid.js lazy-loaded)

### Takeaway
For a Rails/importmap app the pragmatic default is client-side Mermaid 12, lazy-loaded through a Stimulus controller only when a `pre.mermaid` exists, with `securityLevel: 'strict'` and the source text kept in the HTML. Server-side SVG (mermaid-cli/Puppeteer, or self-hosted Kroki) is heavier operationally. It is only worth it if diagrams must appear in RSS/email/OG images or without JavaScript.

### Cited Findings
- Mermaid 12.3.0 ships an ESM build importable from a CDN. `startOnLoad: false` plus `mermaid.run({ nodes })` gives explicit control. The full build lazy-loads diagram types and the Tiny build does not. — [mermaid usage docs](https://mermaid.js.org/config/usage.html)
- GitHub renders mermaid fences and lets users query the version with an `info` diagram. — [GitHub diagrams docs](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams)
- Kroki (per secondary sources):
  - It is an HTTP API returning SVG for 25+ diagram languages. The public kroki.io is rate-limited, and self-hosting a container is recommended for real traffic. Renderers should fall back to client-side on error.
  - Source: [tinkerdown diagrams package docs](https://pkg.go.dev/github.com/livetemplate/tinkerdown/internal/diagrams), [secondary skill page](https://skills.sh/erichowens/some_claude_skills/mermaid-graph-renderer). These are low-authority sources.
- mermaid-cli (per secondary sources):
  - It runs headless Chromium via Puppeteer (~280 MB footprint).
  - Its SVGs contain `<foreignObject>` (HTML labels) unless `htmlLabels: false` is set.
  - Reported latency is roughly 0.5-3 s per diagram, and the reported figures conflict.
  - Source: [secondary skill page](https://skills.sh/erichowens/some_claude_skills/mermaid-graph-renderer). Low-authority, treat the numbers as rough.

### Inferences
- Server-side SVG with `<foreignObject>` is incompatible with a strict HTML sanitizer, and SVG must not pass through the article allowlist. If going server-side:
  - Render in a Solid Queue job at publish time (not during preview keystrokes).
  - Store the SVG as an Active Storage file and reference it as `<img>`. That keeps scripts inert and makes the SVG cacheable.
- Client-side approach for importmap:
  - Pin mermaid. A dynamic `import()` inside a `mermaid` Stimulus controller's `connect()` keeps the ~MB bundle off pages without diagrams.
  - Re-run on `turbo:render` and on preview frame updates, and cleanly ignore parse errors (`suppressErrors`).
- Math should follow the same pattern: comrak emits math markup and a lazily loaded KaTeX auto-render runs client-side. Server-side KaTeX would need a JS runtime from Ruby (ExecJS/mini_racer), which is unverified.

### Gaps
- No primary Kroki docs (kroki.io) or mermaid-cli README were fetched this session. Kroki's supported-language count, its Mermaid version and mermaid-cli's current version are unverified.
- No authoritative benchmark of server-side Mermaid rendering latency was found.

---

## 6. Spec compliance and dialect divergence (portability for agents/LLMs)

### Takeaway
Divergent dialects cost portability. Markdown written by humans or LLMs (which default to GFM, GitHub alerts and ```` ```mermaid ````) should render the same in Papyro's preview, its public page and other tools. Redcarpet's pre-CommonMark parsing (code spans vs links, escaped pipes, `lax_spacing`, no task lists or alerts) breaks that. A comrak-based renderer passing 652/652 CommonMark and 670/670 GFM tests minimizes surprises.

### Cited Findings
- comrak passes 652/652 CommonMark 0.31.2 and 670/670 GFM spec tests. — [comrak](https://github.com/kivikakk/comrak)
- Redcarpet's README makes no CommonMark claim and warns that output varies across renderers. It only fixed "code spans precedence over link brackets" and "backslash-escaped pipes in table cells" on master in July and October 2026, and those fixes are still unreleased. — [redcarpet](https://github.com/vmg/redcarpet), [commits](https://api.github.com/repos/vmg/redcarpet/commits?per_page=8)
- GitLab explicitly aims for 100% CommonMark compliance and adds new syntax "only when truly necessary". — [GitLab GLFM dev docs](https://docs.gitlab.com/development/gitlab_flavored_markdown/)
- Callout syntax divergence: GitHub uses `> [!NOTE]` (5 types, no nesting), Obsidian `> [!type]±` (13+ types, foldable, nestable), and Docusaurus `:::note[Title]` directives. — [GitHub](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax), [Obsidian](https://obsidian.md/help/callouts), [Docusaurus](https://docusaurus.io/docs/markdown-features/admonitions)
- Math delimiter divergence: GitHub supports `$…$`, ``$`…`$``, `$$…$$` and ```` ```math ````, and comrak supports all of these behind separate options (`math_dollars`, `math_code`, `math_latex`). — [GitHub math](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/writing-mathematical-expressions), [commonmarker](https://github.com/gjtorikian/commonmarker)

### Inferences
- For Papyro, I'd recommend choosing "GFM + footnotes + GitHub alerts (optionally accepting Obsidian's `+/-` and extra types and mapping them onto the 5 GitHub types) + mermaid fences + GitHub math delimiters" as the documented dialect. That dialect is what LLMs emit by default and what GitHub, GitLab, Obsidian and comrak all parse.
- Avoid inventing directive or shortcode syntax for embeds and figures. Bare-URL-on-its-own-line auto-embeds and image title → figcaption degrade gracefully to valid CommonMark elsewhere.
- Enabling `$` math has a real cost for an editorial (non-technical, Spanish/English) audience: prose containing prices ("$5 and $10") can be misparsed as math. Prefer ```` ```math ```` plus ``$`…`$`` only (comrak `math_code`), or keep `$` math opt-in per article.

### Gaps
- No empirical study was found that quantifies LLM output-dialect frequencies (alerts vs directives, `$` vs fences). The default-to-GFM claim is an inference from platform prevalence.
