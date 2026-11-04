# EDIT: editor user experience requirements for the Md gem

This area covers what a writer feels while typing in the `Md` editor: the three modes over one markdown text, the toolbar and keyboard shortcuts, what paste and drop do, table commands, the `/` menu, the save and conflict signals the host app wires, focus and typewriter modes, counts, speed on long documents, mobile, accessibility and accent composition. The benchmark already settled the architecture (CodeMirror 6 decorating the real markdown text, a server preview from the render core, Source first and Live later; see `../reports/Markdown editor benchmark.md`). This doc turns that direction into requirements a system test can check, and it marks which behaviours a writer expects on day one (gem 0.1) and which can wait for later 0.x releases.

## Scope

This doc decides the editing experience in the browser: modes and their defaults, the shortcut map, toolbar behaviour, paste and drop behaviour, table and `/` menu commands, the client side of autosave (events, states, conflict banner, local backup), focus and typewriter modes, word count and reading time on the client, the keystroke and document-size budget, mobile layout and input, accessibility (WCAG 2.2 AA) and IME and dead-key composition.

It leaves to other areas, which it mentions only by area code:

- **RENDER**: the dialect, the sanitizer, the HTML the preview shows and the server `word_count` the client count must match.
- **THEME**: the CSS tokens and the editor's look (marker colour, focus ring, prose styles). This doc only sets the contrast floor those tokens must meet.
- **RAILS**: upload storage and transport (Active Storage direct uploads), the autosave endpoint and its `lock_version` check, Turbo cache and morph handling.
- **ASSETS**: how the CodeMirror packages and the optional HTML-to-markdown converter reach the page, and their byte cost.
- **VIEWS** and **DX**: the helper and form-builder signatures (`f.markdown_field`) and the configuration API. Option names below are illustrative.
- **AGENT**: the suggestion and review UI drawn inside the editor.
- **PAPYRO**: the EN/ES side-by-side translation view and Studio layout.

