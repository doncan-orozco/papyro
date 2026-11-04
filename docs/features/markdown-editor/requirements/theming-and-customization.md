# THEME: Theming and customization requirements for the Md gem

This doc covers how the Md gem looks native in an app it has never seen. It sets the design tokens the viewer and the
editor read, light and dark modes, prose typography, code highlighting, the CodeMirror theme, Mermaid and KaTeX colors,
the cascade-layer contract that lets app CSS win, presets and the eject generator. It also covers non-visual
customization: toolbar layout and icons, translated UI strings and per-field configuration. Theming is the third
priority of the gem, after developer experience and the writer's and reader's experience. So the default has to look
right with no work, and a full restyle has to be a short token file, never a fork of the stylesheet.

## Scope

This doc decides:

- the token set (names, count, groups, light and dark defaults) shared by the viewer, the editor, code, diagrams and
  math;
- how the gem's CSS is layered so that app CSS and Tailwind utilities override it without `!important`;
- how light and dark modes are triggered;
- the customization path for a Tailwind app, a plain-CSS app and a chadcn (shadcn) app;
- presets, the eject generator and how upgrades treat ejected files;
- toolbar layout, icons, UI-string translation and per-field configuration, as configuration surface.

It leaves to other areas:

- how the CSS and JavaScript files reach the browser (importmap pins, Propshaft, jsbundling, the npm package): ASSETS;
- what the toolbar buttons do, shortcuts, modes and accessibility of the editing surface: EDIT;
- which HTML the renderer emits and the sanitizer allowlist (class names included): RENDER;
- form-builder and component signatures in ERB, Phlex and ViewComponent: VIEWS;
- the review UI of agent suggestions, beyond the two colour tokens it reads: AGENT;
- generator and configuration conventions in general (naming, `Md.configure`, the install generator): DX;
- Rails i18n beyond the gem's own UI strings (content locale, translated attributes, locale-aware rendering and caching):
  RAILS; this doc owns only the `md.*` UI-string keys and their override path.

