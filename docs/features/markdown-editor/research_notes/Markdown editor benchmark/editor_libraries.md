# Embeddable web editor libraries for a markdown editor in Papyro (Rails 8.1, importmap, Hotwire, Phlex)

Snapshot date: 2026-11-03. Version, stars, release dates and dependency counts were pulled live on that date from the GitHub REST API (`gh api repos/<repo>` and `/releases`), the npm registry (`registry.npmjs.org/<pkg>`) and the Bundlephobia API (`bundlephobia.com/api/size`). Each row cites the repo, npm and Bundlephobia pages the numbers came from. Bundlephobia numbers are for the whole package entry point, including its bundled dependencies (no tree-shaking). They show order of magnitude, not exact importmap payload.

Labelling convention: anything marked **[background, not re-verified]** comes from the researcher's prior knowledge and was NOT confirmed by a source fetched in this pass. The report writer should treat those items as leads, not facts.

## Q1. Editing model and markdown round-trip fidelity

### Takeaway
There are two families. **Source-of-truth editors** keep the markdown string as the document and only decorate it: CodeMirror 6, Overtype, EasyMDE, Marksmith, ink-mde, Vditor's SV/IR modes. These preserve the user's bytes exactly. **Doc-model editors** parse markdown into a tree and re-serialize it: ProseMirror/TipTap, Milkdown/Crepe, Lexical/MDXEditor/Lexxy, BlockNote, Plate, Toast UI. These normalize the markdown and have documented lossy cases, including tables limited to one block per cell, footnotes, comments, escaping and custom syntax. For a markdown-stored, agent-edited corpus the difference matters a lot.

### Cited Findings

#### Comparison table (snapshot 2026-11-03)

| Library | Editing model | Latest version / date | GitHub stars | Licence | Gzip size (Bundlephobia, entry pkg) | Framework coupling | Maintenance flag |
|---|---|---|---|---|---|---|---|
| CodeMirror 6 (`@codemirror/view`, `@codemirror/lang-markdown`) | Source + decorations (markdown text is the doc) | view 6.43.15 (2026-10-19); lang-markdown 6.5.2 (2026-08-04); meta pkg `codemirror` 6.0.2 | 7,807 (GitHub repo **archived 2026-04-15**, moved to Forgejo) | MIT | view 77 KB; lang-markdown 170 KB (includes view/state/lezer deps); `codemirror` meta 115 KB | Vanilla | Active (development moved off GitHub) |
| ProseMirror (`prosemirror-view`, `prosemirror-markdown`) | WYSIWYM doc model; markdown via parser/serializer | view 1.42.9 (2026-10-31); markdown 1.13.9 (2026-10-22) | 8,693 (GitHub **archived**, moved to Forgejo) | MIT | view 53 KB; prosemirror-markdown 68 KB | Vanilla | Active |
| TipTap v3 (`@tiptap/core`, `@tiptap/markdown`) | Doc model (ProseMirror) + MarkedJS-based markdown parse/serialize | v3.32.0 GH release 2026-10-13; npm 3.32.2 (2026-10-30) | 38,944 | MIT core; Pro/AI add-ons paid | core 36 KB; markdown 18 KB; starter-kit 105 KB | Vanilla core (React/Vue wrappers optional) | Very active |
| Milkdown (`@milkdown/kit`) / Crepe (`@milkdown/crepe`) | Doc model (ProseMirror + remark) | 7.23.0 (2026-10-27) | 12,040 | MIT | Crepe 452 KB (batteries-included); kit not measurable (re-export meta pkg) | Vanilla | Active |
| Lexical (`lexical`, `@lexical/markdown`) | Doc model; markdown via transformers | 0.53.0 (2026-10-28) | 23,993 (repo now `meta/lexical`) | MIT | lexical 67 KB; @lexical/markdown 80 KB | Vanilla core (React bindings optional) | Very active, still 0.x |
| Lexxy (`@37signals/lexxy`, gem `lexxy`) | WYSIWYG on Lexical; markdown is input-only (shortcuts/paste); stores Action Text HTML | 1.0.3 (2026-10-29); 1.0 announced 2026-09-28 | 1,253 | MIT | not measured (Bundlephobia error); depends on lexical 0.52 x 14 pkgs + marked + prismjs + dompurify | Vanilla custom element + Rails/Action Text | Active (new 1.0) |
| Trix | WYSIWYG, own doc model, HTML (Action Text) | 2.1.19 (2026-05-09) | 20,015 | MIT | 49 KB | Vanilla custom element | Maintained, being superseded by Lexxy at 37signals |
| BlockNote (`@blocknote/core`) | Block-based doc model on ProseMirror/TipTap | 0.57.0 (2026-10-30) | 10,352 | MPL-2.0 core; `@blocknote/xl-*` (incl. AI) GPL-3.0 or commercial | core 185 KB | React UI (core is framework-agnostic but the UI is React) | Very active, 0.x |
| MDXEditor (`@mdxeditor/editor`) | Doc model on Lexical + mdast; has source and diff-source modes | 4.5.0 (2026-11-02) | 3,710 | MIT | 568 KB; 57 runtime deps | React only | Active |
| Plate (`platejs`; old `@udecode/plate`) | Doc model on Slate; markdown via plugin | platejs 53.5.2 (2026-10-30); `@udecode/plate` frozen at 49.0.0 (2025-06-11) | 16,686 | GitHub reports NOASSERTION (mixed; see Q6) | not measured | React only | Very active (package renamed) |
| Toast UI Editor (`@toast-ui/editor`) | Dual: markdown source pane + WYSIWYG pane (own ProseMirror-based WYSIWYG) | 3.2.2 (**2023-02-17**) | 17,988 (repo **archived**, last push 2024-08-01) | MIT | 157 KB | Vanilla | **Abandoned** |
| EasyMDE | Source + decorations (CodeMirror 5) + preview | 2.21.0 (2026-05-03) | 3,093 | MIT | 104 KB | Vanilla | Maintained, slow cadence |
| SimpleMDE | Source (CodeMirror 5) | 1.11.2 (**2016-06-14**) | 10,138 | MIT | n/a | Vanilla | **Abandoned** (use EasyMDE fork) |
| Vditor | Three modes: WYSIWYG, instant-render (IR), split-view source [background, not re-verified] | 4.0.1 (2026-10-18) | 11,428 | MIT | 68 KB entry (lazy-loads assets from CDN) [CDN loading: background] | Vanilla | Active |
| ByteMD | Source (CodeMirror) + preview, Svelte-based | 1.22.0 (**2025-02-12**) | 1,374 | MIT | 128 KB | Svelte core with vanilla/React/Vue wrappers [background] | **Stale** (no release in ~21 months) |
| Overtype | Source: transparent `<textarea>` over styled preview (no contentEditable) | 2.7.0 (2026-10-28) | 3,704 | MIT | 39 KB; 2 deps (`@floating-ui/dom`, `markdown-actions`) | Vanilla | Active (no GitHub releases, ships via npm) |
| ink-mde | Source (CodeMirror 6) with live-preview decorations | 0.34.0 (**2024-09-28**), last push 2026-07-31 | 304 | MIT | not measured | Vanilla (Vue/Svelte wrappers) [background] | **Stale releases** |
| codemirror-rich-markdoc | CodeMirror 6 live-preview demo (Markdoc) | no releases; last push **2024-11-20** | 124 | MIT | n/a | Vanilla | **Proof of concept, stale** |
| Rhino Editor | TipTap WYSIWYG for Action Text (HTML) | 0.18.6 (2026-10-29) | 337 | MIT | not measured; 19 deps | Vanilla custom element + Rails | Active, pre-1.0 |
| Marksmith (gem) | Plain `<textarea>` + GitHub `markdown-toolbar-element` + server preview tab | gem 0.4.7 (2025-08-07); last push 2026-08-14 | 555 | MIT | n/a (gem + small JS) | Rails engine, Stimulus + Turbo | Maintained, slow cadence |
| House (37signals, Writebook) | WYSIWYM markdown editor | not published as a standalone package (`github.com/basecamp/house-md` returns 404) | n/a | Ships inside Writebook | n/a | Rails/Action Text | **Not available standalone; 37signals moved on to Lexxy** |

