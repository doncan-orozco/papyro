# Editing UX of best-regarded markdown and markdown-adjacent writing editors (as of Nov 2026)

Scope: end-user products (not libraries). Covers how users write and see markdown: editing paradigm, rendering, keyboard/command model, fidelity, writer features, mobile/accessibility, praise/complaints.

Convention: every bullet in "Cited Findings" was confirmed this session against the cited URL. Items tagged **[prior knowledge, unverified this session]** appear only under Inferences or Gaps; they come from the researcher's background knowledge (cutoff mid-2026), were not re-checked against a source this session, and should be verified before they go into the final report.

## 1. Editing paradigm per product, and which paradigm writers prefer for long-form prose

### Takeaway
The market has settled on five paradigms. (1) Raw source with styled syntax: iA Writer, Ulysses, Obsidian Source mode. (2) Split pane with scroll sync: StackEdit, Dillinger, HackMD/HedgeDoc. (3) Write/Preview tabs: GitHub. (4) Inline "live preview" that hides syntax except at the cursor: Typora, Obsidian Live Preview, Bear 2, MarkText, Zettlr (partial), and Bear's new Lettera. (5) Block WYSIWYG where markdown is only an input shortcut: Notion, Craft, Google Docs. For long-form prose, opinion splits between "hide it until I touch it" (Typora/Bear/Obsidian LP) and "show it but dim it" (iA Writer style). Most writers prefer some reveal-near-cursor compromise over both pure WYSIWYG and a plain split pane.