Out of scope (WON'T, for every release this research plans):

- Real-time co-editing (Yjs, `y-codemirror.next`): the benchmark puts it after optimistic locking and comments, only if demanded.
- A rich-text or block document model, or storing anything but the markdown text.
- Remapping markdown semantics in the editor, such as Notion's `>` that makes a toggle instead of a quote.
- A spelling or grammar engine of the gem's own: the editor hands spellcheck to the browser and the OS.
- Inline AI autocomplete (ghost text), part-of-speech highlighting and a style checker: later Papyro phases, not gem UX.
- Fixing CommonMark emphasis flanking around CJK or Spanish punctuation in the editor: that is a renderer and dialect question for RENDER.

## Questions

1. Which behaviours does a writer expect on day one, and which can wait?
2. What performance budget applies: keystroke latency, document size, preview and counts?
3. How will accessibility and IME behaviour (including Spanish dead keys and accent composition) be verified?
4. Which mode is the default, and what has to be true before Live mode becomes the default?
5. Which keyboard shortcuts ship, and how do they avoid collisions with CodeMirror's own keymap, the browser and assistive technology?
6. What does the editor do with pasted URLs, HTML and images, and with dropped files?
7. What does the gem own for autosave and conflicts, and what does the host app wire?

## Findings

### Day one versus later (answers question 1)

The baseline writers expect from any web markdown field is GitHub's: Cmd+B/I/K, a URL pasted over a selection becomes a link, and images can be pasted or dragged in. The delight features (focus mode, `/` menu, table tools, paste-to-embed) come after that (benchmark report, "Writers converge"; `editing_ux_products.md` section 3). The report's Phase 1 and Phase 2 lists map directly to gem 0.1 and later 0.x releases. The report's GitHub baseline also lists `@`/`#`/`:` autocomplete; this doc defers it (EDIT-42) because it needs app data.

| Behaviour | Evidence | Release |
|---|---|---|
| Source mode with markdown highlighting, the textarea still the form value | Report, "Recommended direction"; GitLab's lazy serialization | 0.1 (MUST) |
| Cmd+B/I/E/K, list and quote shortcuts, paste URL over selection | GitHub keyboard shortcuts docs | 0.1 (MUST) |
| List and quote continuation on Enter, one level removed by Backspace | `@codemirror/lang-markdown` `markdownKeymap` | 0.1 (MUST) |
| Image paste and drop with an alt-text prompt | GitHub; report Phase 1 | 0.1 (MUST) |
| Server preview next to or instead of the text, same HTML as publish | Report, "preview parity is the most cited trust signal" | 0.1 (MUST) |
| Save states, conflict banner, local backup | Report Phase 1 (`lock_version` plus local backup) | 0.1 (MUST) |
| Word count and reading time | Typora; report Phase 1 | 0.1 (MUST) |
| Find and replace inside the editor | CodeMirror draws only the viewport, so browser find misses text | 0.1 (MUST) |
| Live mode (markers hidden off the cursor) | Obsidian, Typora, Bear; IME risk in the report | 0.x (SHOULD), default only after the IME matrix passes |
| Table commands, `/` menu, HTML paste to markdown | Typora, Zettlr 4, Notion, Craft | 0.x (SHOULD) |
| Focus and typewriter modes, preview scroll sync | iA Writer, StackEdit | 0.x (SHOULD) |
| `@`, `#`, `[[` completion hooks, paste URL to embed | GitHub, Obsidian, Ghost | Later (COULD) |

### Modes

Obsidian is the reference: Live Preview (default), Source mode and Reading view per tab, with Live Preview revealing syntax when the cursor enters an element; switching Live and Source has no default hotkey ([Obsidian Help](https://obsidian.md/help/edit-and-read)). Writer opinion splits between "hide it until I touch it" and "if you want Markdown, show the Markdown"; the complaints against hiding are unpredictable Backspace and layout jumps when markers appear ([HN 41254936](https://news.ycombinator.com/item?id=41254936)). Bear's word-level reveal is praised as less jumpy than line-level reveal. The report's decision stands: one text, three per-user views, Source first, Live the default only after IME testing. HedgeDoc drops its side-by-side mode on mobile and offers only View or Edit ([HedgeDoc features](https://md.informatik.uni-ulm.de/s/features)), which is the right fallback for narrow screens.

### Keyboard shortcuts and CodeMirror's own keymap (answers question 5)

GitHub's comment editor defines the shortcuts writers already know: Cmd/Ctrl+B bold, +I italic, +E inline code, +K link, Cmd/Ctrl+Shift+7 ordered list, +8 unordered list, +. quote, Cmd/Ctrl+Shift+P toggles Write and Preview, Cmd/Ctrl+Enter submits ([GitHub Docs: keyboard shortcuts](https://docs.github.com/en/get-started/accessibility/keyboard-shortcuts)).

CodeMirror's `defaultKeymap` collides with that set in two places, read from the `@codemirror/commands` typings on 2026-11-03 ([unpkg @codemirror/commands](https://unpkg.com/@codemirror/commands/dist/index.d.ts)):

- **Ctrl-i (Cmd-i on macOS) is `selectParentSyntax`**, not italic. The gem must bind italic at a higher precedence.
- **Ctrl-Enter (Cmd-Enter on macOS) is `insertBlankLine`**, where GitHub users expect submit.
- Useful bindings to keep: Mod-z and Mod-Shift-z / Mod-y undo and redo, Alt-ArrowUp/Down move a line (reordering list items), Mod-[ and Mod-] outdent and indent, and Ctrl-m (Shift-Alt-m on macOS) `toggleTabFocusMode`.
- `@codemirror/search` binds Mod-f to its search panel, F3 and Shift-F3 to next and previous match and Mod-d to select the next occurrence ([unpkg @codemirror/search](https://unpkg.com/@codemirror/search/dist/index.js)). That matters because CodeMirror "only draws the code that is visible (plus a margin around it) to the DOM" ([unpkg @codemirror/view typings](https://unpkg.com/@codemirror/view@6.43.15/dist/index.d.ts)), so the browser's own find cannot see off-screen text.

CodeMirror deliberately leaves Tab unbound so the default setup passes WCAG's no-keyboard-trap criterion; Escape then Tab leaves the editor, and an app that binds Tab for indentation should document an escape hatch because CodeMirror shows none ([CodeMirror: Tab handling](https://codemirror.net/examples/tab/)).

The shortcut table the gem ships (Mod = Cmd on macOS, Ctrl elsewhere):

| Action | macOS | Windows / Linux | Prior art | Release |
|---|---|---|---|---|
| Bold | Cmd+B | Ctrl+B | GitHub | 0.1 |
| Italic (overrides `selectParentSyntax`) | Cmd+I | Ctrl+I | GitHub | 0.1 |
| Inline code | Cmd+E | Ctrl+E | GitHub | 0.1 |
| Link (wraps the selection, cursor in the URL) | Cmd+K | Ctrl+K | GitHub | 0.1 |
| Paste a URL over a selection as a link | Cmd+V | Ctrl+V | GitHub, Notion | 0.1 |
| Paste as plain text (no conversion, no link wrap) | Cmd+Shift+V | Ctrl+Shift+V | Typora; OS "paste and match style" | 0.1 |
| Ordered list | Cmd+Shift+7 | Ctrl+Shift+7 | GitHub | 0.1 |
| Unordered list | Cmd+Shift+8 | Ctrl+Shift+8 | GitHub | 0.1 |
| Quote | Cmd+Shift+. | Ctrl+Shift+. | GitHub | 0.1 |
| Toggle preview | Cmd+Shift+P | Ctrl+Shift+P | GitHub | 0.1 |
| Save now (a save request the host handles) | Cmd+S | Ctrl+S | Desktop writing apps | 0.1 |
| Submit the form (opt-in; overrides `insertBlankLine` when on) | Cmd+Enter | Ctrl+Enter | GitHub | 0.1 |
| Undo / redo | Cmd+Z / Cmd+Shift+Z | Ctrl+Z / Ctrl+Y | CodeMirror | 0.1 |
| Continue a list or quote / remove one level | Enter / Backspace | Enter / Backspace | `markdownKeymap` | 0.1 |
| Indent / outdent a list item | Cmd+] / Cmd+[ (and Tab / Shift+Tab inside lists) | Ctrl+] / Ctrl+[ (and Tab / Shift+Tab inside lists) | CodeMirror | 0.1 |
| Move a line up / down | Alt+Up / Alt+Down | Alt+Up / Alt+Down | CodeMirror | 0.1 |
| Find / next / previous | Cmd+F / F3 / Shift+F3 | Ctrl+F / F3 / Shift+F3 | `@codemirror/search` | 0.1 |
| Leave the editor with the keyboard | Esc, then Tab or Shift+Tab | Esc, then Tab or Shift+Tab | CodeMirror | 0.1 |
| Toggle Tab focus mode | Shift+Alt+M | Ctrl+M | CodeMirror | 0.1 |
| Next / previous table cell (adds a row after the last cell) | Tab / Shift+Tab inside a table | Tab / Shift+Tab inside a table | Typora | 0.x |
| Open the `/` menu | `/` at line start or after a space | `/` at line start or after a space | Notion, Craft | 0.x |
| Switch Source / Live | unbound, configurable | unbound, configurable | Obsidian | 0.x |
| Toggle focus mode / typewriter mode | unbound, configurable | unbound, configurable | iA Writer | 0.x |

GitHub uses Cmd/Ctrl+Shift+V to replace the selection with the copied link; this table gives that chord the OS meaning instead (plain paste), since plain Cmd+V already wraps a selection in a link. That choice is listed under Open decisions. WCAG 2.2 SC 2.1.4 allows a single-character shortcut such as `/` only when it can be turned off or remapped, or is active only while the component has focus ([WCAG 2.2](https://www.w3.org/TR/WCAG22/)); the `/` menu fires only inside the focused editor and can be disabled.

Browser and assistive technology collisions: the gem handles these chords, and calls `preventDefault`, only while the editor has focus. No 0.1 chord uses a screen reader modifier (NVDA's Insert or Caps Lock, VoiceOver's Control+Option), and screen readers pass keys through to an editable field in focus or forms mode. Browsers keep some chords pages cannot override (new window, new tab, close tab and similar). Cmd/Ctrl+Shift+P, which Firefox uses for a private window, is the row to verify: if Firefox keeps it, toggle preview becomes a configurable binding there. CodeMirror's Mod-/ (`toggleComment`) writes HTML comments the renderer drops, so the gem leaves it unbound in prose.

### Paste and drop (answers question 6)

- GitHub turns a URL pasted over a selection into a link and accepts images dragged, picked or pasted ([GitHub Docs: basic formatting](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax)).
- Typora converts pasted HTML while keeping its structure, such as heading levels, and Shift+Cmd+V pastes plain text ([Typora Quick Start](https://support.typora.io/Quick-Start/)). Google Docs offers "Paste from Markdown" and "Copy as Markdown" ([Google Docs Help](https://support.google.com/docs/answer/12014036)).
- Turndown is the MIT-licensed HTML-to-markdown converter for the browser. Its defaults do not match the dialect: `headingStyle` defaults to `setext`, `codeBlockStyle` to `indented` and `bulletListMarker` to `*`; `turndown-plugin-gfm` adds tables and strikethrough but no task lists ([turndown](https://github.com/mixmark-io/turndown)). Any converter the gem ships must be configured to ATX headings, fenced code and `-` bullets.
- Ghost's "paste a URL on an empty line to get a card" is a delight feature, but its rendering is RENDER's embed work (v2 in the report), so the editor only keeps the bare URL on its own line.

Because the text is the document, the safe default is that pasted plain text lands byte for byte, and a conversion happens only when the clipboard holds structural HTML (headings, lists, links, tables, emphasis) from a rich source such as Google Docs or a web page.

### Tables and the `/` menu

Table UI is the one feature that favours doc-model editors; source editors close the gap with "format table" and cell-navigation commands, the Zettlr 4 path (`editor_libraries.md` Q2, report). Typora shows the expected set: a typed header row becomes a table, Cmd/Ctrl+Enter or Tab adds a row, Shift+Cmd/Ctrl+Backspace deletes a row, and the context menu adds and deletes columns ([Typora: Table Editing](https://support.typora.io/Table-Editing/)). The gem leaves Cmd/Ctrl+Enter to form submit when the app turns it on (otherwise CodeMirror's `insertBlankLine`) and uses Tab in the last cell for a new row.

Notion's `/` opens a filterable block menu dismissed by Esc ([Notion Help](https://www.notion.com/help/keyboard-shortcuts)); Craft's menu is context-sensitive and filters by the typed fragment ([Craft: Slash menu](https://support.craft.do/en/write-and-edit/formatting/slash-menu)). In a markdown-faithful editor the menu inserts markdown text and never creates a construct the text cannot hold. The accessible shape is the WAI-ARIA combobox with a listbox popup: focus stays in the editor, `aria-activedescendant` points at the active option, Enter accepts, Escape closes ([APG combobox](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/)).

### Autosave and conflicts (answers question 7)

The report keeps optimistic locking (`lock_version`) and a local backup for now, comments before CRDT, and Yjs only if demanded; WordPress pulled real-time co-editing from 7.0. GitLab's editor avoids two-way binding because getting and setting markdown is expensive, and serializes lazily, on demand, instead of on every change ([GitLab content editor guide](https://docs.gitlab.com/development/fe_guide/content_editor/)). The Stimulus wrapper keeps the real `textarea` as the form value and syncs into it on a debounce. The split that follows: the gem owns the client states (dirty, saving, saved, offline, conflict), the events it emits, the banner and the local backup; the host owns the endpoint, the lock check and what "save" means. WCAG 2.2 SC 4.1.3 (AA) asks that status messages such as "saved" be exposed through a role or property without moving focus ([Understanding 4.1.3](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html)).

### Focus, typewriter and counts

iA Writer's Focus Mode dims everything except the current sentence or paragraph and has a Typewriter scope ([iA Writer: Edit and polish](https://ia.net/writer/how-to/edit-and-polish)). Typora shows a word count on hover or permanently, plus a selection count ([Typora Quick Start](https://support.typora.io/Quick-Start/)). `Intl.Segmenter` with `granularity: "word"` splits text by locale rules, marks word segments with `isWordLike`, and has been Baseline widely available since April 2024 ([MDN Intl.Segmenter](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Segmenter)), so the client count can be locale-aware without a dependency. The render core returns `word_count` and `reading_time` (benchmark report, gem layer 1); two different numbers for the same article would undermine the same trust that preview parity builds.

### Performance budget (answers question 2)

- Field metric: INP is good at or below 200 ms at the 75th percentile, and key presses on physical or on-screen keyboards count as interactions ([web.dev INP](https://web.dev/articles/inp)). That threshold is a ceiling for any interaction, too loose for typing.
- Typing research: keyboard and monitor alone add about 26 ms on a typical setup, visual processing about 40 ms, and the author argues editors should aim for 1 to 5 ms of processing and treats one 16 ms frame as an arbitrary ceiling ([Pavel Fatin, Typing with pleasure](https://pavelfatin.com/typing-with-pleasure/)).
- Document size: Papyro articles are 2 to 10 KB (report). CodeMirror's demo loads a document of a few million lines; the parser limits its work, so highlighting can lag behind far scroll positions and stops entirely while the editor is inactive ([CodeMirror: huge document](https://codemirror.net/examples/million/)). Viewport-only drawing keeps typing cost independent of length, so the risk sits in the gem's own Live-mode decorations, counts and sync, which must also work per viewport or on a debounce.

The budget this doc sets: on a reference machine the gem's own work per keystroke stays within one frame (16 ms) at the 95th percentile on a 100 KB document (about 15,000 words) in Source and Live modes; a 1 MB document stays editable with no task over 200 ms; preview requests, counts and textarea sync never run synchronously on a keystroke.

### Accessibility (answers question 3, first half)

- CodeMirror's content element has `role="textbox"` but no accessible name by default; Mozilla fixed it by passing `aria-label` through the public `contentAttributes` facet ([Mozilla bug 2071227](https://bugzilla.mozilla.org/show_bug.cgi?id=2071227)), and Joomla's axe scan flagged the same gap ([Joomla issue 48153](https://issues.joomla.org/tracker/joomla-cms/48153)). Line-number gutters are read before the text ([Sourcegraph PR 44148](https://github.com/sourcegraph/sourcegraph-public-snapshot/pull/44148)), so a prose editor should ship without gutters.
- CodeMirror sets `spellcheck="false"`, `autocorrect="off"`, `autocapitalize="off"`, `writingsuggestions="false"` and `translate="no"` on its content element by default ([unpkg @codemirror/view](https://unpkg.com/@codemirror/view@6.43.15/dist/index.js)). Those suit code; for prose the gem must turn spellcheck, autocorrect and autocapitalize back on, or writers lose the native tools a textarea gives them.
- `EditorView.announce` adds screen reader announcements to a transaction through a visually hidden `aria-live="polite"` element, meant for effects that are visible but easy to miss ([unpkg @codemirror/view typings](https://unpkg.com/@codemirror/view@6.43.15/dist/index.d.ts)). Mode switches, inserted table rows and upload results are such effects.
- The toolbar follows the APG toolbar pattern: one tab stop, arrow keys between controls, Home and End optional, `role="toolbar"` with a label ([APG toolbar](https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/)).
- WCAG 2.2 AA criteria that bind the editor ([WCAG 2.2, W3C Recommendation 2024-12-12](https://www.w3.org/TR/WCAG22/)): 2.1.1 Keyboard, 2.1.2 No Keyboard Trap, 2.1.4 Character Key Shortcuts, 2.4.7 Focus Visible, 2.4.11 Focus Not Obscured (Minimum), 1.4.10 Reflow (320 CSS px without two-dimensional scrolling), 1.4.11 Non-text Contrast (3:1), 2.5.8 Target Size (Minimum) of 24 by 24 CSS px or the spacing exception ([Understanding 2.5.8](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html)), 4.1.2 Name, Role, Value and 4.1.3 Status Messages. Dimmed markers in Source mode are text, so they still need 4.5:1 contrast under 1.4.3; iA-style dimming has to stay within that floor, and focus-mode dimming (EDIT-32) is held to the same floor.
- The benchmark notes found no source on screen reader behaviour in Typora, Obsidian Live Preview, Notion or Bear (`editing_ux_products.md` section 5, Gaps). Source mode is the accessible baseline because every character CodeMirror draws is DOM text equal to the markdown; but CodeMirror draws only the viewport plus a margin, so a screen reader's read-all can stop at the drawn edge of a long document, and caret navigation (which moves the viewport) is the reading path to verify. Live mode replaces markers with decorations, and whether a screen reader then reads the full text is unknown until tested.
- Automated checks are available for the gem's system tests: Deque's `axe-core-capybara` 4.14.0 ([axe-core-gems](https://github.com/dequelabs/axe-core-gems)).

### IME and Spanish accent composition (answers question 3, second half)

- Obsidian's Live Preview, built on CodeMirror 6, has a tail of composition bugs: a Japanese or Chinese character dropped out of composition right after a markdown link (Obsidian 1.14.4), a drifting candidate panel on Linux, and an iOS bug traced to CodeMirror and fixed upstream (the first in [Obsidian forum: IME after a link](https://forum.obsidian.md/t/issue-extra-latin-character-inserted-when-typing-japanese-ime-right-after-a-markdown-link/118859/4), the others with their threads in `editing_ux_products.md` section 5). Decorations that re-render mid-composition are the common cause.
- Dead keys differ by platform: on macOS all major browsers fire composition events for a dead-key sequence, while on Windows the dead key inserts nothing and the second key inserts the composed character as plain key events ([W3C public-webapps, Ryosuke Niwa, 2016](https://lists.w3.org/Archives/Public/public-webapps/2016JanMar/0033.html)); a 2023 UI Events comment confirms macOS handles dead keys as IME composition and Windows as two sets of key events, with a keydown whose `key` is `Dead` ([W3C public-webapps-github, 2023](https://lists.w3.org/Archives/Public/public-webapps-github/2023Jul/0056.html)). Spanish writers on macOS (´ then e) therefore go through the same composition path as CJK IME users, and Live mode must not decorate across an active composition. `KeyboardEvent.isComposing` is true between `compositionstart` and `compositionend` ([MDN isComposing](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/isComposing)); CodeMirror exposes `view.composing` and `view.compositionStarted`, and notes that on Android merely placing the cursor on a word starts a composition.
- System tests can drive composition: the Chrome DevTools Protocol has `Input.imeSetComposition` (text, selection and replacement range) and `Input.insertText` for text "that doesn't come from a key press, for example an emoji keyboard or an IME", both marked experimental ([CDP Input domain](https://chromedevtools.github.io/devtools-protocol/tot/Input/)). Cuprite drives Chrome over CDP, so a gem system test can send them; real dead-key and mobile keyboard behaviour still needs a manual matrix.

### Mobile

The benchmark notes say, as background not re-verified, that textarea-based editors inherit native IME, autocorrect, dictation and accessibility while CodeMirror 6 uses contenteditable with its own composition handling (`editor_libraries.md` Q6). With spellcheck and autocorrect restored on the content element (see Accessibility), the remaining known mobile work is the mobile rows of EDIT-34 plus layout: no side-by-side preview on narrow screens (HedgeDoc), a toolbar that stays reachable while the on-screen keyboard is open, targets of at least 24 CSS px, and no hover-only control.

## Requirements

Grouped by release intent: 0.1 behaviours are MUST unless marked otherwise, later behaviours SHOULD or COULD. "System test" means a Capybara and Cuprite test in the gem's dummy app.

### Modes and the form value

- **EDIT-01** (MUST) The editor enhances a real `textarea` that stays the form value: with JavaScript off or before the editor loads, the plain textarea edits and submits the same field. Acceptance: a system test with JavaScript disabled types into the field and submits it, and a JS-enabled test shows the textarea value equals the editor text after a 300 ms idle.
- **EDIT-02** (MUST) Source mode is the 0.1 default: it shows every character of the markdown, styles syntax (headings, emphasis, links, code, lists, quotes, tables) and dims markers without hiding them. Acceptance: a system test loads a fixture with every v1 construct that fits in one viewport and asserts the drawn lines' text (each `.cm-line` innerText joined with a newline) equals the stored markdown byte for byte.
- **EDIT-03** (MUST) A preview shows the render core's HTML for the current text: side by side at 1024 CSS px and wider, as a toggled view below that, refreshed on a debounce and never on each keystroke. Acceptance: a system test types a table and a footnote, waits for the debounce, and asserts the preview HTML equals the render core's output for the same text, with one preview request per typing burst.
- **EDIT-04** (MUST) Switching mode never changes the text and keeps the caret, the selection and the scroll position of the caret line. Acceptance: a system test cycles through every enabled mode with a selection set and asserts the text digest, selection range and caret line position are unchanged.
- **EDIT-05** (MUST) The chosen mode is a per-user preference: the editor applies a mode the host passes in and emits an event when the writer changes it, so the host can store it. Acceptance: a system test switches mode, asserts the event carries the new mode, reloads with that mode passed in and sees it applied.
- **EDIT-06** (SHOULD) Live mode hides markdown markers outside the element at the caret and reveals them for that element (word or element granularity, never the whole block) without moving any other line. Acceptance: a system test moves the caret into a bold word in a multi-line paragraph and asserts the vertical position of every other line is unchanged within 1 px.
- **EDIT-07** (SHOULD) Live mode becomes the default only when the IME and dead-key matrix of EDIT-34 passes in Live mode, and Source stays one action away. Acceptance: the release checklist of the version that changes the default links a passing EDIT-34 run for Live mode.
- **EDIT-08** (SHOULD) The side-by-side preview follows the editor's scroll position by source line. Acceptance: a system test scrolls the editor to a heading near the end and asserts the same heading is in the preview's viewport.

### Shortcuts and toolbar

- **EDIT-09** (MUST) The gem ships the 0.1 rows of the shortcut table in this doc, binding italic above CodeMirror's `selectParentSyntax` and, when the app turns submit on, submit above `insertBlankLine`. Acceptance: a system test per row presses the chord on a fixture selection and asserts the resulting markdown text (or the save request for Mod+S, and the form submit for Mod+Enter with submit turned on), with the Windows/Linux modifier and with the macOS modifier via a `navigator.platform` override set before load; the EDIT-38 release checklist presses each 0.1 chord once in Firefox and Safari.
- **EDIT-10** (MUST) Formatting commands are toggles: applied to text that already has the format they remove it, and every command is one undo step. Acceptance: a system test presses Mod+B twice on a selection and gets the original text back, then presses Mod+Z once after a list command and gets the text before it.
- **EDIT-11** (MUST) Enter continues a list item, task item or quote with the same marker, Enter on an empty item ends the list, and Backspace after a marker removes one level, using `markdownKeymap`. Acceptance: a system test types three list items and an empty fourth, and asserts the text has three `-` items and the caret on a plain line.
- **EDIT-12** (MUST) Tab indents and Shift+Tab outdents only inside list items (inside tables they move between cells once EDIT-22 ships); anywhere else Tab moves focus, and Escape then Tab always leaves the editor. Acceptance: a system test presses Tab in a paragraph and sees focus leave the editor, presses Tab in a list item and sees the item indented, and presses Escape then Tab inside a list and sees focus leave.
- **EDIT-13** (MUST) Find and replace runs in the editor (Mod+F opens CodeMirror's search panel) so matches in off-screen text are found. Acceptance: a system test on a 100 KB fixture searches for a word that exists only in the last paragraph and asserts the editor scrolls to it and selects it.
- **EDIT-14** (MUST) The toolbar follows the APG toolbar pattern: one tab stop, arrow keys between buttons, an accessible name, `aria-pressed` on format toggles that reflects the format at the caret, and every button shows its shortcut in its tooltip and accessible description; a keyboard help, opened from a toolbar button with no default chord, lists every active binding including Escape then Tab to leave the editor, and the content element's `aria-describedby` points at a short hint ("Escape then Tab leaves the editor; keyboard help is in the toolbar"). Acceptance: a system test tabs into the toolbar once, moves with ArrowRight, places the caret in bold text and asserts the bold button has `aria-pressed="true"`, then opens the keyboard help and asserts it lists Escape then Tab.
- **EDIT-15** (MUST) Apps can add, remove and rebind shortcuts and toolbar items through configuration (API shape owned by DX), and the gem warns in development when two bindings use the same chord. Acceptance: a dummy-app test rebinds italic to another chord and asserts the old chord no longer formats and a duplicate chord logs a warning.
- **EDIT-16** (COULD) Switching between Source and Live, focus mode and typewriter mode have commands an app can bind to chords, unbound by default as in Obsidian. Acceptance: a dummy-app test binds the Source and Live command to a chord and asserts pressing it switches mode.

### Paste and drop

- **EDIT-17** (MUST) Pasting a URL while text is selected wraps the selection as `[text](url)`; pasting a URL with no selection inserts the bare URL. Acceptance: a system test pastes `https://example.com` over a selected word and asserts `[word](https://example.com)`, then pastes it on an empty line and asserts the line equals the URL.
- **EDIT-18** (MUST) Pasting plain text inserts it byte for byte after line breaks are normalized to `\n`, and Mod+Shift+V always pastes plain text with no conversion and no link wrap. Acceptance: a system test pastes a markdown fixture with tabs, trailing spaces and `*` bullets and asserts the inserted text equals the clipboard text, then puts an HTML fragment containing a link on the clipboard, selects a word, presses Mod+Shift+V and asserts the word is replaced by the clipboard's plain text with no link wrap and no conversion.
- **EDIT-19** (MUST) Pasting or dropping an image inserts a placeholder at the caret or drop point, uploads it through the host's upload hook, replaces the placeholder with `![alt](url)` on success, and removes it with an announced error on failure; other files dropped are rejected with a message unless the host allows them. Acceptance: a system test drops an image with a stubbed upload hook and asserts the final markdown, then fails the hook and asserts the placeholder is gone and an error status was announced.
- **EDIT-20** (MUST) Every image upload asks for alt text in a labelled field that the writer can skip, and a skipped alt is left empty and flagged rather than filled with the file name. Acceptance: a system test drops `IMG_0042.png`, types alt text in the prompt and asserts it lands in the markdown; a second drop skips the prompt and asserts `![](url)` plus a visible flag.
- **EDIT-21** (SHOULD) Pasting structural HTML (headings, lists, links, emphasis, tables, code) converts it to markdown in the pinned dialect: ATX headings, fenced code, `-` bullets, GFM tables, and never raw HTML. Acceptance: a system test pastes HTML copied from a Google Docs fixture and asserts the expected markdown, and a paste from a code-editor fixture (HTML of plain `pre` lines) inserts the plain text unchanged.

### Tables and the `/` menu

- **EDIT-22** (SHOULD) Table commands work on GFM pipe text: insert a table, format (align pipes), add and delete a row or column, set column alignment, and Tab or Shift+Tab between cells with a new row after the last cell; each command is one undo step and writes only pipe syntax. Acceptance: a system test inserts a 3 by 2 table, tabs through every cell typing values, adds a column, formats it and asserts the text equals a fixture.
- **EDIT-23** (SHOULD) Typing `/` at the start of a line or after a space opens a filterable menu built on the APG combobox pattern that inserts markdown text (headings, lists, task list, quote, code fence, table, GitHub alert types, footnote, divider, image upload, and Mermaid and math fences when the dialect enables them); Escape closes it and leaves the `/` typed. Acceptance: a system test types `/tab`, presses Enter and asserts a table template was inserted, then types `/` and Escape and asserts a literal `/` remains.
- **EDIT-24** (SHOULD) The `/` menu can be turned off and its items extended by the app, and it never opens inside code spans, code fences or URLs. Acceptance: a dummy-app test with the menu disabled types `/` at line start and sees no popup, and a default-config test types `/` inside a code fence and sees no popup.

### Save, conflict and recovery

- **EDIT-25** (MUST) The editor tracks a save state (clean, dirty, saving, saved, offline, conflict), shows it in a visible indicator and announces changes through a polite live region. Acceptance: a system test types, triggers a stubbed save and asserts the indicator and the live region move from dirty to saving to saved.
- **EDIT-26** (MUST) The editor emits a debounced change event carrying the text and a save request on Mod+S, and exposes calls the host uses to report saved, failed and conflict (with the server text), so the host app owns the endpoint and the lock check. Acceptance: a dummy-app test wires a fake autosave endpoint to the events and asserts one request per typing burst and the saved state after the host reports success.
- **EDIT-27** (MUST) A conflict reported by the host shows a banner that keeps the writer's text in the editor and offers to compare (the two texts side by side, read-only), keep mine or take theirs; the editor never replaces local text without that choice. Acceptance: a system test makes the stubbed endpoint answer conflict, asserts the local text is unchanged and the banner is focusable, and chooses "take theirs" to see the server text loaded.
- **EDIT-28** (MUST) When the host passes a backup key, unsaved text is kept in browser storage under that key, offered for restore on the next load when it differs from the stored value, cleared after a confirmed save, and expired after a host-set age (default 7 days); without a key nothing is stored. Acceptance: a system test types, reloads without saving and sees the restore offer, accepts it and sees the text, then saves and reloads to see no offer, and with the clock stubbed past the age, a reload offers no restore.
- **EDIT-29** (MUST) Leaving the page with unsaved changes asks for confirmation, both on a full unload and on a Turbo visit. Acceptance: a system test types without saving, clicks a Turbo link and asserts the confirmation appears, reloads the page and asserts the `beforeunload` dialog appears, then saves and repeats both to see neither.

### Focus, typewriter and counts

- **EDIT-30** (MUST) The editor shows word count, character count and reading time for the document and for the selection when there is one, counted with the word rule RENDER defines for `word_count` (on the client: `Intl.Segmenter` word segments with `isWordLike`, in the field's locale, over the text without markdown markers, link targets or image URLs) and updated on a debounce. Acceptance: a system test with locale `es` types a Spanish fixture and asserts the counts, then selects one sentence and asserts the selection count.
- **EDIT-31** (MUST) The client word count matches the render core's `word_count` on every fixture of a shared counting corpus (contractions, hyphenated words, decimal numbers, `¿`/`¡` punctuation, emoji, links, images, code), so the editor and the published page never disagree. Acceptance: a test runs the corpus through the client counter in the CI browser and through the render core and asserts equal counts for every fixture.
- **EDIT-32** (SHOULD) Focus mode dims all but the current sentence or paragraph to a colour that still meets 4.5:1 against the background (THEME supplies the token), and typewriter mode keeps the caret line vertically centred; both change only the view, never the text, and respect `prefers-reduced-motion`. Acceptance: a system test turns on focus mode, asserts the caret paragraph uses the full-contrast colour and the others the dim token, the text digest is unchanged and an axe scan reports no colour-contrast violation, and with typewriter mode on asserts the caret line stays within 10 percent of the viewport centre while typing.

### Performance

- **EDIT-33** (MUST) The gem's own work per keystroke stays within 16 ms at the 95th percentile on a 100 KB document in Source mode (and in Live mode once it ships), a 1 MB document stays editable with no long task over 200 ms, and preview, counts and textarea sync never run synchronously in the key handler. Acceptance: a system test types 200 characters into the 100 KB and 1 MB fixtures, measures the gem's handlers with `performance.measure` marks in test builds and records long tasks with a `PerformanceObserver`, and asserts both limits on the CI runner with CDP `Emulation.setCPUThrottlingRate` set to 4.

### Composition, accessibility and mobile

- **EDIT-34** (MUST) Composition works in every shipped mode: no decoration, toolbar state or sync rewrites text inside an active composition, and dead keys, IME and on-screen keyboards produce exactly the composed characters. Acceptance: a system test drives CDP `Input.imeSetComposition` and `Input.insertText` to compose `é`, `ñ` and `¿Qué?` right after a link, bold text and a list marker and asserts the textarea value, drives the Windows dead-key path with CDP `Input.dispatchKeyEvent` (a keydown with `key` `Dead`, then the composed character) and asserts the same, plus a manual matrix run before each release (macOS Safari, Chrome and Firefox with the Spanish and US International layouts, Windows Chrome and Edge with US International, iOS Safari Spanish keyboard, Android Gboard Spanish, one Japanese IME smoke test).
- **EDIT-35** (MUST) The editable element has an accessible name taken from the field's label, `aria-multiline`, a description pointing at the keyboard help, no line-number gutter by default, and native spellcheck, autocorrect and autocapitalize turned on for prose. Acceptance: a system test asserts the content element's computed accessible name equals the label text, `spellcheck` is `true`, `autocorrect` is `on`, `autocapitalize` is `sentences`, `aria-describedby` points at the keyboard hint, no `.cm-gutters` element exists, and an axe scan of every mode reports no violations.
- **EDIT-36** (MUST) The editor passes WCAG 2.2 AA: keyboard access to every function, no keyboard trap, visible focus not hidden by sticky toolbars or banners, reflow at 320 CSS px without two-dimensional scrolling of prose, 24 by 24 CSS px targets, 3:1 contrast for controls and focus, 4.5:1 for text including dimmed markers. Acceptance: the gem's system tests run `axe-core-capybara` on every mode at 320 px and 1280 px widths with no violations; at 320 px they assert the editor and preview containers have no horizontal overflow (`scrollWidth <= clientWidth`); a keyboard-only test reaches every toolbar, menu and banner action and at each stop asserts the focused element's box does not intersect a sticky toolbar or banner; and the release checklist records a 3:1 check of the focus indicator and control boundaries, which axe does not measure.
- **EDIT-37** (MUST) Effects that are visible but easy to miss are announced through CodeMirror's `EditorView.announce`: mode changes, inserted table rows and columns, upload results and search result counts (save state has its own status region, EDIT-25). Acceptance: a system test performs each action and asserts the expected text in the editor's live region.
- **EDIT-38** (MUST) Source mode is verified with VoiceOver on Safari and NVDA on Firefox or Chrome before each release: reading the document, moving by line and word through a 100 KB fixture past the first screen, hearing the toolbar state and the save status. Acceptance: the release checklist records a pass for each step of the screen reader script for both pairs, including the step that reads text that was off-screen at load.
- **EDIT-39** (SHOULD) In Live mode the text a screen reader reaches equals the markdown text, or the editor tells screen reader users that Source mode reads the full text and offers it from the keyboard help. Acceptance: the EDIT-38 script run in Live mode records that every hidden marker is either read or reachable through the documented switch.
- **EDIT-40** (MUST) On narrow screens and touch devices the editor shows one view at a time with a mode toggle, keeps the toolbar reachable above the on-screen keyboard, and has no hover-only control. Acceptance: a system test at 375 by 812 CSS px asserts no side-by-side preview and every toolbar action reachable by tap, and the manual matrix of EDIT-34 checks the toolbar above the iOS and Android keyboards.
- **EDIT-41** (MUST) Every visible string, tooltip, accessible name and announcement the editor produces is translatable and follows the field's locale, with English and Spanish shipped; where the strings live and how they reach the client is RAILS's i18n work. Acceptance: a system test renders the editor with locale `es` and asserts the toolbar names, keyboard help, save status and an upload error announcement are in Spanish, and with locale `en` that the same elements are in English.

### Later

- **EDIT-42** (COULD) Apps can register completion providers on trigger characters (`@`, `#`, `[[`, `:`) that insert markdown links or text, using the same combobox pattern as the `/` menu. Acceptance: a dummy-app test registers an `@` provider and asserts choosing a suggestion inserts its markdown link.
- **EDIT-43** (COULD) A URL pasted alone on an empty line can be marked by the editor as an embed candidate when the render core supports embeds, while the stored text stays the bare URL. Acceptance: a system test with embeds enabled pastes a supported URL on an empty line and asserts the text is the URL and the preview shows the embed.

## Developer experience notes

The defaults carry most of the weight: an app that writes `f.markdown_field :body` gets Source mode, the preview, the 0.1 shortcuts, uploads off until the app passes an upload hook or opts into the RAILS area's Active Storage default, and EN and ES strings, with no configuration. What each group costs a newcomer:

- **Modes (EDIT-01 to EDIT-08)**: one option listing the enabled modes and an optional initial mode. Storing the per-user mode (EDIT-05) is opt-in: the app listens for one event. No server code is needed for the preview beyond the endpoint RENDER and RAILS define.
- **Shortcuts and toolbar (EDIT-09 to EDIT-16)**: nothing to learn for the defaults. Customization (EDIT-15) is the largest new API surface in this area: a keymap and toolbar configuration with named commands. The development warning on duplicate chords is what keeps that surface from producing silent bugs. A keyboard help panel documents the escape hatch, so apps do not have to.
- **Paste and drop (EDIT-17 to EDIT-21)**: uploads need one hook from the app (or the RAILS area's Active Storage default). HTML conversion adds a lazy-loaded dependency, which ASSETS has to budget; apps that do not want it turn it off.
- **Tables and `/` menu (EDIT-22 to EDIT-24)**: no cost by default; extending the menu means registering items with a label, keywords and the text to insert, which is the second API surface to document.
- **Save and recovery (EDIT-25 to EDIT-29)**: the costliest part for a newcomer, because autosave needs an endpoint. The gem should work without it (plain form submit, dirty-state warning only) and document a one-screen recipe for autosave with `lock_version` (owned by RAILS and DX). The backup key is optional, which keeps shared computers safe by default.
- **Counts, focus and performance (EDIT-30 to EDIT-33)**: no API; the shared counting corpus (EDIT-31) is a gem test asset, not an app concern.
- **Composition, accessibility and mobile (EDIT-34 to EDIT-41)**: no API beyond the field label the form builder already renders. The cost lands on the gem's CI and release checklist (manual matrix, screen reader script), which is the price of making accessibility a default instead of an app's homework.
- **Error messages**: an upload hook missing while uploads are on, a duplicate chord and a missing label are development-time warnings that name the option to set.

## Open decisions

- Which mode is the default in 0.1? Recommendation: Source, as the report says. Live waits for EDIT-34 to pass in Live mode (EDIT-07), because the IME and layout-jump risk sits in the custom decorations and Spanish writers on macOS use the composition path on every accent.
- Should Tab indent? Recommendation: indent only inside list items, move between cells inside tables (EDIT-22), move focus everywhere else, with Escape then Tab always leaving (EDIT-12). Writers expect Tab to indent list items, and keyboard users must not be trapped in a long field; binding Tab everywhere, CodeMirror's `indentWithTab`, gives code-editor behaviour to a prose field.
- What does Mod+Shift+V do? Recommendation: plain paste, the OS meaning, instead of GitHub's "replace selection with link", because plain Mod+V already makes a link over a selection (EDIT-17) and writers need one guaranteed no-conversion paste once HTML conversion ships.
- Where does the preview sit by default? Recommendation: side by side from 1024 CSS px, a toggle below (EDIT-03), because parity is the trust signal and a side-by-side preview shows it without a click; the breakpoint is configurable.
- Which word rule do the editor and the render core share? Recommendation: RENDER owns the rule; EDIT asks for Unicode word segmentation (UAX #29, which `Intl.Segmenter` implements) over the rendered text (no link targets, image URLs or markers), with the server using the same rule rather than a whitespace or regex split, which counts `don't` and `3.5` differently and would make EDIT-31 fail by construction. If RENDER cannot run UAX #29 in Ruby, both sides implement one simpler rule identically and EDIT-30 drops `Intl.Segmenter`.
- Turndown or an own converter for HTML paste? Recommendation: Turndown with the GFM plugin, configured for ATX headings, fenced code and `-` bullets, plus a small task-list rule, lazy-loaded on the first HTML paste; it is MIT and mature, and an own converter is a maintenance cost with no UX gain.
- Is the `/` menu on by default? Recommendation: on, at line start or after a space only, with a config switch (EDIT-24), because it is the discoverability aid for writers who do not know markdown and stays out of the way for those who do.
- Does Mod+Enter submit the form by default? Recommendation: off, enabled by one option, because in an article form the submit button can save or publish and a writer adding a blank line should never trigger it; GitHub-style comment fields turn it on.
- Is the local backup on by default? Recommendation: on only when the host passes a backup key (EDIT-28), cleared after a confirmed save, so a shared or public computer never keeps a draft the app did not ask for.

## Sources

Benchmark inputs (cited throughout, settled questions not re-researched):

- `docs/features/markdown-editor/reports/Markdown editor benchmark.md`
- `docs/features/markdown-editor/research_notes/Markdown editor benchmark/editing_ux_products.md`
- `docs/features/markdown-editor/research_notes/Markdown editor benchmark/editor_libraries.md`

Web sources:

- https://obsidian.md/help/edit-and-read (accessed 2026-11-03)
- https://news.ycombinator.com/item?id=41254936 (accessed 2026-11-03)
- https://md.informatik.uni-ulm.de/s/features (accessed 2026-11-03)
- https://docs.github.com/en/get-started/accessibility/keyboard-shortcuts (accessed 2026-11-03)
- https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax (accessed 2026-11-03)
- https://unpkg.com/@codemirror/commands/dist/index.d.ts (accessed 2026-11-03)
- https://unpkg.com/@codemirror/search/dist/index.js (accessed 2026-11-03)
- https://unpkg.com/@codemirror/view@6.43.15/dist/index.d.ts (accessed 2026-11-03)
- https://unpkg.com/@codemirror/view@6.43.15/dist/index.js (accessed 2026-11-03)
- https://codemirror.net/examples/tab/ (accessed 2026-11-03)
- https://codemirror.net/examples/million/ (accessed 2026-11-03)
- https://support.typora.io/Quick-Start/ (accessed 2026-11-03)
- https://support.typora.io/Table-Editing/ (accessed 2026-11-03)
- https://support.google.com/docs/answer/12014036 (accessed 2026-11-03)
- https://github.com/mixmark-io/turndown (accessed 2026-11-03)
- https://www.notion.com/help/keyboard-shortcuts (accessed 2026-11-03)
- https://support.craft.do/en/write-and-edit/formatting/slash-menu (accessed 2026-11-03)
- https://www.w3.org/WAI/ARIA/apg/patterns/combobox/ (accessed 2026-11-03)
- https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/ (accessed 2026-11-03)
- https://docs.gitlab.com/development/fe_guide/content_editor/ (accessed 2026-11-03)
- https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html (accessed 2026-11-03)
- https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html (accessed 2026-11-03)
- https://www.w3.org/TR/WCAG22/ (accessed 2026-11-03)
- https://ia.net/writer/how-to/edit-and-polish (accessed 2026-11-03)
- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Segmenter (accessed 2026-11-03)
- https://web.dev/articles/inp (accessed 2026-11-03)
- https://pavelfatin.com/typing-with-pleasure/ (accessed 2026-11-03)
- https://bugzilla.mozilla.org/show_bug.cgi?id=2071227 (accessed 2026-11-03)
- https://issues.joomla.org/tracker/joomla-cms/48153 (accessed 2026-11-03)
- https://github.com/sourcegraph/sourcegraph-public-snapshot/pull/44148 (accessed 2026-11-03)
- https://github.com/dequelabs/axe-core-gems (accessed 2026-11-03)
- https://forum.obsidian.md/t/issue-extra-latin-character-inserted-when-typing-japanese-ime-right-after-a-markdown-link/118859/4 (accessed 2026-11-03)
- https://lists.w3.org/Archives/Public/public-webapps/2016JanMar/0033.html (accessed 2026-11-03)
- https://lists.w3.org/Archives/Public/public-webapps-github/2023Jul/0056.html (accessed 2026-11-03)
- https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/isComposing (accessed 2026-11-03)
- https://chromedevtools.github.io/devtools-protocol/tot/Input/ (accessed 2026-11-03)