Out of scope (WON'T for the first releases):

- a visual theme builder or a theme marketplace;
- per-document or per-author themes stored in the database;
- Sass or Less sources (the gem ships plain CSS with custom properties);
- web fonts loaded by the gem (it uses the app's font stacks; the KaTeX math fonts are the one exception);
- server-side theming of Mermaid SVG for RSS, email or OG images (a later phase in the benchmark roadmap).

## Questions

1. Which token set (names and count) covers the viewer, the editor, code, diagrams and math?
2. How does an app with Tailwind, one with plain CSS and one with chadcn each customize the look?
3. Does the gem ship presets, an eject generator, or both, and how do upgrades treat ejected files?
4. What are the draft token defaults for light and dark?
5. How do app styles beat gem styles without `!important` or higher specificity?
6. How are the toolbar, its icons, the UI strings and per-field options customized?

## Findings

The benchmark settles the starting point: the viewer ships "prose styles built on CSS variables (theme tokens;
shadcn-compatible, so it looks native in chadcn apps and has sensible defaults elsewhere)", and commonmarker should emit
CSS classes for code (`theme: ""`) "so Tailwind theme tokens can style it" (`../reports/Markdown editor benchmark.md`,
sections "What the gem provides" and "commonmarker 2.x and a pinned GitHub-compatible dialect"). The research notes add
no theming evidence beyond that (they cover paradigms, libraries and agents), so the sources below were read for this
doc on 2026-11-03.

### How existing markdown and editor stylesheets expose theming

| Stylesheet | Variables | Light and dark | Override model | Notes |
|---|---|---|---|---|
| Tailwind Typography (`prose`) | 16 colour variables `--tw-prose-*` plus 16 `--tw-prose-invert-*` | `prose-invert` class, usually `dark:prose-invert` | element modifiers (`prose-a:…`, `prose-headings:…`), `not-prose` to opt out, custom `@utility prose-x` themes | colours only; sizes come from the `prose-sm` to `prose-2xl` classes |
| github-markdown-css | 60 Primer variables (`--fgColor-default`, `--bgColor-muted`, `--borderColor-default`, 32 `--color-prettylights-syntax-*`) | `prefers-color-scheme` media query in the default file; separate light, dark, dimmed, high-contrast and colorblind files | `.markdown-body` wrapper; edit or replace variables | code-highlight colours are part of the same variable set |
| Pico CSS | 130+ `--pico-*` variables, split into scheme-independent style variables and scheme-dependent colour variables | light by default; `data-theme="dark"` forces dark; `prefers-color-scheme` when no attribute is set | override variables; Sass to change the prefix | the clearest "attribute or media query" model |
| Lexxy | about 70 `--lexxy-*` variables in `lexxy-variables.css` (ink scale, accent scale, 8 code-token colours, `--lexxy-text-size`) | no built-in dark mode; apps override the colour variables | separate `lexxy-variables.css`, `lexxy-content.css`, `lexxy-editor.css`; the docs suggest copying the CSS into the app | derived colours use `color-mix(in oklch, …)`; no `@layer` |
| Trix (Action Text default) | none for colours; only `--icon-*` variables holding toolbar icon images | none | plain element and class selectors with fixed values (`border: 1px solid #bbb`) | the baseline Rails developers know, restyled by overriding selectors |
| Marksmith | none documented | `.dark` class on any ancestor (`div`, `form_with` or `html`) | `class` and `style` options on the field; CSS compiled with the Tailwind CLI at release | the closest Rails prior art to the gem |
| Papyro `article-prose` (this repo) | none of its own; reads shadcn tokens (`--color-primary`, `--color-muted`, `--color-border`) | follows the shadcn `.dark` switch | rules in `@layer components` with `:where()` selectors, so specificity is zero | `color-mix(in oklab, var(--color-muted) 72%, transparent)` derives tints from the theme |

Three lessons follow. First, variable count is not quality: Primer's 60 and Pico's 130 cover a whole design system,
while Tailwind Typography restyles all prose with 16 colours. A markdown gem needs enough tokens to reach code, alerts
and the editor, and few enough that a newcomer can read the list on one screen. Second, derived colours (`color-mix`)
let a small base set produce tints, which is how Lexxy and Papyro already work. Third, every stylesheet that ships a
dark mode picks one trigger (class, attribute or media query), and Rails apps use all three, so the gem has to accept
each of them.

### shadcn tokens and chadcn

shadcn/ui themes with 32 variables (31 colours plus `--radius`): `--background`, `--foreground`, `--card`, `--popover`,
`--primary`, `--secondary`, `--muted` and `--accent` (each with a `-foreground` pair), `--destructive`, `--border`,
`--input`, `--ring`, five chart colours, eight sidebar colours and `--radius`. Dark mode overrides the 31 colour names
under `.dark`, and colours are `oklch()`. chadcn (the Phlex port Papyro uses) keeps these names unchanged in
`app/assets/tailwind/theme/theme.css`, maps them to Tailwind utilities in `tokens.css` with `@theme inline`, declares
`@custom-variant dark (&:is(.dark *))`, and switches presets with `bin/rails theme:use[slate]` and `theme:import`. If the
gem's tokens fall back to these names, a chadcn or shadcn app gets a matching viewer and editor with no configuration,
and every `theme:use` restyles them too.

### Cascade layers

Unlayered styles beat every layered style whatever their order and specificity; layers are ordered by their first
declaration; and `!important` reverses the order (MDN, `@layer`, Baseline since March 2022). Tailwind v4's entry file
starts with `@layer theme, base, components, utilities;`, and Tailwind's docs put component classes in `components` so
that utilities can override them. Two consequences decide the gem's CSS contract:

- In a plain-CSS app, gem rules inside any layer lose to the app's normal (unlayered) rules, which is the wanted
  behaviour.
- In a Tailwind app, a gem layer declared after Tailwind's layers would sit above `utilities` and beat utility classes,
  and a gem layer declared before them would sit below `base` and lose to Preflight's resets of margins and headings.
  So the gem's rules belong inside Tailwind's `components` layer (`@import "md.css" layer(components)`), which is where
  Papyro's `article-prose` already lives.

`:where()` keeps every gem selector at zero specificity, so even inside one layer an app selector of any specificity
wins. Papyro's reader styles already combine both techniques.

### Where tokens are declared

A custom property whose value reads another one (`--_md-link: var(--_md-accent)`, or
`--_md-border: var(--md-border, var(--border, #e4e4e7))`) is resolved on the element that declares it, and descendants
inherit the resolved value. If the gem declared its tokens on `:root`, a `.dark` class or a `--md-accent` override set on
a wrapper below the root would not reach the derived tokens, yet chadcn's `@custom-variant dark (&:is(.dark *))` allows
`.dark` on any ancestor and THEME-08 promises wrapper scoping. If the gem declared them on its own root instead, an app override on
`:root` would lose to it. So the gem never declares a public `--md-*` token: on its own roots
(`:where(.md-viewer, .md-editor)`) it resolves each one into a private `--_md-*` property through the chain public
token, then the "Falls back to" variable, then the default
(`--_md-background: var(--md-background, var(--background, #ffffff))`), derived tokens read the private names of their
sources, and gem rules read only private names. An app sets public tokens on `:root`, `.dark` or any wrapper and always
wins, because the gem never declares them. This follows from how custom properties compute; THEME-08 makes it testable.

### Code highlighting from tokens

commonmarker highlights fenced code with syntect, with the `base16-ocean.dark` theme by default, and emits CSS classes
instead of inline colours when the theme is `""`; custom `.tmTheme` files can be loaded from a path. CodeMirror 6 themes
are extensions: `EditorView.theme` takes CSS rules scoped to the editor (`{dark: true}` turns on the library's dark
defaults), `HighlightStyle.define` maps `@lezer/highlight` tags to styles, and `classHighlighter` emits static `tok-*`
classes (`tok-keyword`, `tok-comment`). Shiki's `createCssVariablesTheme` shows the pattern for client-side highlighters:
one `--shiki-token-*` variable per token kind (nine kinds: constant, string, string expression, comment, keyword,
parameter, function, punctuation, link), with the caveat that it is less granular than a full theme. Lexxy settles on 8
code-token colours, Primer on 32. The conclusion: the server stylesheet maps syntect classes to the 11 code tokens
(`--md-code-*`, read through their resolved private names), and the editor maps the same Lezer tag groups to the same
tokens. Then the code a writer sees in the editor and the code a reader sees on the page share one
palette, which is part of the preview-parity promise of the benchmark.

CodeMirror theme values are plain CSS declarations, so `var(--_md-…)` in an `EditorView.theme` resolves at paint time
against the private names THEME-02 resolves on the editor root, and a token change or a `.dark` toggle restyles the
editor without rebuilding the extension. This is an inference from the styling model, to be confirmed in the integration
spike (THEME-09 makes it testable).

### Diagrams and math

Mermaid's theming engine accepts only hex colours (it "will only recognize hex colors and not color names"), and only
the `base` theme takes `themeVariables` (`primaryColor`, `primaryTextColor`, `primaryBorderColor`, `lineColor`,
`secondaryColor`, `tertiaryColor`, `background`, `fontFamily`, `fontSize`, `darkMode`). `securityLevel: 'strict'`, the
default, encodes HTML in labels and disables click handlers. So Mermaid cannot read CSS variables directly: the gem's
Stimulus controller has to read the resolved token values (the private `--_md-*` properties computed on the root),
convert them to hex (`oklch()` values included), pass them as `themeVariables` of the `base` theme, and render again
when the colour scheme changes.

KaTeX renders math at 1.21 times the surrounding font size (overridable with `.katex { font-size: … }`) and expects its
fonts in a `fonts` directory next to its stylesheet. Its `errorColor` option (default `#cc0000`) is the only colour it
sets itself. Math therefore needs one size token, plus an error colour mapped to the theme's caution colour. Whether
KaTeX output inherits the text colour of its container is not stated in the KaTeX docs and is a spike check.

### Non-visual customization

Lexxy is the clearest model for configuration precedence: `Lexxy.configure({ default: … })` for every editor, named
presets that extend the default and are picked per editor with `preset="name"`, and HTML attributes on one element that
override both. Its options include `toolbar` (`false`, the id of an external `lexxy-toolbar`, or an object), `headings`
(the levels in the heading dropdown, `h2` to `h4` by default), `attachments`, `tables`, `markdown` and `multiLine`. Lexxy
documents no general translation system; its only localized option is `uploadsBusyMessage`. Marksmith's field options are
`enable_file_uploads`, `upload_url`, `extra_preview_params`, `class`, `style` and the standard input attributes; it
documents neither toolbar customization nor translated labels. Trix exposes its toolbar icons as `--icon-*` CSS
variables holding images. Rails already has the right tool for UI strings: an engine ships `config/locales` files, and
the app overrides any of them by defining the same key in its own locale files (Rails i18n guide). Papyro needs every
UI string in English and Spanish.

### Answers to the questions

1. **Token set.** 45 tokens with the `--md-` prefix, in five groups: 12 base tokens (surface, text, accent, border,
   ring, radius, three font stacks), 12 prose and alert tokens, 11 code tokens, 9 editor tokens and 1 math token.
   Diagrams read the base group (THEME-11). The 12 base tokens restyle surfaces, text, accent and fonts: all the others
   default to a value derived from them with `var()` or `color-mix()`, or to a fixed value (code and alert hues, prose
   sizes, math size). The draft list with light and dark defaults is under THEME-02.
2. **Customization by app type.** A chadcn or shadcn app does nothing: the base tokens fall back to the shadcn variables,
   so `theme:use` restyles the viewer and the editor. A Tailwind app without shadcn imports the gem CSS into its
   `components` layer, sets a few `--md-*` tokens, and adds utility classes through the helpers' `class:` option;
   utilities win because they sit in a later layer. A plain-CSS app links the stylesheet and overrides `--md-*` tokens or
   any selector in its own CSS; its normal unlayered rules win. Step by step under "Customization paths" below.
3. **Presets and eject.** Both. Presets are named sets of defaults (a short list, THEME-12) switched with one setting or
   per field. The eject generator writes the active preset's values as a token file by default and copies the full
   stylesheet only with `--full`. Ejected token files are upgrade-safe, because every token the file omits still resolves
   to the gem's default at the end of its chain. Ejected full stylesheets carry a version stamp, and a check task lists
   what changed since that version (THEME-14, THEME-21).
4. **Draft defaults.** In the table under THEME-02, in hex where the value is fixed.
5. **App wins.** Gem rules live in a cascade layer (`md`, nested inside Tailwind's `components` in Tailwind apps, with
   vendor CSS in a sub-layer beneath it) and use `:where()` selectors, so any app rule wins with no `!important` and no
   specificity race (THEME-06).
6. **Non-visual customization.** A toolbar item list with groups, configured globally, per preset and per field (in that
   precedence); an inline-SVG icon set with an app-supplied icon resolver; every UI string in the gem's `config/locales`
   (English and Spanish), overridable by the app's locale files and rendered server-side into the markup, so the
   JavaScript needs no translation library (THEME-16 to THEME-20).

### Customization paths

**chadcn or shadcn app (zero configuration).** Import the gem's CSS into the `components` layer of the Tailwind entry
file, and the viewer and editor read the shadcn variables in the "Falls back to" column of THEME-02.
Dark mode follows the app's `.dark` class. `bin/rails theme:use[stone]` restyles the editor with the rest of the app. To
brand only the code palette, set the `--md-code-*` tokens in `theme.css`, outside the managed colour markers.

**Tailwind app without shadcn.** `@import "md.css" layer(components);` after `@import "tailwindcss";`. The base tokens
fall back to the gem's neutral defaults. Override the base tokens in a `:root` and a `.dark` block (5 to 12 lines), or
run `bin/rails generate md:theme` for a commented token file. Add utilities on the wrapper through the helper, for
example `markdown_view @post.body, class: "max-w-3xl mx-auto"`. Size classes such as `prose-lg` are not needed: the size
comes from `--md-text-size`.

**Plain-CSS app (Propshaft or Sprockets, no build step).** `stylesheet_link_tag "md"` before the app's stylesheet.
Override tokens on `:root`, `.dark` or `[data-theme="dark"]` in the app's CSS. Any selector the app writes, for example
`.md-prose h2 { letter-spacing: -0.01em }`, wins over the gem because the gem's rules are layered and use `:where()`.

## Requirements

Grouped by concern: tokens, cascade and modes, per-surface theming, presets and eject, non-visual customization, then
full eject.

### Tokens

- **THEME-01** (MUST) Every colour, font family and radius the viewer and the editor use, and the prose size, leading,
  measure and block spacing, come from a CSS custom property with the `--md-` prefix; other lengths are `em` multiples so
  they follow `--md-text-size`; no literal colour appears in a gem rule outside the token-resolution blocks.
  Acceptance: a test scans the gem's own stylesheets (not the vendored ones in `md.vendor`) and fails on any hex, rgb,
  hsl or oklch literal, any `font-family` or `border-radius` value that is not a `var(--_md-…)`, and any `rem` or `px`
  length other than a border width, outside those blocks.
- **THEME-02** (MUST) The gem ships the 45 tokens in the table below with light and dark defaults and never declares a
  public `--md-*` token: it resolves each one on its own roots into a private `--_md-*` property (public token, then the
  "Falls back to" shadcn or Tailwind variable, then the default, as in
  `var(--md-background, var(--background, #ffffff))`), every derived token reads the private names of its sources, and
  gem rules read only private names. Acceptance: a dummy app with no shadcn variables renders the viewer and the editor
  with the listed defaults, and a dummy app with a shadcn theme renders them with the shadcn colours, both checked by a
  computed-style system test.

Draft token list. "Falls back to" is the shadcn or Tailwind variable read after the public `--md-*` token; "derived"
tokens are defined by the formula shown, written with public names for readability (in the stylesheet each formula reads
the private `--_md-` name of its source); hex values are drafts to confirm against THEME-03.

| Group | Token | Falls back to | Light | Dark |
|---|---|---|---|---|
| base | `--md-background` | `--background` | `#ffffff` | `#09090b` |
| base | `--md-foreground` | `--foreground` | `#09090b` | `#fafafa` |
| base | `--md-muted` | `--muted` | `#f4f4f5` | `#27272a` |
| base | `--md-muted-foreground` | `--muted-foreground` | `#696970` | `#a1a1aa` |
| base | `--md-border` | `--border` | `#e4e4e7` | `#27272a` |
| base | `--md-accent` | `--primary` | `#2563eb` | `#60a5fa` |
| base | `--md-accent-foreground` | `--primary-foreground` | `#ffffff` | `#09090b` |
| base | `--md-ring` | `--ring` | `#71717a` | `#a1a1aa` |
| base | `--md-radius` | `--radius` | `0.5rem` | same |
| base | `--md-font-sans` | `--font-sans` | `ui-sans-serif, system-ui, sans-serif` | same |
| base | `--md-font-serif` | `--font-serif` | `ui-serif, Georgia, serif` | same |
| base | `--md-font-mono` | `--font-mono` | `ui-monospace, SFMono-Regular, Menlo, monospace` | same |
| prose | `--md-font-body` | derived | `var(--md-font-sans)` | same |
| prose | `--md-font-heading` | derived | `var(--md-font-body)` | same |
| prose | `--md-text-size` | none | `1rem` | same |
| prose | `--md-line-height` | none | `1.75` | same |
| prose | `--md-measure` | none | `65ch` | same |
| prose | `--md-block-space` | none | `1.25em` | same |
| prose | `--md-link` | derived | `var(--md-accent)` | same |
| prose | `--md-alert-note` | none | `#0969da` | `#4493f8` |
| prose | `--md-alert-tip` | none | `#1a7f37` | `#3fb950` |
| prose | `--md-alert-important` | none | `#8250df` | `#ab7df8` |
| prose | `--md-alert-warning` | none | `#9a6700` | `#d29922` |
| prose | `--md-alert-caution` | `--destructive` | `#cf222e` | `#fa5e55` |
| code | `--md-code-background` | derived | `var(--md-muted)` | same |
| code | `--md-code-foreground` | derived | `var(--md-foreground)` | same |
| code | `--md-code-comment` | derived | `var(--md-muted-foreground)` | same |
| code | `--md-code-keyword` | none | `#cf222e` | `#ff7b72` |
| code | `--md-code-string` | none | `#0a3069` | `#a5d6ff` |
| code | `--md-code-constant` | none | `#0550ae` | `#79c0ff` |
| code | `--md-code-function` | none | `#8250df` | `#d2a8ff` |
| code | `--md-code-type` | none | `#953800` | `#ffa657` |
| code | `--md-code-punctuation` | derived | `var(--md-muted-foreground)` | same |
| code | `--md-code-inserted` | none | `#1a7f37` | `#3fb950` |
| code | `--md-code-deleted` | none | `#cf222e` | `#fa5e55` |
| editor | `--md-editor-background` | derived | `var(--md-background)` | same |
| editor | `--md-editor-foreground` | derived | `var(--md-foreground)` | same |
| editor | `--md-editor-marker` | derived | `var(--md-muted-foreground)` | same |
| editor | `--md-editor-selection` | derived | `color-mix(in oklab, var(--md-accent) 20%, transparent)` | same |
| editor | `--md-editor-cursor` | derived | `var(--md-foreground)` | same |
| editor | `--md-editor-active-line` | derived | `color-mix(in oklab, var(--md-muted) 50%, transparent)` | same |
| editor | `--md-editor-toolbar` | derived | `var(--md-background)` | same |
| editor | `--md-suggestion-insert` | derived | `color-mix(in oklab, var(--md-code-inserted) 18%, transparent)` | same |
| editor | `--md-suggestion-delete` | derived | `color-mix(in oklab, var(--md-code-deleted) 18%, transparent)` | same |
| math | `--md-math-size` | none | `1.21em` (KaTeX's own default) | same |

The code and alert hues start from GitHub's Primer palette (github-markdown-css and GitHub alerts), because readers know
it from READMEs; the dark caution and deleted hues are lightened (`#fa5e55` instead of Primer's `#f85149`) so they keep
4.5:1 on `--md-code-background`. `--md-editor-marker` is the dimmed colour of markdown syntax in Source mode (the "markers
dimmed" Source view the benchmark recommends); it dims by using the muted text colour rather than transparency, so markers
keep the 4.5:1 of THEME-03. `--md-border` is decorative (table rules, separators), so THEME-03's 3:1 for meaningful
borders applies to `--md-ring`, which also draws the editor's outline (1px at rest, 2px when focused), not to it.
`--md-suggestion-*` are the only tokens the AGENT review UI needs from this area. The prose sizes follow Tailwind
Typography's base scale (leading 1.75, measure 65ch), a starting point to tune with real articles.

- **THEME-03** (MUST) The default light and dark token values meet WCAG 2.2 AA contrast (4.5:1 for text, 3:1 for the
  focus ring and for borders that carry meaning) for every foreground and background pair the gem draws. Acceptance: a
  contrast check over the token pairs runs in the gem's CI and fails below the thresholds.
- **THEME-04** (MUST) The token list is a documented public API: every token has a one-line description, its fallback
  and its defaults in the gem's theming guide, and renaming or removing a token follows THEME-15. Acceptance: a test
  compares the public tokens the stylesheet reads in its resolution blocks with the documented table and fails on any
  difference.
- **THEME-05** (SHOULD) A Tailwind v4 app can use the tokens as utilities (`bg-md-code-background`, `text-md-accent`)
  inside the viewer and the editor through an optional `@theme inline` file the gem ships, which maps each utility to the
  private name with the public one as fallback (`--color-md-accent: var(--_md-accent, var(--md-accent))`), the way chadcn
  maps the shadcn variables. Acceptance: in the Tailwind dummy app, an element with `text-md-accent` inside a viewer
  computes to the default accent, and to the app's value when the app sets `--md-accent`.

### Cascade and modes

- **THEME-06** (MUST) All gem CSS sits inside a cascade layer and uses `:where()` selectors, with a documented Tailwind
  entry (`@import "md.css" layer(components);`) and a plain-CSS entry (the file declares `@layer md.vendor, md.base`);
  third-party stylesheets the gem ships (KaTeX) are imported into `md.vendor` so the gem's token rules in `md.base` beat
  them, and CodeMirror is styled only through `EditorView.theme`; so unlayered app rules and Tailwind utilities override
  gem rules without `!important`. Acceptance: in the Tailwind and the plain-CSS dummy apps a system test checks that an app
  rule `.md-prose h2 { color: red }` and a utility class on the wrapper both win, that Preflight does not reset the gem's
  heading and paragraph margins, and that `--md-math-size: 1.5em` on the wrapper changes the computed `.katex` font size.
- **THEME-07** (MUST) Dark mode turns on when an ancestor has the `.dark` class or `data-theme="dark"`, and follows
  `prefers-color-scheme` only when the app opts in with `color_scheme: :auto` (rendered as `data-md-color-scheme="auto"`),
  so an app without a dark mode never gets a dark editor by accident. Acceptance: system tests for the class, the
  attribute, the opt-in media query (emulated) and the default (light under a dark OS setting) each check the
  editor's computed background colour (the resolved `--_md-background`).
- **THEME-08** (SHOULD) Scoping works below the document root: tokens or `.dark` set on one wrapper restyle only the
  viewers and editors inside it, derived tokens included, so an admin page can show a dark editor next to a light
  preview. Acceptance: a system test renders two editors whose wrappers set different `--md-accent` values and `.dark` on
  only one, and checks each one's computed link colour (derived from `--md-accent`) and background.

### Per-surface theming

- **THEME-09** (MUST) The CodeMirror theme and highlight style are generated from the tokens: `EditorView.theme` values
  and `HighlightStyle` tag styles are `var(--_md-…)` references to the private names THEME-02 resolves on the editor
  root, so a token change or a `.dark` toggle restyles a live editor without reconfiguring it. Acceptance: a system test
  toggles `.dark` on the page and checks that the editor background and a keyword token change colour with no JavaScript
  call.
- **THEME-10** (MUST) The server highlighter (commonmarker with `theme: ""`) emits classes, and the gem's code stylesheet
  maps them to the 11 code tokens (read as their resolved `--_md-code-*` names) with the same tag groups as the editor's
  highlight style, so a code block looks the same in the editor, the preview and the published page. Acceptance: a
  fixture with Ruby, JavaScript and a diff block renders keyword, string and comment spans whose computed colours equal
  the editor's for the same token kinds.
- **THEME-11** (SHOULD) The Mermaid controller reads the resolved private `--_md-*` values on the diagram's root and
  converts them to opaque hex (converting `oklch()` and `color-mix()` results and compositing any alpha over
  `--_md-background`, since shadcn's dark `--border` is `oklch(1 0 0 / 10%)`), initializes Mermaid with the `base` theme
  and `themeVariables` `primaryColor` from `--_md-muted`, `primaryTextColor` from `--_md-foreground`, `primaryBorderColor`
  from `--_md-border`, `lineColor` from `--_md-muted-foreground`, `background` from `--_md-background`, `fontFamily` from
  `--_md-font-sans` and `darkMode` from the active scheme, and renders diagrams again when the colour scheme changes;
  KaTeX math uses `--_md-math-size` and maps `errorColor` to `--_md-alert-caution`. Acceptance: a system test renders a
  flowchart under the light and the dark tokens and checks that the node fill equals the hex of the resolved
  `--_md-muted` and the node border is an opaque hex, and a KaTeX error renders in the caution colour.

### Presets and eject

- **THEME-12** (SHOULD) The gem ships a small set of presets: `default` (neutral, follows shadcn variables when present),
  `github` (Primer-like prose and code) and `serif` (long-form reading: serif body, wider leading), each with light and
  dark values. A preset is a set of resolution blocks keyed by `data-md-theme` on the gem roots that replaces the defaults
  at the end of each private chain, so it never declares a public token and app tokens still win; it is selected with one
  setting (`Md.configure { _1.theme = :github }`) or a `theme:` field option. Acceptance: switching the preset in the
  dummy app changes the resolved `--_md-*` values with no other change, an app-set `--md-accent` still wins under every
  preset, and every preset passes the contrast check of THEME-03.
- **THEME-13** (MUST) `bin/rails generate md:theme` writes the active preset's values into the app as a commented file of
  public `--md-*` declarations (light and dark blocks) and prints the line that imports it; `--full` also copies the
  complete stylesheet for apps that want full control. Acceptance: in a new Rails app the generated token file, imported
  unchanged, renders identically to the gem default (computed-style test), and running the generator twice changes
  nothing.
- **THEME-14** (MUST) Ejected files carry a header with the gem version they came from; every token an ejected
  file omits still resolves to the gem's default at the end of its chain, so tokens added later still have values; and
  `bin/rails md:theme:check` reports tokens missing from or unknown to an ejected token file. Acceptance: after ejecting
  with one version and upgrading the dummy app to a version that adds a token, the check task lists the new token and
  exits 0, and a renamed token makes it exit 1 and name the replacement.
- **THEME-15** (MUST) A token is renamed only in a minor release that keeps reading the old public name as a fallback in
  the private chain (`--_md-new: var(--md-new, var(--md-old, #ffffff))`) with a CHANGELOG entry, and removed only with a
  CHANGELOG entry; the old name is dropped no earlier than the next minor release. Acceptance: the token-documentation
  test of THEME-04 also lists old names and fails if one disappears in the release that introduced the rename, and a
  system test that sets only the old name sees its value.

### Toolbar, icons, strings and per-field options

- **THEME-16** (MUST) The toolbar is configured as an ordered list of item names with group separators (for example
  `%i[heading bold italic | link image | bulleted_list numbered_list task_list | code quote table]`), set globally in
  `Md.configure`, in a named preset and per field, with the field winning over the preset and the preset over the global
  default; `toolbar: false` hides it. Acceptance: a component test renders a field with a custom list and checks the
  buttons' order and separators, and another checks the field, preset and global precedence.
- **THEME-17** (MUST) Toolbar icons are inline SVG drawn with `currentColor`, from a permissively licensed set credited
  in the gem (for example Lucide, ISC licence), and an app replaces any icon through a resolver
  (`Md.configure { _1.icons = ->(name) { … } }`) or by giving an icon per toolbar item. Acceptance: with a resolver that
  returns a custom SVG for `:bold`, the rendered button contains that SVG, and with no resolver every default item renders
  an icon whose colour follows the text colour.
- **THEME-18** (MUST) Every user-facing string of the viewer and the editor (button labels, tooltips, mode names, upload
  and alt-text prompts, error and busy messages, Mermaid and math error text) comes from the gem's `config/locales` in
  English and Spanish under the `md.` namespace, is rendered server-side into the markup the JavaScript reads, and is
  overridable from the app's own locale files; a key is renamed only with the old key still read as a fallback for one
  minor release and a CHANGELOG entry. Acceptance: a locale-parity check finds no key missing between `en` and `es`, a
  system test that renders the editor under the `es` locale shows Spanish labels, and an app-level key replaces one
  label, also under its previous name for a renamed key.
- **THEME-19** (SHOULD) Per-field options cover look and behaviour without CSS: `placeholder`, `toolbar`, `modes`,
  `min_height` and `max_height`, `theme` (a preset name), `color_scheme`, and `class` and `data` passed through to the
  wrapper; every option also has a global default in `Md.configure` and a named-preset form. Acceptance: a table-driven
  test renders one field per option and checks the resulting attribute or computed style, and the README lists every
  option with its default.
- **THEME-20** (COULD) The heading levels offered by the toolbar and the `/` menu are configurable
  (`headings: %i[h2 h3 h4]`, Lexxy's default), so an app whose page title is the only `h1` cannot get a second one.
  Acceptance: with `headings: %i[h2 h3]` the heading control offers exactly two levels.

### Full eject

- **THEME-21** (SHOULD) For a full eject (`--full`), `bin/rails md:theme:check` also lists the selectors added, removed
  or changed since the stamped version, read from a selector manifest the gem ships with each release. Acceptance: after a
  full eject with one version and an upgrade that changes one selector, the check task names that selector and exits 0.

## Developer experience notes

What each requirement costs a newcomer, and how the design keeps that cost low:

- **Nothing to learn for the default.** THEME-02 and THEME-07 give a chadcn or shadcn app and an app with no theme a
  correct look with no configuration: one stylesheet line (its delivery belongs to ASSETS) and nothing else.
- **Twelve names restyle the surfaces, text, accent and fonts.** The base group is the whole mental model; code and
  alert hues keep their Primer defaults unless set, and the other 33 tokens sit in one documented table (THEME-04). A
  developer who knows shadcn already knows 7 of the 12 names (`background`, `foreground`, `muted`, `muted-foreground`,
  `border`, `ring`, `radius`); `--md-accent` and `--md-accent-foreground` read shadcn's `--primary` pair, not its
  `--accent` pair (see Open decisions).
- **No new CSS concepts for plain-CSS apps.** THEME-06 means "write normal CSS and it wins"; the developer never sees
  `@layer`. Tailwind apps write one import line with `layer(components)`, documented with the reason (Preflight and
  utilities), because getting it wrong gives confusing results; the install generator (DX) should write that line.
- **One surface for code colours.** THEME-09 and THEME-10 remove the usual second step of picking a highlight.js or Rouge
  theme that clashes with the editor.
- **Dark mode by media query is opt-in.** THEME-07 costs one option for apps that want automatic dark mode; in exchange
  no app ships a surprise dark editor.
- **Eject is a short file, not a fork.** THEME-13's default copies about a hundred lines of variables (light and dark
  blocks). `--full` is the escape hatch, and THEME-21's selector report is the price of that freedom, paid at upgrade time.
- **Configuration surface.** THEME-16, THEME-17, THEME-19 and THEME-20 add options to `Md.configure` and to the field
  helper. Each has a default, so the quick start needs none of them, and the precedence rule (global, then preset, then
  field) is the one thing to learn, the same as Lexxy's.
- **Presets.** THEME-12 adds one setting (`theme`) and one field option, both defaulting to `default`; a newcomer never
  sees them, and each extra preset is a contract the maintainer keeps across releases (hence the 0.1 recommendation below).
- **Locale keys are public API.** THEME-18 makes every `md.*` key something an app may override, so renaming a key would
  silently drop the app's translation; THEME-18 therefore keeps the old key as a fallback for one minor release, like the
  token renames of THEME-15.
- **Error messages.** THEME-14's check task names the replacement token on a rename, and THEME-13's generator prints the
  import line to add. Both turn an upgrade problem into a copy-paste fix.
- **Optional extras.** THEME-05's Tailwind utilities are one file only Tailwind apps import, and they resolve inside the
  gem's roots (outside them only when the app sets the public token). THEME-11's Mermaid bridge adds no API, but it is
  real code (colour conversion, re-render on a scheme change) the gem maintains.

## Open decisions

- Token prefix: keep the placeholder `--md-` or derive it from the final gem name. Recommendation: derive it from the
  gem name at the naming decision and keep it to two to five letters, because it appears in every override an app writes.
- Should the base tokens fall back to the shadcn variable names by default, or only when the app picks a `shadcn` preset?
  Recommendation: by default. It is the zero-configuration path for chadcn and shadcn apps (Papyro first), and
  `var(--background, #ffffff)` costs nothing in apps that do not define `--background`. The risk is an app that uses
  `--background` for something else; the theming guide documents the one-line opt-out (set `--md-background`).
- Which presets ship in 0.1? Recommendation: `default` only, with `github` and `serif` in a later 0.x release once the
  token list has met a second app; every preset is a contract to keep, and THEME-12 is a SHOULD.
- Dark-mode default: opt-in `prefers-color-scheme` as THEME-07 proposes, or automatic like github-markdown-css.
  Recommendation: opt-in, because most Rails apps have no dark mode and an automatic dark editor inside a light app is the
  worse failure.
- Icon set: a Lucide subset (matching shadcn and chadcn) or a small set drawn for the gem. Recommendation: a Lucide
  subset, credited in the gem, because chadcn apps already use it and the licence is permissive.
- Code palette: fixed Primer-derived hues (the draft above) or hues derived from `--md-accent` with `color-mix`.
  Recommendation: fixed hues, because derived hues collapse into one colour family and weaken the distinction between
  token kinds; revisit if THEME-03's contrast check fails.
- Accent token name: `--md-accent` (reads shadcn `--primary`) or `--md-primary`. Recommendation: `--md-primary` and
  `--md-primary-foreground`, because shadcn's `--accent` is a subtle hover surface and a shadcn developer would guess
  wrong; with the rename, 9 of the 12 base names match shadcn exactly. Decide before 0.1, since THEME-15 makes a later
  rename cost an alias cycle.

## Sources

- https://ui.shadcn.com/docs/theming (accessed 2026-11-03)
- https://github.com/tailwindlabs/tailwindcss-typography (accessed 2026-11-03)
- https://github.com/sindresorhus/github-markdown-css (accessed 2026-11-03)
- https://raw.githubusercontent.com/sindresorhus/github-markdown-css/main/github-markdown.css (accessed 2026-11-03)
- https://picocss.com/docs/css-variables (accessed 2026-11-03)
- https://lexxy.dev/docs/css-setup.html (accessed 2026-11-03)
- https://lexxy.dev/docs/configuration.html (accessed 2026-11-03)
- https://raw.githubusercontent.com/basecamp/lexxy/main/app/assets/stylesheets/lexxy-variables.css (accessed 2026-11-03)
- https://unpkg.com/trix@2.1.15/dist/trix.css (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith (accessed 2026-11-03)
- https://developer.mozilla.org/en-US/docs/Web/CSS/@layer (accessed 2026-11-03)
- https://tailwindcss.com/docs/adding-custom-styles (accessed 2026-11-03)
- https://unpkg.com/tailwindcss@4.1.11/index.css (accessed 2026-11-03)
- https://codemirror.net/examples/styling/ (accessed 2026-11-03)
- https://lezer.codemirror.net/docs/ref/#highlight.classHighlighter (accessed 2026-11-03)
- https://github.com/gjtorikian/commonmarker (accessed 2026-11-03)
- https://shiki.style/guide/theme-colors (accessed 2026-11-03)
- https://mermaid.js.org/config/theming.html (accessed 2026-11-03)
- https://mermaid.js.org/config/schema-docs/config.html (accessed 2026-11-03)
- https://katex.org/docs/options (accessed 2026-11-03)
- https://katex.org/docs/font (accessed 2026-11-03)
- https://guides.rubyonrails.org/i18n.html (accessed 2026-11-03)
- https://lucide.dev/license (accessed 2026-11-03)
- `../reports/Markdown editor benchmark.md` (sections "What the gem provides" and "commonmarker 2.x and a pinned
  GitHub-compatible dialect")
- `../research_notes/Markdown editor benchmark/editor_libraries.md` (Marksmith and Lexxy entries)
- Papyro `app/assets/tailwind/domains/articles/reader.css` and `app/assets/tailwind/theme/theme.css`; chadcn
  `app/assets/tailwind/chadcn/tokens.css`