### Cited Findings
**Obsidian (three views)**
- Obsidian has a Reading view plus an Editing view, and the Editing view has two modes: Live Preview and Source mode. — [Obsidian Help: Views and editing mode](https://obsidian.md/help/edit-and-read)
- Live Preview shows formatted text inline and hides most markdown syntax. The syntax becomes visible when the cursor enters the formatted content. Obsidian says this "often removes the need for Reading view". — [Obsidian Help](https://obsidian.md/help/edit-and-read)
- Source mode shows all syntax exactly as written, for plain text or precise control. Reading view shows the note with no syntax. — [Obsidian Help](https://obsidian.md/help/edit-and-read)
- Cmd/Ctrl+E toggles Reading view. Cmd/Ctrl-clicking the view switcher opens Editing and Reading views side by side, which is an on-demand split pane. Switching between Live Preview and Source has no default hotkey: the user assigns one to the "Toggle Live Preview/Source mode" command. — [Obsidian Help](https://obsidian.md/help/edit-and-read)
- Live Preview is the default editing mode and can be changed to Source in Settings → Editor → Default editing mode. New tabs open in editing view by default. — [Obsidian Help](https://obsidian.md/help/edit-and-read)
- Obsidian's Live Preview is built on CodeMirror 6, which follows CommonMark emphasis parsing. — [CJK Bold Fix plugin page](https://community.obsidian.md/plugins/cjk-bold-fix)

**Typora (seamless live preview)**
- Inline styles render once you finish typing them. Block styles render as you type or after Enter. Inline markers such as `**` are hidden or shown depending on context, and block markers such as `###` disappear once the block renders. Typora uses GitHub Flavored Markdown. — [Typora Quick Start](https://support.typora.io/Quick-Start/)
- One comparison calls Typora a "true WYSIWYG markdown editor" that hides all syntax and renders formatting in place, while Obsidian reveals raw syntax when the cursor enters a block. This is a low-quality, SEO-style source. — [AFFiNE blog: Typora vs Obsidian](https://affine.pro/blog/typora-vs-obsidian)

**Bear 2 and Lettera**
- Bear 2 (July 2023) can hide markdown syntax while writing. Hidden syntax reappears when the text is selected: for example, the asterisks around bold show up when the word is selected. — [Bear FAQ: What's new in Bear 2](https://bear.app/faq/whats-new-in-bear-2/); [Bear blog: Bear 2 is here](https://blog.bear.app/2023/07/bear-2-is-here/)
- An HN commenter praises Bear for revealing raw markdown only around the word under the cursor, a finer unit than Obsidian's per-line reveal. — [HN: "Markdown is meant to be shown"](https://news.ycombinator.com/item?id=41254936)
- **New (June 2026):** Bear's developers announced Lettera, a standalone native Mac markdown editor built on Bear 2's editor and in TestFlight beta. Its main features: live rendering in one view, syntax hidden when you aren't editing it, a formatting bar for bold/italic/underline, CommonMark, tables, MathJax math, inline images, and both folders of files and single .md files (an iCloud Lettera folder by default). It exports and copies as plain text, rich text, Markdown and HTML, and exports to PDF, JPG and ePub. — [9to5Mac, 2026-06-19](https://9to5mac.com/2026/06/19/bear-app-developers-announce-lettera-a-beautiful-markdown-editor-for-mac/)

**iA Writer (focus and syntax control)**
- Focus Mode dims everything except the current sentence or paragraph. Its scopes are Sentence, Paragraph and Typewriter. — [iA Writer: Syntax Highlight support (iPhone)](https://ia.net/writer/support/editor/syntax-highlight/syntax-highlight-iphone); [iA Writer](https://ia.net/writer)
- (Markdown visibility in iA Writer is covered under Gaps: the support page tried for it returned a 404.)

**Ulysses (semantic markup)**
- Ulysses uses "Markdown XL", minimal markup that *defines* text passages rather than formatting them. Sources disagree on the tag count, giving either 27 or 28. — [Ulysses Help: Markdown XL](https://help.ulysses.app/markdown-xl); [Ulysses Help: First steps](https://help.ulysses.app/getting-started/first-steps-markdown-xl)
- An HN commenter says Ulysses's markdown base pushes it into clunky extensions and syntax-hiding tricks, so it feels less like a word processor. — [HN 41254936](https://news.ycombinator.com/item?id=41254936)

**Zettlr (CodeMirror with selective inline rendering)**
- Zettlr is an Electron app whose editor is CodeMirror. Users choose which elements render inline (links, images, headings, Mermaid), and a toggle switches between pure markdown and pre-rendered elements. A "readability mode" is toggled from an eye icon in the status bar. — [Zettlr docs: status bar](https://docs.zettlr.com/en/editor/statusbar.html); [LWN on Zettlr](https://lwn.net/Articles/984502)
- Zettlr 4.0 (Dec 2025) shipped a new table editor and an in-app PDF/image viewer. — [AlternativeTo news, Dec 2025](https://alternativeto.net/news/2025/12/zettlr-4-0-launches-with-new-table-editor-in-app-pdf-image-viewer-and-big-workflow-upgrades)

**MarkText (Typora-like, open source)**
- MarkText is a Typora-style live-preview editor. It went dormant after v0.17.1 (March 2022) and was revived in 2026: v0.19.0 shipped on 2026-05-28, its first release in over four years. — [Star History Monthly, May 2026](https://www.star-history.com/blog/standalone-markdown-editor)
- A third-party aggregator lists v0.20.0 (2026-10-02) as the latest release. This has not been confirmed against GitHub. — [OpenTechHub](https://www.opentechhub.io/marktext/)
- HN groups Typora, MarkText and Bear as editors that reveal markup only near the cursor. — [HN thread 25066769](https://news.ycombinator.com/item?id=25066769); [HN: Mark Text](https://news.ycombinator.com/item?id=21462832)

**HackMD / HedgeDoc (split pane, collaborative)**
- HedgeDoc has three modes: View (rendered only), Edit (editor only) and Both (side by side). Mobile offers only View and Edit. A ToC button opens an autogenerated table of contents. HedgeDoc started as a fork of HackMD's open-source code. — [HedgeDoc features page](https://md.informatik.uni-ulm.de/s/features); [HedgeDoc docs](https://docs.hedgedoc.org/)
- The editor offers real-time multi-user editing with visible cursors, authorship colours and a list of online users. Its toolbar covers headings, tables, checklists, code and image upload. — [Railway HedgeDoc template](https://railway.com/deploy/hedgedoc-notes.md) (a deployment guide, not first-party)

**StackEdit / Dillinger (classic split pane)**
- StackEdit has a split pane with scroll sync on by default and source syntax highlighting. It syncs with GitHub, Dropbox and Google Drive, supports Mermaid and KaTeX, and is built on PageDown, Stack Overflow's markdown library. — [It's FOSS: StackEdit](https://itsfoss.com/stackedit-markdown-editor/); [AlternativeTo: StackEdit](https://www.alternativeto.net/software/stackedit/about/)
- Dillinger is built on Monaco, the editor engine behind VS Code. It has a side-by-side preview with synced scroll and exports to MD, HTML and PDF. Documents persist in the browser without an account. — [dillinger.io](https://dillinger.io/); [Dillinger guide (self-promotional)](https://dillinger.io/guide/best-online-markdown-editor)

**Notion / Craft / Google Docs (block or rich-text WYSIWYG; markdown as input sugar)**
- Notion converts markdown-style shortcuts as you type, both inline and at block start. Some mappings differ from markdown: `>` makes a *toggle list*, not a quote, and `"` makes a quote. — [Notion Help: Keyboard shortcuts](https://www.notion.com/help/keyboard-shortcuts)
- Craft supports block-level markdown shortcuts at line start: `#` gives a Title, `##` a Subtitle, `###` a Heading. It also has a context-sensitive `/` menu. — [Craft: Markdown shortcuts](https://support.craft.do/en/write-and-edit/formatting/markdown-shortcuts); [Craft: Slash menu](https://support.craft.do/en/write-and-edit/formatting/slash-menu)
- Google Docs handles markdown through Tools → Preferences → "Enable Markdown". Supported syntax: `#`–`######` + space for headings (Docs only), `*`/`_` italic, `**` bold, `***` bold italic, `~` strikethrough, `[text](url)` links. — [Google Docs Help: Use Markdown](https://support.google.com/docs/answer/12014036)

**Preference for long-form prose**
- Writers who like rendered text say it is easier to focus on. One HN commenter writes long-form in Typora with a variable-width font. Others like Obsidian because they don't have to switch between view and edit modes. — [HN 41254936](https://news.ycombinator.com/item?id=41254936)
- The opposing camp, quoting the essay that started the thread: "If you want Markdown, show the Markdown." They value predictability: backspace deletes the character you expect, and you can see which side of a `*` the cursor is on. — [HN 41254936](https://news.ycombinator.com/item?id=41254936); [HN 25066769](https://news.ycombinator.com/item?id=25066769)
- Compromises proposed in the same thread: show the markup in a lighter colour (iA-style dimming), hide by default with a show toggle, or keep visual cues without the display changing on every keystroke. — [HN 41254936](https://news.ycombinator.com/item?id=41254936)
- One commenter says their company's switch to a visual-only editor reduced long-form writing. — [HN 41254936](https://news.ycombinator.com/item?id=41254936)

### Inferences
- Compact paradigm matrix (cited above unless tagged):

| Product | Primary paradigm | Can drop to raw source? | Storage |
|---|---|---|---|
| Typora | Inline live preview (hide-at-cursor) | Yes, Source Code mode **[prior knowledge, unverified this session: Cmd+/ toggle]** | .md files |
| Obsidian | Live Preview (default) / Source / Reading | Yes, per tab | .md files in a vault |
| Bear 2 / Lettera | Inline live preview, "Hide Markdown" optional (reveal on selection) | Bear: turn hiding off; Lettera: unclear | Bear: database; Lettera: .md files |
| iA Writer | Styled raw source + Focus mode + separate Preview **[prior knowledge, unverified this session]** | Always source | .md/.txt files |
| Ulysses | Styled semantic markup (Markdown XL) | Always markup | Proprietary library |
| Zettlr | CodeMirror source with selective inline rendering | Always source | .md files |
| MarkText | Inline live preview (Typora clone) + source mode | Yes | .md files |
| HackMD/HedgeDoc | Split pane (View/Edit/Both) | Always source | Server DB, markdown text |
| StackEdit / Dillinger | Split pane, scroll sync | Always source | Browser / cloud sync |
| GitHub | Write / Preview tabs **[prior knowledge, unverified this session]** | Always source | Markdown text |
| Notion / Craft | Block WYSIWYG; markdown = typing shortcuts | No raw-source view **[prior knowledge, unverified this session]** | Proprietary blocks |
| Google Docs | Rich text; markdown autoformat + paste/copy/import/export | No | Proprietary doc |

- For an editorial long-form tool, the strongest model is inline live preview with a one-keystroke escape to source (Obsidian's three-view model), plus iA-style focus/typewriter modes. Reveal granularity matters. Bear (word/selection) and Obsidian (line/element) feel less jumpy than revealing a whole block.
- Bear's 2026 decision to ship Lettera, a file-based standalone app built on its hide-syntax editor, suggests the hide-at-cursor paradigm is still where well-regarded native editors are investing.

### Gaps
- iA Writer's markdown display: syntax visible and dimmed, a separate Preview pane, Content Blocks. The support page tried (`ia.net/writer/support/editor/markdown`) returned 404. **[prior knowledge, unverified this session]**: iA Writer keeps markdown syntax visible (markers dimmed), has an optional side or tab preview, and uses `/path` lines for content-block transclusion.
- GitHub's Write/Preview tabs and formatting toolbar: the GitHub docs page fetched covers syntax and shortcuts, not the tab UI. It is not verified this session, and nothing was found on any 2025–2026 redesign of the comment editor.
- Typora's Focus mode (F8) and Typewriter mode (F9) **[prior knowledge, unverified this session]**; the Quick Start page did not mention them.
- Craft: whether it has any raw-markdown editing view, and how faithful its export is. Not found this session.

## 2. Markdown fidelity: does storage stay plain markdown, are round trips lossy, can users drop to source?

### Takeaway
File-based editors (Obsidian, Typora, Zettlr, MarkText, iA Writer, Lettera, StackEdit, Dillinger, HedgeDoc) keep markdown as the source of truth and let users see or edit it at any time. Block editors (Notion, Craft, Google Docs) treat markdown as an import/export or input format, and their round trips are lossy. Notion's markdown export is the cautionary example most often cited. Ulysses sits in the middle: markup-based, but stored in a proprietary library and remapped at export.

### Cited Findings
- Obsidian Source mode shows the syntax "exactly as written", and the user can switch modes per tab at any time. — [Obsidian Help](https://obsidian.md/help/edit-and-read)
- Typora's Copy produces HTML by default. It can be set to copy markdown source, or users can pick "copy as Markdown / HTML" explicitly. Paste accepts HTML, and Smart Paste keeps structure such as heading levels. Shift+Cmd+V pastes as plain text. Export covers PDF, HTML (with or without styles) and images, with Word and other formats via pandoc. — [Typora Quick Start](https://support.typora.io/Quick-Start/)
- Notion's markdown export problems: databases export as CSV rather than markdown, toggles come out as `<details>/<summary>` HTML, and code blocks sometimes lose their language identifiers. The source is a vendor with a commercial stake. — [Unmarkdown: Notion export broken](https://unmarkdown.com/blog/notion-export-broken)
- Obsidian's own Notion-import guide advises against Notion's Markdown export because it leaves out important data, and recommends HTML export instead. — [Obsidian Help: Import from Notion](https://help.obsidian.md/import/notion)
- The author of a third-party exporter says Notion's official markdown export is UI-only and buggy, citing stray asterisks in bold text. — [notion2markdown on PyPI](https://pypi.org/project/notion2markdown)
- Anytype's docs call Notion's Markdown & CSV import "more lossy" than importing through the API. — [Anytype: Migrate from Notion](https://doc.anytype.io/anytype-docs/advanced/data-and-security/import-export/migrate-from-notion)
- Google Docs (July 2024): import .md (File → Open, or "Open with Google Docs"), export .md (File → Download → Markdown), and right-click "Copy as Markdown" and "Paste from Markdown". Import and export are on by default. The copy/paste features need the Enable Markdown preference. — [Google Workspace Updates, July 2024](https://workspaceupdates.googleblog.com/2024/07/import-and-export-markdown-in-google-docs.html); [Google Docs Help](https://support.google.com/docs/answer/12014036)
- Ulysses: export styles map each semantic tag to an appearance (for example, emphasis can render red instead of italic). Most export styles drop editorial tags, but the "Revision" style keeps them. Plain-text export strips markup, comments, annotations and images, while markdown export keeps or converts the tags. — [Ulysses Help: Markdown XL](https://help.ulysses.app/markdown-xl); [The Sweet Setup: Ulysses toolbar](https://thesweetsetup.com/?p=11183)
- Ulysses stores sheets in a centralized library database and exports to ePub 3, DOCX, PDF and HTML5. — [TrustRadius: Ulysses reviews](https://www.trustradius.com/products/ulysses/reviews)
- Bear 2 supports markdown extensions for tables, footnotes and YAML. — [Bear blog: Bear 2 is here](https://blog.bear.app/2023/07/bear-2-is-here/)
- During the Bear 2 beta, users reported that a pasted markdown table did not render or export as a table, and that tables could only be created from the styles bar. These may be outdated. — [Bear community: Bear 2.0 feedback](https://community.bear.app/t/bear-2-0-feedback-questions/4076)
- Lettera follows CommonMark and opens plain .md files and folders. — [9to5Mac](https://9to5mac.com/2026/06/19/bear-app-developers-announce-lettera-a-beautiful-markdown-editor-for-mac/)
- An HN commenter values plain text because it stays readable and diffable. Another objects to WYSIWYG styling being applied "invisibly and destructively". — [HN 41254936](https://news.ycombinator.com/item?id=41254936)

### Inferences
- For Papyro, storing canonical markdown, with the inline preview as a *view* over that source rather than an HTML/blocks model, avoids the Notion-style loss problem and keeps diffs and version history meaningful.
- Markdown constructs a block editor can't express (raw HTML, reference links, custom attributes) are where lossiness shows up. An editor that always exposes source keeps them safe.

### Gaps
- No quantified data on which constructs Google Docs' markdown export drops (footnotes, tables, images). Google's help page lists no limitations.
- Typora's normalization behaviour, for example whether it rewrites list markers or table spacing on save, was not verified this session.

## 3. Input affordances

### Takeaway
Best-in-class input combines: markdown shortcuts that convert as you type (all block editors plus Typora/Bear), standard formatting hotkeys (Cmd+B/I/K), pasting a URL over a selection to make a link (GitHub, Notion), a slash/command menu (Notion, Craft), drag/paste of images (GitHub, Typora), smart paste from HTML to structure (Typora; Google Docs "Paste from Markdown"), and autocompletion triggers (`@`, `#`, `:`, `[[`). For tables, the good tools layer GUI controls over the raw pipe syntax (Typora, Zettlr 4 table editor) instead of leaving users to type pipes.

### Cited Findings
- **GitHub:** Cmd/Ctrl+B bold, +I italic, +E inline code, Cmd+K link. Tab/Shift+Tab indent selected lines. Pasting a URL over selected text makes a link, and Cmd/Ctrl+Shift+V replaces the selection with the link. Images and attachments can be dragged, picked from a file browser, or pasted. `@` autocompletes people/teams, `#` issues/PRs, `:` emoji, and Tab/Enter completes. An optional fixed-width font is available for all comment fields. — [GitHub Docs: Basic writing and formatting syntax](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax)
- **Notion:** inline `**bold**`, `*italic*`, `` `code` ``, `~strike~`. At block start: `*`/`-`/`+` bullets, `[]` to-do, `1.`/`a.`/`i.` numbered, `#`/`##`/`###` headings, `>` toggle, `"` quote, `---` divider. `/` opens a filterable block menu (`/turn` changes block type, `/color` sets colour) and Esc dismisses it. Pasting a URL over selected text makes a link. — [Notion Help: Keyboard shortcuts](https://www.notion.com/help/keyboard-shortcuts)
- **Craft:** the `/` menu is context-sensitive, with commands specific to blocks, tasks, links, tables and table cells. It filters by typed fragment (for example `/ins`). Slash commands affect only the current block unless several blocks are selected. — [Craft: Slash menu](https://support.craft.do/en/write-and-edit/formatting/slash-menu)
- **Typora tables:** typing a GFM header row renders a table. A floating tooltip above the header offers resize and alignment. Cmd/Ctrl+Enter inserts a row, and newer versions also add rows with Tab. Shift+Cmd/Ctrl+Backspace deletes a row. The context menu adds and deletes columns, and rows and columns can be reordered by dragging. Alignment is written as cell `text-align` and can be overridden by the theme. — [Typora: Table Editing](https://support.typora.io/Table-Editing/)
- **Typora:** Quick Open (Cmd+Shift+O), global search (Cmd/Ctrl+Shift+F), Smart Paste of HTML that keeps headings. — [Typora Quick Start](https://support.typora.io/Quick-Start/)
- **Zettlr 4.0** added a rewritten table editor. — [AlternativeTo, Dec 2025](https://alternativeto.net/news/2025/12/zettlr-4-0-launches-with-new-table-editor-in-app-pdf-image-viewer-and-big-workflow-upgrades)
- **Zettlr** formats citations with citeproc-js from CSL JSON and BibTeX files, and integrates with Zotero and JabRef. — [Zenodo: Zettlr record](https://zenodo.org/records/3958899)
- **Bear 2:** a toolbar button inserts a 2×2 table with a heading row. Beta users said tables couldn't be created by typing markdown, which may have changed since. — [Bear community feedback thread](https://community.bear.app/t/bear-2-0-feedback-questions/4076)
- **Lettera:** a formatting bar for bold, italic and underline. — [9to5Mac](https://9to5mac.com/2026/06/19/bear-app-developers-announce-lettera-a-beautiful-markdown-editor-for-mac/)
- **HedgeDoc:** a toolbar for headings, tables, checklists and code, plus an image-upload button. — [Railway HedgeDoc guide](https://railway.com/deploy/hedgedoc-notes.md)
- **Google Docs:** markdown autoformat for headings, emphasis, strikethrough and links once the preference is on; "Paste from Markdown" converts on paste. — [Google Docs Help](https://support.google.com/docs/answer/12014036)
- On Notion, an HN commenter complains that monospace/inline-code boundaries are hard to control because the editor misjudges where the formatting ends. — [HN 41254936](https://news.ycombinator.com/item?id=41254936)

### Inferences
- The minimum input set users now expect: Cmd+B/I/K, paste-URL-on-selection, and image drag/paste with upload. GitHub's model (shortcuts + autocomplete triggers + paste/drag uploads) is the baseline for web textareas.
- A slash menu helps discoverability for non-markdown users. Mapping `>` to something other than a quote (as Notion does) breaks markdown expectations and should be avoided in a markdown-faithful editor.
- For editorial use, `[[`/`@`-style autocompletion could map to "link to another Papyro article/author".
- **[prior knowledge, unverified this session]**: Obsidian has `[[` wikilink autocompletion and pasting a URL over a selection; Typora has image drag-and-drop with copy-to-folder rules; Notion converts pasted markdown into blocks.

### Gaps
- Smart paste in Obsidian and Notion (HTML → markdown, markdown → blocks) is not verified.
- GitHub's formatting toolbar, saved replies, and any new rich editor (2025–2026) are not verified.

## 4. Writer-focused features

### Takeaway
iA Writer sets the bar for prose craft: Focus mode with sentence/paragraph/typewriter scopes, part-of-speech Syntax Highlight, and a local, non-AI Style Check. Typora sets the bar for structure tools: outline panel, word count including selection count, themes and export. Collaborative web tools add live ToC and presence. Ulysses adds export-style mapping and editorial tags.

### Cited Findings
- **iA Writer Syntax Highlight** colours parts of speech: adjectives brown, nouns red, adverbs purple, verbs blue, conjunctions green. Writers pick which ones to show. It is enabled from the Focus menu and pairs with Focus Mode. — [iA Writer: Edit and polish](https://ia.net/writer/how-to/edit-and-polish)
- **iA Writer Style Check** flags fillers, redundancies and clichés with a strikethrough that appears only in the Editor, not in Preview or exports. It runs on-device, uses no AI, and sends nothing to a server. — [iA Writer: Edit and polish](https://ia.net/writer/how-to/edit-and-polish)
- On Windows, iA Writer's Syntax Control supports English only. — [iA Writer: Syntax Highlight (Windows)](https://ia.net/writer/support/editor/syntax-highlight/syntax-highlight-windows)
- **iA Writer Focus Mode** has Sentence, Paragraph and Typewriter scopes. — [iA Writer support (iPhone)](https://ia.net/writer/support/editor/syntax-highlight/syntax-highlight-iphone)
- **Typora** has an outline panel (ToC) that can be pinned to the left. Word count shows on toolbar hover or can be kept visible, and selecting text shows a selection count. It also has custom themes and a CLI. — [Typora Quick Start](https://support.typora.io/Quick-Start/)
- **HedgeDoc** has an auto-generated ToC button and a night mode. — [HedgeDoc features](https://md.informatik.uni-ulm.de/s/features)
- **Ulysses** "Revision" export keeps editorial tags (comments, annotations), and per-tag export styling separates semantics from appearance. — [Ulysses Help: Markdown XL](https://help.ulysses.app/markdown-xl)
- **Zettlr** has a status bar with a readability-mode toggle, plus citation management. — [Zettlr docs: status bar](https://docs.zettlr.com/en/editor/statusbar.html)
- Third-party descriptions say HackMD's premium plans add version history, alongside team workspaces and permissions. This may be outdated and was not confirmed on HackMD's own pricing page. — [Unmarkdown: StackEdit vs HedgeDoc vs HackMD](https://unmarkdown.com/blog/stackedit-vs-hedgedoc-vs-hackmd)
- The Obsidian community has a Hemingway-style typewriter plugin, which shows focus/typewriter modes are add-ons there rather than core. — [Obsidian community plugin: Hemingway typewriter](https://community.obsidian.md/plugins/hemingway-typewriter)

### Inferences
- For Papyro's editorial audience, the differentiating writer features are focus/typewriter mode, outline navigation, live word count and reading time, and an optional style check that never alters exported or published output, following iA's principle of flagging without rewriting.
- iA's English-only Syntax Control on Windows shows that part-of-speech features need per-language NLP. Papyro would need Spanish support explicitly.
- **[prior knowledge, unverified this session]**: iA Writer has an authorship feature that marks pasted or AI text differently from text the user typed. The "next tutorial" referenced on the iA page suggests it exists, but the details weren't fetched. Obsidian has core Outline and Word Count plugins and File Recovery snapshots. Bear and Ulysses show reading time in their stats panels.

### Gaps
- No verified source this session on reading-time display in any product, or on version-history UX in Typora, Obsidian, Bear or iA (Obsidian Sync history, iA's use of macOS versions, Google Docs version history are all known from prior knowledge but uncited).
- Offline behaviour of the web tools (StackEdit offline/PWA, HackMD) is not verified.

## 5. Mobile and accessibility (screen readers, IME / non-Latin input, spellcheck)

### Takeaway
Hide-at-cursor editors built on contenteditable or CodeMirror 6 have a long tail of IME (CJK) composition bugs and cursor/selection oddities. Textarea-based approaches keep native undo, mobile keyboard, spellcheck and accessibility behaviour almost for free, at the cost of less rendering. Hard evidence on screen-reader support for live-preview editors was not found.

### Cited Findings
- **Obsidian Live Preview IME bugs:**
  - Typing Japanese or Chinese right after a markdown link drops the first character out of composition (Obsidian 1.14.4, macOS and Ubuntu). — [Obsidian forum: IME after a markdown link](https://forum.obsidian.md/t/issue-extra-latin-character-inserted-when-typing-japanese-ime-right-after-a-markdown-link/118859/4)
  - An older iOS report describes the candidate bar jumping to the top-left in Live Preview. — [Obsidian forum: iOS CJK IME](https://forum.obsidian.md/t/bug-ios-cjk-ime-unable-to-work-continuously-when-there-are-long-text-in-the-note/34948)
  - A Linux report (Fcitx5 on Wayland) describes the candidate panel drifting. — [Obsidian forum: Linux CJK IME](https://forum.obsidian.md/t/linux-cjk-input-method-ime-fcitx5-display-bug/105118)
  - An iOS Japanese-kana bug was traced to CodeMirror 6 and later fixed upstream. — [Obsidian forum: iOS Japanese keyboard](https://forum.obsidian.md/t/ios-input-problem-with-japanese-keyboard/14450)
- CJK emphasis often fails to render in Live Preview because CommonMark's emphasis rules (CommonMark issue #650, open 7+ years) handle CJK punctuation badly. A plugin works around it. — [CJK Bold Fix plugin](https://community.obsidian.md/plugins/cjk-bold-fix)
- HN commenters report that rich WYSIWYG editors let the visible state and the internal formatting state drift apart, and that cursor movement in contenteditable is "broken for inexplicable reasons". — [HN 25066769](https://news.ycombinator.com/item?id=25066769)
- The OverType Show HN describes a transparent textarea overlaid on a rendered preview. It keeps native textarea undo/redo, mobile keyboard support and accessibility, but commenters note it breaks when styling changes element width or height (for example a bold or heading font). — [Show HN: OverType](https://news.ycombinator.com/item?id=44932651)
- HedgeDoc's mobile layout drops the side-by-side mode and offers only View or Edit. — [HedgeDoc features](https://md.informatik.uni-ulm.de/s/features)
- iA Writer's Syntax Control availability varies by platform and language: English only on Windows. — [iA Writer Windows support](https://ia.net/writer/support/editor/syntax-highlight/syntax-highlight-windows)
- Trello removed its desktop markdown editor but kept it on mobile, and users complain about the lost opt-out. — [HN 41254936](https://news.ycombinator.com/item?id=41254936)

### Inferences
- For Papyro's English/Spanish audience, CJK IME is lower priority. However, Spanish dead-key and accent composition (´ + e → é) goes through the same `compositionstart/end` path, and live-preview decorations that re-render mid-composition can break it. This needs explicit testing on macOS, Windows and mobile keyboards.
- Native spellcheck and grammar tools (browser spellcheck, Grammarly, OS autocorrect) work best on a textarea or a well-behaved contenteditable. CodeMirror 6 supports `spellcheck` on its contenteditable, but decorations can interfere **[prior knowledge, unverified this session]**.
- CommonMark emphasis edge cases (like the CJK issue) also affect Spanish punctuation such as `¿**Qué**?` and `¡**hola**!`. Flanking rules around non-ASCII punctuation should be tested **[inference, not verified]**.

### Gaps
- No source found on screen-reader (VoiceOver/NVDA/JAWS) support in Typora, Obsidian Live Preview, Notion or Bear. This needs dedicated a11y research, such as CodeMirror 6's accessibility docs and the ProseMirror/Lexical a11y notes.
- Mobile UX of iA Writer, Bear, Ulysses and Obsidian (for example the keyboard accessory toolbars on iOS) is not verified this session **[prior knowledge: all four ship iOS keyboard toolbars for markdown]**.

## 6. Recurring praise and complaints: what makes an editor feel "best in class"

### Takeaway
Users praise distraction-free rendering that never fights the cursor, plain-file portability, speed, and focus tools. They complain about lossy export (Notion), cursor and backspace unpredictability and layout jumps when syntax appears or disappears, markdown semantics remapped (Notion's `>`), forced visual-only editors, IME bugs, and abandoned projects (MarkText 2022–2026).

### Cited Findings
- **Praise:**
  - Typora is used for long-form with variable-width fonts.
  - Bear's word-level reveal is praised.
  - Obsidian is liked because users don't have to switch between edit and view.
  - Source: [HN 41254936](https://news.ycombinator.com/item?id=41254936)
- **Complaint: layout jumps.** Text shifts when bold or header markers appear or resize, and revealed characters push the text around. — [HN 41254936](https://news.ycombinator.com/item?id=41254936)
- **Complaint: unpredictable deletion.** Backspace unexpectedly changes formatting in Word-style editors, and styling is applied "invisibly and destructively". — [HN 41254936](https://news.ycombinator.com/item?id=41254936)
- **Complaint: inline-code boundaries in Notion.** Monospace and inline-code boundaries are hard to control. — [HN 41254936](https://news.ycombinator.com/item?id=41254936)
- **Complaint: Notion export loss.** Notion's markdown export loses content (databases, toggles, code languages). One Obsidian forum user reported that hundreds of pages were lost migrating a large workspace. — [Unmarkdown](https://unmarkdown.com/blog/notion-export-broken); [Obsidian forum: missing Notion data](https://forum.obsidian.md/t/missing-notion-database-data-when-exporting-to-markdown-csv-or-html/37931)
- **Preference: keeping the syntax visible.** An Obsidian forum user who prefers raw markdown wanted a Typora-style mode as an *option*, not as a replacement. — [Obsidian forum: Typora-like editing mode](https://forum.obsidian.md/t/a-wysiwym-typora-like-editing-mode/1953/38)
- **Complaint: Bear 2 "Hide Markdown".** During the beta, the setting reportedly had no effect, and tables and to-dos didn't reveal markdown. — [Bear community: Show/Hide Markdown](https://community.bear.app/t/show-hide-markdown/49?page=2); [Bear community: markdown hiding, syntax highlighting vs rich text](https://community.bear.app/t/markdown-hiding-syntax-highlighting-vs-rich-text/9919)
- **Complaint: MarkText dormancy.** MarkText went four years without a release (2022–2026), and its archived maintainer fork (Aug 2025) admitted very limited maintenance time. — [Star History, May 2026](https://www.star-history.com/blog/standalone-markdown-editor)
- **iA Writer marketing angle.** iA presents Style Check as non-AI and local-only, a deliberate privacy and authorship stance. — [iA Writer: Edit and polish](https://ia.net/writer/how-to/edit-and-polish)

### Inferences
- "Best in class" criteria, distilled for Papyro:
  1. Markdown remains the stored truth, with a one-key escape to source.
  2. Reveal syntax only at the cursor or selection, at a fine granularity, without reflowing the line, for example by reserving space or dimming markers instead of inserting them.
  3. Standard hotkeys, paste-URL-on-selection, and image paste/drag.
  4. Focus/typewriter mode, outline, and word count/reading time.
  5. GUI help for tables over raw pipes.
  6. Robust IME/accent composition and native spellcheck.
  7. Never alter content invisibly: style checks flag and don't rewrite.
- Because opinion is split between hide-syntax and show-syntax writers, making both a per-user preference (as Obsidian does) is the safest product decision.

### Gaps
- Reddit (r/ObsidianMD, r/Markdown, r/writing) threads and reviews from The Sweet Setup and Zapier were not retrieved this session, so the user-sentiment evidence leans on HN and vendor forums.
- No current (2026) independent review of Typora, Ulysses or Craft pricing or UX changes was retrieved. **[prior knowledge, unverified this session]**: Typora became paid at 1.0 (Nov 2021), and Ulysses and Craft are subscription-based.