Row sources:
- CodeMirror: [GitHub codemirror/dev](https://github.com/codemirror/dev), [npm @codemirror/view](https://www.npmjs.com/package/@codemirror/view), [npm @codemirror/lang-markdown](https://www.npmjs.com/package/@codemirror/lang-markdown), [Bundlephobia @codemirror/lang-markdown](https://bundlephobia.com/package/@codemirror/lang-markdown)
- ProseMirror: [GitHub ProseMirror/prosemirror](https://github.com/ProseMirror/prosemirror), [npm prosemirror-markdown](https://www.npmjs.com/package/prosemirror-markdown), [Bundlephobia prosemirror-view](https://bundlephobia.com/package/prosemirror-view)
- TipTap: [GitHub ueberdosis/tiptap](https://github.com/ueberdosis/tiptap), [npm @tiptap/markdown](https://www.npmjs.com/package/@tiptap/markdown), [Bundlephobia @tiptap/starter-kit](https://bundlephobia.com/package/@tiptap/starter-kit)
- Milkdown: [GitHub Milkdown/milkdown](https://github.com/Milkdown/milkdown), [npm @milkdown/crepe](https://www.npmjs.com/package/@milkdown/crepe), [Bundlephobia @milkdown/crepe](https://bundlephobia.com/package/@milkdown/crepe)
- Lexical: [GitHub meta/lexical](https://github.com/facebook/lexical), [npm @lexical/markdown](https://www.npmjs.com/package/@lexical/markdown)
- Lexxy: [GitHub basecamp/lexxy](https://github.com/basecamp/lexxy), [npm @37signals/lexxy](https://www.npmjs.com/package/@37signals/lexxy), [37signals Dev: Lexxy 1.0 is here](https://dev.37signals.com/lexxy-1-0/)
- Trix: [GitHub basecamp/trix](https://github.com/basecamp/trix)
- BlockNote: [GitHub TypeCellOS/BlockNote](https://github.com/TypeCellOS/BlockNote)
- MDXEditor: [GitHub mdx-editor/editor](https://github.com/mdx-editor/editor), [npm @mdxeditor/editor](https://www.npmjs.com/package/@mdxeditor/editor)
- Plate: [GitHub udecode/plate](https://github.com/udecode/plate), [npm platejs](https://www.npmjs.com/package/platejs), [npm @udecode/plate](https://www.npmjs.com/package/@udecode/plate)
- Toast UI: [GitHub nhn/tui.editor](https://github.com/nhn/tui.editor), [npm @toast-ui/editor](https://www.npmjs.com/package/@toast-ui/editor)
- EasyMDE / SimpleMDE: [GitHub Ionaru/easy-markdown-editor](https://github.com/Ionaru/easy-markdown-editor), [npm simplemde](https://www.npmjs.com/package/simplemde)
- Vditor: [GitHub Vanessa219/vditor](https://github.com/Vanessa219/vditor)
- ByteMD: [GitHub pd4d10/bytemd](https://github.com/pd4d10/bytemd)
- Overtype: [GitHub panphora/overtype](https://github.com/panphora/overtype), [npm overtype](https://www.npmjs.com/package/overtype)
- ink-mde: [GitHub davidmyersdev/ink-mde](https://github.com/davidmyersdev/ink-mde)
- codemirror-rich-markdoc: [GitHub segphault/codemirror-rich-markdoc](https://github.com/segphault/codemirror-rich-markdoc)
- Rhino: [GitHub KonnorRogers/rhino-editor](https://github.com/KonnorRogers/rhino-editor)
- Marksmith: [GitHub avo-hq/marksmith](https://github.com/avo-hq/marksmith)

#### Editing-model and fidelity findings
- TipTap's official `@tiptap/markdown` parses markdown to TipTap JSON with MarkedJS and serializes it back. The docs call it an "early release" that may change and have unsupported edge cases. Documented losses: comments are not supported, and table cells can hold only one child node because markdown cannot represent more. Set content with `contentType: 'markdown'`. Helpers `createBlockMarkdownSpec` and `createInlineMarkdownSpec` support custom syntax. — [TipTap Markdown docs](https://tiptap.dev/docs/editor/markdown)
- TipTap markdown export targets CommonMark. Footnotes are not supported, and math depends on a configured math extension. Re-importing exported markdown gives a simplified document, so anything lost on export does not come back. — [TipTap export markdown docs](https://tiptap.dev/docs/conversion/export/markdown/editor-extension)
- Lexical's `@lexical/markdown` ships element transformers (unordered/ordered list, code, heading, quote), text-format transformers (bold/italic variants, strikethrough, inline code) and one text-match transformer (link). Tables, footnotes and task lists are not in the built-in `TRANSFORMERS` set. The docs say export can differ from input: numeric character references for escaped brackets, conservative escaping of `<`/`&`, and changed characters in bare URLs to prevent autolinking. API: `$convertFromMarkdownString`, `$convertToMarkdownString`. — [Lexical markdown docs](https://lexical.dev/docs/packages/lexical-markdown)
- GitLab's rich text editor (TipTap + ProseMirror) deserializes by sending markdown to the server Markdown API, which returns HTML, then parses that HTML into ProseMirror. It serializes with `prosemirror-markdown`, with a custom serializer function per node type. It avoids `v-model` because getting and setting markdown is expensive. — [GitLab rich text editor dev guide](https://docs.gitlab.com/development/fe_guide/content_editor/)
- Discourse's rich composer builds on ProseMirror and its non-core markdown module (schema, parsing and serialization), and it is a mode of a composer that still stores markdown. — [Discourse Meta announcement](https://meta.discourse.org/t/369779), [ProseMirror forum](https://discuss.prosemirror.net/t/discourse-is-heading-towards-a-prosemirror-based-editor/8017)
- MDXEditor converts through Lexical and mdast (`importMarkdownToLexical` / `exportMarkdownFromLexical`). It exposes a diff-source plugin (`diffMarkdown$`, `readOnlyDiff$`), a frontmatter plugin and a markdown source-editor value. — [unpkg @mdxeditor/editor 3.52.4 dist](https://app.unpkg.com/@mdxeditor/editor@3.52.4/files/dist/index.js), [GitHub mdx-editor/editor](https://github.com/mdx-editor/editor)
- Milkdown is a headless, plugin-driven WYSIWYG markdown framework built on ProseMirror, Yjs and Remark. — [milkdown.dev](https://milkdown.dev)
- Overtype is a transparent textarea over a styled preview div. Syntax markers stay visible, and there is a plain mode showing the raw textarea. It avoids contentEditable. Its comparison table classes HyperMD, Milkdown and TUI Editor as contentEditable and EasyMDE as CodeMirror-based. Known limits: images break the character-grid alignment, and tables conflict with the monospace grid. — [GitHub panphora/overtype](https://github.com/panphora/overtype)
- Lexxy accepts markdown as input ("type Markdown and get rich text", auto-formatting on paste) and saves Action Text's canonical HTML ("What you see in the editor is what gets saved"). The 1.0 post does not describe markdown export. — [Lexxy 1.0 is here](https://dev.37signals.com/lexxy-1-0/), [Saeloun on Lexxy](https://blog.saeloun.com/2025/10/14/lexxy-editor/)
- 37signals built House as a WYSIWYM markdown editor for Writebook in 2024. When they tried it in another product in 2025 it "didn't fit", and they concluded "For most apps, WYSIWYG was just the right answer". — [Lexxy 1.0 is here](https://dev.37signals.com/lexxy-1-0/)
- Writebook's markdown editor is based on Action Text but uses House instead of Trix. — [Exploring Rails codebases: Writebook](https://kemenaran.winosx.com/posts/exploring-rails-codebases-writebook)
- Rhino Editor (TipTap for Action Text) does not support markdown yet. Its roadmap mentions a future ProseMirror-based integration for markdown + WYSIWYG. — [GitHub KonnorRogers/rhino-editor](https://github.com/KonnorRogers/rhino-editor)
- Marksmith is a plain textarea with GitHub's `markdown-toolbar-element`, a preview panel, list continuation and Active Storage uploads. Default rendering uses Commonmarker, so GFM tables and task lists render. — [Avo blog: Marksmith](https://avohq.io/blog/ruby-on-rails-markdown-editor-marksmith), [AppSignal: create a markdown editor in Rails](https://blog.appsignal.com/2025/12/10/create-a-markdown-editor-in-ruby-on-rails.html)

### Inferences
- For Papyro, where markdown is the stored format and AI agents will write patches against it, only the source-of-truth family (CodeMirror 6, Overtype, or the current textarea/Marksmith pattern) guarantees that the bytes an agent diffs against are the bytes the writer sees and saves. Every doc-model editor re-serializes on save, so opening and saving an article can churn whitespace, list markers, emphasis style, escaping and table alignment. That produces noisy diffs and can silently drop footnotes, reference-link definitions or HTML blocks, depending on schema coverage.
- Doc-model editors are viable only if Papyro treats the editor's serializer as canonical and normalizes stored markdown once, for example a migration that round-trips every article and diffs the result. Agents would then always be given serializer-normalized markdown.
- The "live preview" middle ground (Obsidian-style: CodeMirror 6 decorations that hide syntax off the cursor line) keeps byte fidelity and still looks rich. Off-the-shelf packages for it are thin and stale (ink-mde last released 2024-09, codemirror-rich-markdoc a 2024 demo), so Papyro would likely build its own decorations on `@codemirror/lang-markdown`'s Lezer tree.
- Reference links, footnotes and raw HTML blocks are the riskiest round-trip cases for TipTap and Lexical, based on the documented gaps above (no footnotes in TipTap export, no footnote, table or task-list transformers in Lexical's default set).

### Gaps
- No byte-level round-trip test results were found for Milkdown/Crepe, BlockNote, MDXEditor or Plate. Their docs fetched here do not state preservation guarantees. A small fixture corpus (tables, nested lists, HTML blocks, footnotes, reference links) run through each serializer would settle it.
- Whether `prosemirror-markdown` / GitLab's serializer preserves source details (list marker, emphasis char) was not documented in sources found.
- House's source and licence could not be verified. `basecamp/house-md` is not a public GitHub repo, and the name "action_text-markdown" turned up no package. A third-party review disagrees on whether Writebook is MIT or source-available ([daveswift.com](https://daveswift.com/writebook/)).

## Q2. Extended syntax support (GFM tables + table UI, task lists, footnotes, code highlighting, Mermaid, KaTeX, callouts, embeds, frontmatter)

### Takeaway
Most syntax coverage comes from plugins, not defaults. TipTap's markdown supports GFM tables (one block per cell) but no footnotes. Lexical's default transformers cover none of tables, footnotes or task lists. Lexxy 1.0 adds tables and highlighting in 20+ languages, but stored as HTML. Marksmith/Commonmarker covers GFM on render only. MDXEditor has frontmatter and source/diff modes. For a source editor like CodeMirror, Papyro decides syntax support in its server renderer (Redcarpet today), not in the editor.

### Cited Findings
- TipTap markdown supports GFM-style tables (one child node per cell) and custom tokenizers for non-standard syntax. Embedded HTML goes through TipTap's HTML parser. — [TipTap Markdown docs](https://tiptap.dev/docs/editor/markdown)
- TipTap markdown export does not support footnotes. Math depends on a configured math extension. — [TipTap export docs](https://tiptap.dev/docs/conversion/export/markdown/editor-extension)
- Lexical's built-in markdown transformers do not include tables, footnotes or task lists. Tables are mentioned only as something a custom element transformer could handle. — [Lexical markdown docs](https://lexical.dev/docs/packages/lexical-markdown)
- Lexxy 1.0 ships tables "simple and accessible", code blocks with highlighting in "more than twenty languages", image galleries, prompts (mentions/emoji), attachment previews (video, PDF) and a colour highlighter. It is built from thirteen extensions. — [Lexxy 1.0 is here](https://dev.37signals.com/lexxy-1-0/)
- Lexxy's npm dependencies include `@lexical/table`, `@lexical/code-prism`/`prismjs`, `marked` and `dompurify`. — [npm @37signals/lexxy](https://www.npmjs.com/package/@37signals/lexxy)
- MDXEditor's README lists tables, images, code blocks and JSX component editing. Its build exports frontmatter and diff-source plugins. — [GitHub mdx-editor/editor](https://github.com/mdx-editor/editor), [unpkg dist](https://app.unpkg.com/@mdxeditor/editor@3.52.4/files/dist/index.js)
- Marksmith's default Commonmarker renderer gives GFM tables and task lists. Shortcodes need a custom renderer. — [Avo blog: Marksmith](https://avohq.io/blog/ruby-on-rails-markdown-editor-marksmith), [Avo: Marksmith shortcodes](https://avohq.io/blog/marksmith-shortcodes)
- Overtype's architecture has trouble with images and tables. — [GitHub panphora/overtype](https://github.com/panphora/overtype)
- [background, not re-verified] Milkdown Crepe bundles CodeMirror code blocks, KaTeX math, tables with a table UI, slash menu and image blocks. Vditor supports Mermaid, KaTeX/MathJax, ECharts, Graphviz and more out of the box. ByteMD has plugins for GFM, math, Mermaid, highlight and frontmatter. These would explain Crepe's 452 KB gzip size ([Bundlephobia](https://bundlephobia.com/package/@milkdown/crepe)).

### Inferences
- With a CodeMirror/textarea-style editor, extended syntax (footnotes, callouts, Mermaid, KaTeX, embeds) is a renderer concern. Papyro would extend its Redcarpet/Commonmarker preview pipeline and add optional CodeMirror highlighting per syntax. This keeps the editor dependency-light. Redcarpet itself lacks task lists and footnote variants that Commonmarker supports, so a renderer switch may be needed regardless of editor.
- A table-editing UI (insert row/column, cell navigation) is the one feature that strongly favours doc-model editors. Source editors would need a custom "format table" command or a small table-grid widget.

### Gaps
- No verified, sourced list of Crepe's built-in features, Vditor's diagram support or ByteMD's plugin list was fetched. Check milkdown.dev/docs/guide/using-crepe, the Vditor README and the ByteMD README.
- Callout/admonition syntax support (GitHub `> [!NOTE]`) was not confirmed for any library.

## Q3. Integration cost with importmap (no bundler), Stimulus wrapping, Turbo pitfalls

### Takeaway
Small vanilla ESM libraries (Overtype 2 deps, Trix 1 dep, Marksmith's textarea + toolbar element) are near-zero cost under importmap. Multi-package ESM ecosystems (CodeMirror 6, ProseMirror/TipTap, Lexical) work but need many pins, all at mutually consistent versions. React-only editors (MDXEditor 57 deps, BlockNote's UI, Plate) are a poor fit for importmap + Phlex. Lexxy is the only rich editor shipping first-party Rails/importmap integration, but it stores HTML, not markdown.

### Cited Findings
- Runtime dependency counts from the npm registry on 2026-11-03: `@codemirror/lang-markdown` 7, `@milkdown/kit` 21, `@milkdown/crepe` 17, `@blocknote/core` 19, `@mdxeditor/editor` 57, `bytemd` 19, `rhino-editor` 19, `@37signals/lexxy` 18, `ink-mde` 15, `overtype` 2, `trix` 1, `vditor` 1, `@tiptap/core` 0 (peer deps), `lexical` 1. — [npm registry](https://www.npmjs.com/) (per-package pages linked in Q1)
- Bundlephobia gzip sizes (entry package with deps): Overtype 39 KB, Trix 49 KB, prosemirror-view 53 KB, lexical 67 KB, Vditor 68 KB, @codemirror/view 77 KB, @lexical/markdown 80 KB, EasyMDE 104 KB, @tiptap/starter-kit 105 KB, `codemirror` meta 115 KB, ByteMD 128 KB, Toast UI 157 KB, @codemirror/lang-markdown 170 KB, @blocknote/core 185 KB, Crepe 452 KB, MDXEditor 568 KB. — [Bundlephobia](https://bundlephobia.com/) (per-package pages linked in Q1)
- Lexxy has a peer dependency on `@rails/activestorage >= 7.0.0` and is enabled in Action Text with `config.action_text.editor = :lexxy`. — [npm @37signals/lexxy](https://www.npmjs.com/package/@37signals/lexxy), [Lexxy 1.0 is here](https://dev.37signals.com/lexxy-1-0/)
- Marksmith requires Stimulus and Turbo, installs with `bin/rails generate marksmith:install`, and renders through a helper or form-builder method. — [Avo blog: Marksmith](https://avohq.io/blog/ruby-on-rails-markdown-editor-marksmith), [AppSignal tutorial](https://blog.appsignal.com/2025/12/10/create-a-markdown-editor-in-ruby-on-rails.html)
- Overtype loads from npm or a CDN and is roughly 100 KB unminified. jsDelivr lists it as MIT. — [jsDelivr overtype](https://www.jsdelivr.com/package/npm/overtype), [GitHub panphora/overtype](https://github.com/panphora/overtype)
- MDXEditor, BlockNote's UI and Plate are React components. — [GitHub mdx-editor/editor](https://github.com/mdx-editor/editor), [GitHub TypeCellOS/BlockNote](https://github.com/TypeCellOS/BlockNote), [GitHub udecode/plate](https://github.com/udecode/plate)
- GitLab's Vue wrapper avoids `v-model` because markdown get/set is expensive, and listens to `@change` instead. This is the same pattern a Stimulus wrapper should follow: serialize lazily on submit or debounced change. — [GitLab rich text editor dev guide](https://docs.gitlab.com/development/fe_guide/content_editor/)

### Inferences
- [background, not re-verified] CodeMirror 6 needs one instance each of `@codemirror/state` and `@codemirror/view`. If two pins resolve different versions (common with `bin/importmap pin` pulling transitive copies from jsDelivr/jspm), extensions fail with an "Unrecognized extension value… multiple instances of @codemirror/state" error. ProseMirror has the same single-instance constraint for `prosemirror-model`/`prosemirror-state`, which TipTap inherits. Under importmap, pin every package explicitly at a deduped version, or vendor a pre-built single ESM file (e.g. an esm.sh bundle) into `vendor/javascript`.
- [background, not re-verified] Turbo pitfalls for any JS editor wrapped in Stimulus: mount in `connect()`, destroy in `disconnect()`. Turbo's snapshot cache captures the mounted editor DOM, so on restoration visits the controller reconnects on already-initialized markup and double-mounts unless the controller detects this or the element is reset. Typical mitigations: keep the hidden `<textarea>` as the source of truth and rebuild the editor from it, or mark the editor container `data-turbo-temporary`/clean up on `turbo:before-cache`. Turbo morphing (page refresh with `morph`) can also clobber editor DOM unless the container is excluded from morphing (`data-turbo-permanent` or a morph-ignore approach).
- Keeping a real `<textarea name="article[body]">` that the editor syncs into means the existing form, contract validation, server preview tab and Redcarpet pipeline stay unchanged. Overtype and CodeMirror fit this progressive-enhancement shape best. Doc-model editors need a serialize-on-submit hook.
- React-based options (MDXEditor, BlockNote UI, Plate) would mean adding React + ReactDOM pins and a JSX-free build of each component, against the project's Phlex/Stimulus architecture. Recommend excluding them, or using BlockNote only via its vanilla core.

### Gaps
- No published Stimulus wrapper examples for CodeMirror 6, TipTap or Milkdown were fetched in this pass. No measured importmap payloads (actual number of HTTP requests and bytes for a pinned CodeMirror markdown setup) were found. Pin each candidate in a spike branch and record `bin/importmap json` plus network totals.
- Whether jsDelivr's `+esm` builds or esm.sh dedupe CodeMirror/ProseMirror singletons correctly was not verified.

## Q4. Collaboration (Yjs/CRDT, comments, suggestions/track changes, presence)

### Takeaway
Every major engine has a Yjs binding: ProseMirror/TipTap, Lexical, CodeMirror, Milkdown, BlockNote. Comments, suggestions and tracked changes are where they differ. TipTap sells Tracked Changes and AI suggestions as paid add-ons. BlockNote's advanced features sit behind GPL/commercial XL packages. Lexxy 1.0 and the Rails-native editors (Trix, Rhino, Marksmith) have no collaboration.

### Cited Findings
- Milkdown integrates Yjs for collaborative editing, with a documented Yjs binding. — [milkdown.dev](https://milkdown.dev), [Yjs docs: Milkdown binding](https://docs.yjs.dev/ecosystem/editor-bindings/milkdown)
- TipTap Tracked Changes tracks insertions, deletions and replacements, supports accepting or rejecting individually or in bulk with per-user attribution, and can show AI rewrites as reviewable suggestions. It is a paid add-on with custom pricing. — [TipTap pricing](https://tiptap.dev/pricing.md)
- TipTap's roadmap lists a native "suggestion mode" pilot where humans and AI leave inline suggestions with justifications. — [TipTap roadmap](https://tiptap.dev/roadmap)
- The Lexxy 1.0 announcement does not mention collaboration. — [Lexxy 1.0 is here](https://dev.37signals.com/lexxy-1-0/)
- Rhino Editor's collaboration extension is an unchecked roadmap item. — [GitHub KonnorRogers/rhino-editor](https://github.com/KonnorRogers/rhino-editor)
- [background, not re-verified] Yjs bindings exist for CodeMirror 6 (`y-codemirror.next`), ProseMirror (`y-prosemirror`, used by TipTap's Collaboration extension and BlockNote) and Lexical (`@lexical/yjs`). CodeMirror also has its own OT-style `@codemirror/collab` package. TipTap's hosted collaboration backend (TipTap Cloud / Hocuspocus) is open source as Hocuspocus, with a paid hosted tier.

### Inferences
- Yjs over Action Cable is possible but needs a Yjs provider adapter and persisting Y.Doc updates, which Papyro does not have today. With markdown stored as text, CodeMirror + `y-codemirror.next` gives CRDT text collaboration whose merged state is still the plain markdown string. A doc-model Y.Doc instead has to be serialized to markdown on save, adding a normalization point.
- For writer + agent co-editing, real-time CRDT may be less important than a reviewable suggestion layer: agent proposes, human accepts or rejects. In the open-source tier only TipTap's paid add-ons and MDXEditor's diff-source mode provide this ready-made. With a source editor, Papyro can build it as CodeMirror decorations over a server-computed text diff (see Q5).

### Gaps
- Current versions, maintenance and licences of y-codemirror.next, y-prosemirror and @lexical/yjs were not fetched.
- No source found on BlockNote's comments feature licence tier (whether comments are in core MPL or XL).

## Q5. AI / agent hooks (inline AI, streaming insertion, diff/suggestion rendering, programmatic edit API)

### Takeaway
Ready-made AI integration is a commercial or copyleft upsell: the TipTap AI Toolkit (paid, private registry), BlockNote `@blocknote/xl-ai` (GPL-3.0 or Business licence) and the Plate AI plugin. None of these speak markdown natively; they patch the doc model. For agents editing stored markdown, the simplest robust hook is a source editor with a transaction API (CodeMirror `dispatch({changes})`) plus diff decorations. MDXEditor's diff-source mode is the only off-the-shelf "markdown diff" view found.

### Cited Findings
- The TipTap AI Toolkit is a Pro package from a private npm registry. It offers context-aware editing with selections, read/insert/patch of document content, schema awareness, display and review of AI suggestions, and document compare/diff. — [TipTap AI Toolkit overview](https://tiptap.dev/docs/content-ai/capabilities/ai-toolkit/overview.md), [TipTap Edit workflow](https://tiptap.dev/docs/content-ai/capabilities/ai-toolkit/workflows/tiptap-edit)
- AI Toolkit suggestions are decoration-based and ephemeral, visible only to the current user. Persistent shared review needs the separate Tracked Changes add-on. — [TipTap pricing](https://tiptap.dev/pricing.md), [TipTap AI Toolkit overview](https://tiptap.dev/docs/content-ai/capabilities/ai-toolkit/overview.md)
- AI Toolkit and Tracked Changes are listed as paid add-ons with "custom" pricing (contact sales). A competitor's blog cites $49/$149/$999 monthly tiers and the free plan's removal in June 2025. That source is promotional and unconfirmed. — [TipTap pricing](https://tiptap.dev/pricing.md); unverified figures: [DEV Community (Eddyter)](https://dev.to/eddyter/tiptap-pricing-explained-2026-free-vs-pro-vs-cloud-cost-breakdown-3l5g)
- BlockNote's AI ships in `@blocknote/xl-ai`, under GPL-3.0 or a commercial licence that comes with the Business subscription. — [BlockNote AI docs](https://www.blocknotejs.org/docs/features/ai), [GitHub TypeCellOS/BlockNote](https://github.com/TypeCellOS/BlockNote)
- MDXEditor exposes a diff-source plugin (`diffMarkdown$`, `readOnlyDiff$`) to show markdown against a baseline. — [unpkg @mdxeditor/editor dist](https://app.unpkg.com/@mdxeditor/editor@3.52.4/files/dist/index.js)
- TipTap accepts markdown through `editor.commands.insertContent(markdownString)` when the Markdown extension is loaded, a natural target for streamed agent output. — [TipTap Markdown docs](https://tiptap.dev/docs/editor/markdown)
- The Lexxy team used Claude from day one and moved system tests from Capybara to Playwright so agents could "write a test, see it fail, fix it". They report 600+ browser tests. This concerns development process, not an in-editor AI API. — [Lexxy 1.0 is here](https://dev.37signals.com/lexxy-1-0/)

### Inferences
- Agents work best on text: unified diffs, search/replace blocks, line ranges. A markdown source editor lets Papyro apply an agent patch to the same string the writer edits and render it as inline insert/delete decorations (CodeMirror `Decoration.mark`/`widget` over a diff computed server-side or with a JS diff library). Accept/reject becomes a CodeMirror transaction. This avoids paid AI toolkits and keeps edits auditable as plain-text diffs stored server-side (e.g. a `Studio::` revision/suggestion model).
- Streaming insertion is easy in both families. Source editors append text through transactions. TipTap can `insertContent` partial markdown, but partial markdown (an unclosed fence or table) parses differently mid-stream, so the doc-model render can flicker or restructure as tokens arrive.
- If Papyro ever chooses TipTap, budget for the paid AI Toolkit + Tracked Changes or plan to rebuild suggestion marks. The MIT core alone has no suggestion or track-changes layer, according to the pricing page.

### Gaps
- The Plate AI plugin's licence and markdown streaming behaviour were not fetched.
- No source found documenting an AI or suggestion API for Milkdown or Lexical core.

## Q6. Licence, maintenance health, accessibility, mobile/IME

### Takeaway
Healthy and MIT: CodeMirror 6, ProseMirror, TipTap core, Lexical, Milkdown, Lexxy, Overtype, Vditor, MDXEditor, Trix. Copyleft or paid tiers: BlockNote XL (GPL-3.0), TipTap Pro/AI (paid), Plate (mixed). Abandoned or stale: Toast UI Editor (archived, last release Feb 2023), SimpleMDE (2016), ByteMD (Feb 2025), ink-mde (Sept 2024), codemirror-rich-markdoc (2024 demo). House is not publicly available. CodeMirror and ProseMirror left GitHub for a self-hosted Forgejo in 2026. The archived GitHub repos are NOT abandonment.

### Cited Findings
- The CodeMirror GitHub repos were archived on 2026-04-15 and moved to the maintainer's Forgejo at code.haverbeke.berlin, to reduce dependence on GitHub. ProseMirror migrated first, keeping the same repo structure. — [CodeMirror's migration to Forgejo](https://discuss.codemirror.net/t/codemirrors-migration-to-forgejo/9706), [ProseMirror's migration to Forgejo](https://discuss.prosemirror.net/t/prosemirrors-migration-to-forgejo/8974)
- Active npm releases after the move: `@codemirror/view` 6.43.15 (2026-10-19), `prosemirror-view` 1.42.9 (2026-10-31). — [npm @codemirror/view](https://www.npmjs.com/package/@codemirror/view), [npm prosemirror-view](https://www.npmjs.com/package/prosemirror-view)
- Toast UI Editor's GitHub repo is archived, last pushed 2024-08-01. The latest npm release is 3.2.2 from 2023-02-17. — [GitHub nhn/tui.editor](https://github.com/nhn/tui.editor), [npm @toast-ui/editor](https://www.npmjs.com/package/@toast-ui/editor)
- SimpleMDE's last npm release is 1.11.2 (2016-06-14). EasyMDE, its maintained fork, released 2.21.0 on 2026-05-03. — [npm simplemde](https://www.npmjs.com/package/simplemde), [npm easymde](https://www.npmjs.com/package/easymde)
- ByteMD's last release is v1.22.0 (2025-02-12), with no push since. — [GitHub pd4d10/bytemd](https://github.com/pd4d10/bytemd)
- `@udecode/plate` stopped at 49.0.0 (2025-06-11). Development continues as `platejs` 53.5.2 (2026-10-30). — [npm @udecode/plate](https://www.npmjs.com/package/@udecode/plate), [npm platejs](https://www.npmjs.com/package/platejs)
- BlockNote is MPL-2.0 for most packages and GPL-3.0 for `@blocknote/xl-*`, with a commercial licence for closed-source use. — [GitHub TypeCellOS/BlockNote](https://github.com/TypeCellOS/BlockNote)
- Lexxy 1.0 (2026-09-28) lists accessibility, security and performance improvements and keyboard-navigable galleries. It powers Fizzy (launched December 2025) and Basecamp 5 (May 2026). 275 cards were closed during the project. — [Lexxy 1.0 is here](https://dev.37signals.com/lexxy-1-0/)
- Before 1.0, Lexxy was described as early beta (0.x line). — [Ruby Toolbox: lexxy](https://www.ruby-toolbox.com/projects/lexxy)
- Overtype positions its textarea approach as avoiding the mobile problems of contentEditable editors. — [GitHub panphora/overtype](https://github.com/panphora/overtype)
- The Lexical GitHub repo now resolves to `meta/lexical`: 23,993 stars, last push 2026-11-03, v0.53.0 (2026-10-28). It is still pre-1.0. — [GitHub facebook/lexical → meta/lexical](https://github.com/facebook/lexical)

### Inferences
- Pre-1.0 churn risk: Lexical (0.53), BlockNote (0.57), Rhino (0.18), Marksmith (0.4) can break APIs in minor releases. CodeMirror 6, ProseMirror 1.x, TipTap 3.x, Milkdown 7.x, Lexxy 1.x, Trix 2.x are semver-stable lines.
- [background, not re-verified] On mobile and IME: textarea-based editors (Overtype, Marksmith, plain textarea) inherit native IME, autocorrect, dictation and accessibility for free. CodeMirror 6 uses contentEditable with dedicated IME/composition handling and is generally solid on mobile. ProseMirror-based editors have a long tail of Android/Gboard composition bugs. A textarea also has the most predictable screen-reader behaviour, which matters for WCAG 2.2 AA (Papyro's `accessibility` skill).

### Gaps
- No accessibility audits (WCAG conformance statements) were found for any library in this pass.
- No sourced mobile/IME bug comparisons were fetched. Each candidate's issue tracker (search "IME", "Android", "composition") would quantify this.
- Plate's exact licence split could not be confirmed. GitHub reports NOASSERTION; the core is commonly described as MIT with paid "Plate Plus" templates [background, not re-verified].

## Q7. Who uses what (reference deployments)

### Takeaway
37signals: Trix in older apps, House in Writebook (2024), Lexxy in Fizzy (Dec 2025) and Basecamp 5 (May 2026). GitLab: TipTap + ProseMirror with markdown as storage. Discourse: ProseMirror rich composer over markdown storage, enabled by default with a toggle back to markdown mode. Avo: Marksmith. The markdown-storage precedents (GitLab, Discourse) both keep markdown canonical and accept serializer normalization.

### Cited Findings
- Lexxy powers Fizzy (since December 2025) and Basecamp 5 (since May 2026), "and many others". — [Lexxy 1.0 is here](https://dev.37signals.com/lexxy-1-0/)
- House was built for Writebook. 37signals' first Lexxy announcement introduced it as a new Rails rich text editor. — [Lexxy 1.0 is here](https://dev.37signals.com/lexxy-1-0/), [Announcing Lexxy](https://dev.37signals.com/announcing-lexxy-a-new-rich-text-editor-for-rails/)
- GitLab's rich text editor is built on TipTap and ProseMirror, with markdown deserialized via the server Markdown API and serialized with prosemirror-markdown. — [GitLab rich text editor dev guide](https://docs.gitlab.com/development/fe_guide/content_editor/)
- Discourse: an experimental ProseMirror WYSIWYG composer was announced for testing in March 2025 (ProseMirror chosen per a December 2024 update). A later announcement says it is enabled by default for all communities with a toolbar toggle to classic markdown mode. Admins control a "Default composition mode" setting, and a 2026 user report describes the setting being ignored in some versions. — [Discourse Meta: new composer](https://meta.discourse.org/t/369779), [ProseMirror forum](https://discuss.prosemirror.net/t/discourse-is-heading-towards-a-prosemirror-based-editor/8017), [Discourse Meta regression report](https://meta.discourse.org/t/regression-default-composition-mode-appears-to-be-ignored-between-v2026-7-0-latest-63-and-314/407861)
- Marksmith is built by the Avo team and integrates with Avo admin. — [Avo blog: Marksmith](https://avohq.io/blog/ruby-on-rails-markdown-editor-marksmith)

### Inferences
- The two large markdown-canonical products (GitLab, Discourse) both chose ProseMirror with prosemirror-markdown and kept a raw-markdown mode alongside. That suggests doc-model WYSIWYG over markdown is workable only with an escape hatch to source. A source-first editor with live-preview decorations is the inverse design and needs no mode switch.
- 37signals' own path (House WYSIWYM, then Lexxy WYSIWYG for HTML storage) suggests WYSIWYG is the better default for general apps. Papyro's specific constraints (markdown storage, agent co-editing, long-form editorial) look more like Writebook's use case, for which House was built.

### Gaps
- Forem/dev.to's current editor and GitHub.com's comment editor (believed to be textarea + `markdown-toolbar-element`, the same element Marksmith uses) were not verified with sources in this pass.
- No public list of Milkdown, Lexical-markdown or Overtype production adopters was found.
