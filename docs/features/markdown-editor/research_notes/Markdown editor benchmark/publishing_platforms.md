# Publishing/blogging platform editors and editorial workflow (benchmark for Papyro Studio)

Scope: authoring experience on Papyro's closest competitors (Ghost, Substack, Medium, WordPress Gutenberg, Dev.to/Forem, Hashnode, Bear Blog, Write.as/WriteFreely, Mataroa, Micro.blog, Writebook, GitBook, Mintlify, Docusaurus, Hugo + Decap/TinaCMS). Research date: 2026-11-03. Many community sources are older (2018-2024); staleness is flagged inline. Papyro context: Rails 8.1, markdown storage, EN/ES translations, autosave, image uploads, server-rendered preview tab.

## 1. Editor model and storage format per platform (and portability consequences)

### Takeaway
The market splits three ways. (a) Block/WYSIWYG editors that store structured JSON: Ghost (Lexical), Substack (TipTap/ProseMirror), Gutenberg (block-delimited HTML), GitBook. (b) Markdown-source editors that store markdown: Dev.to, Bear Blog, WriteFreely, Mataroa, Micro.blog, Writebook. (c) Hybrid "visual + source" editors over markdown/MDX files in Git: Mintlify, TinaCMS, Hashnode's mixed mode. Markdown-in-a-textarea editors are the most portable but the poorest at rich elements. Block editors make cards first-class, at the cost of proprietary JSON and lossy export. The best-in-class trend for docs is "visual mode + source mode over the same markdown file".

### Cited Findings
**Ghost**
- Ghost's third-generation editor was "completely rebuilt from the ground up on top of Lexical"; the previous one was built on Mobiledoc. Ghost said Mobiledoc "never became widely adopted, so the technology underpinning our editor became a bit stagnant" — [Ghost changelog: new editor](https://ghost.org/changelog/new-editor/)
- The Lexical editor became the default on 2023-10-04 (commit "Released new editor (#18422)"). Mobiledoc posts stay Mobiledoc until opened in the editor, then are converted to Lexical on the fly — [Ghost forum / commit summary](https://forum.ghost.org/t/dev-team-question-whats-the-future-of-mobiledoc/39277); [Is Mobiledoc removed](https://forum.ghost.org/t/is-mobiledoc-removed-from-ghost/41949)
- The Admin API stores and returns a `lexical` field ("a standardised JSON-based representation of your content, which can be rendered in multiple formats"). HTML is returned only when requested via `formats=html,lexical` — [Ghost Admin API: Posts](https://docs.ghost.org/admin-api/posts/overview)
- Developers reported `mobiledoc` always null via the API from Ghost 5.69, and the docs lagged the change — [Ghost forum: Admin API mobiledoc vs lexical](https://forum.ghost.org/t/admin-api-mobiledoc-vs-lexical/57844)
- Koenig was designed to use markdown syntax as *shortcuts* for editor actions, not as the storage or source format. The original markdown-only editor survives as a "Markdown card" inside Koenig — [Ghost forum: Koenig beta announcement](https://forum.ghost.org/t/koenig-editor-beta-release/1284)
- Markdown typed directly into the editor is parsed automatically; a Markdown card can hold a full post or section, including footnotes — [Ghost help: cards](https://ghost.org/help/cards)

**Substack**
- Rich text editor based on TipTap/ProseMirror. It covers headings, bold, italic, strikethrough, sub/superscript, alignment, horizontal rules and lists — [Substack features](https://substack.com/features)
- Whether Substack supports markdown input is contested in weak secondary sources (one says no, another from the same site says yes) — [substackcourse.com: Substack markdown](https://substackcourse.com/substack-markdown/)
- Lock-in criticism centres on audience portability (only subscribers export, not followers) rather than content format — [werd.io](https://werd.io/to-maintain-their-independence-publishers-are-fleeing-substack/); [HN thread](https://news.ycombinator.com/item?id=33613373)

**Medium**
- WYSIWYG with no full markdown support. Reviewers say it "can feel frustrating" for people used to markdown, and markdown imported via "Import a story" ends up badly formatted — [DEV: Medium, is it worth your time](https://dev.to/dag7dev/medium-is-it-worth-your-time-and-effort-1njm)

**WordPress Gutenberg**
- Block editor. Pasting markdown converts it into blocks, but the editor does not fully support writing in markdown. Plugins (EditorsKit, Averroes) add inline markdown or a markdown editor that round-trips blocks — [WP Tavern: EditorsKit](https://wptavern.com/editorskit-1-6-and-1-7-add-tools-for-writers-drag-and-drop-block-export-import); [Averroes](https://github.com/youknowriad/averroes)
- Typing `/` in a new block opens the block inserter — [mkaz.blog: Gutenberg can do that](https://mkaz.blog/wordpress/gutenberg-can-do-that/)

**Dev.to / Forem (Rails)**
- Markdown editor with Jekyll-style front matter (`title`, `published`, `description`, `tags` (max 4), `canonical_url`, `cover_image`, `series`). Inline HTML generally works. There is an alternative "rich + markdown" mode where title and tags are separate fields — [DEV editor guide](https://dev.to/p/editor_guide)
- Liquid tags are "compiled" when an article is saved, so an article must be re-saved to pick up HTML changes. Tags are Ruby classes in `app/liquid_tags` inheriting from `LiquidTagBase`, with `VALID_ROLES` and `VALID_CONTEXTS` restrictions — [Forem docs: liquid tags](https://developers.forem.com/frontend/liquid-tags)

**Hashnode**
- Markdown plus block-based editor (internally "Neptune"). Slash commands insert blocks, and "most markdown syntax" is supported. The slash menu is unavailable on mobile — [Hashnode docs: editor basics](https://docs.hashnode.com/blogs/editor/editor-basics-and-commands); [Hashnode support: Neptune editor](https://support.hashnode.com/en/articles/6780453-neptune-editor-basics-and-commands)
- An older freeCodeCamp guide says the editor does not support all markdown, and that links and images did not work in markdown (possibly stale) — [freeCodeCamp Hashnode guide](https://www.freecodecamp.org/news/freecodecamp-hashnode-publication-guide/)

**Minimal markdown blogs**
- Bear Blog: the body is a plain `<textarea>` of markdown, with a separate header block for attributes (title, slug, date). It is rendered with Mistune plus extensions. The community has built toolbar and editor replacements (including a Quill-based one with autosave), which signals demand for more than a bare textarea — [fischr: Markdown power-editor for Bear](https://fischr.bearblog.dev/markdown-power-editor-for-bear-blog/); [bearblog-plugins](https://github.com/flschr/bearblog-plugins); [Kami: replace editor with Quill](https://kami.bearblog.dev/how-to-replace-the-default-editor-with-quill/)
- Mataroa: plain text and markdown with images. It imports multiple text or markdown files as drafts and exports to markdown, epub and static-site-generator formats, which is broader export than Bear — [imperfect.bearblog.dev: Mataroa vs Bear](https://imperfect.bearblog.dev/mataroa-versus-bear/)
- WriteFreely (Write.as engine): minimal, auto-saving markdown editor; HTML also works — [WriteFreely features](https://writefreely.org/features/)
- Micro.blog: markdown web editor with a Preview button (added 2018), later extended to render tables and footnotes "to more closely match" the published blog. The Mac app has a floating preview window, and iOS 3.0 added markdown syntax highlighting — [manton.org 2018](https://www.manton.org/2018/10/02/markdown-preview-and.html); [manton.org 2020](https://www.manton.org/2020/07/28/web-posting-markdown.html); [manton.org 2022](https://www.manton.org/2022/01/10/microblog-for-macos.html)

**Writebook (37signals, Rails)**
- 37signals built a custom markdown editor called "House" (not Trix), plus an `ActionText::Markdown` extension. At the time only the minified `vendor/javascript/house.min.js` shipped, and 37signals said they wanted to "use it in anger" before releasing it standalone — [Rails discuss: upstreaming Writebook editor](https://discuss.rubyonrails.org/t/upstreaming-writebook-text-editor-to-rails/86134)
- The toolbar buttons wrap the selected text in markdown characters (word-processor-style toolbar over markdown source) — [Writebook manual: Using Markdown](https://books.37signals.com/2/the-writebook-manual/24/url)

**Docs platforms / Git-backed CMS**
- GitBook: block-based editor with markdown support and WYSIWYG tools. Two-way Git Sync with GitHub/GitLab, where GitBook edits become commits and commits show up in GitBook. As of June 2026 the API can update page content in a change request using Markdown or GitBook's document format — [GitBook Git Sync](https://gitbook.com/docs/integrations/git-sync); [GitBook changelog](https://gitbook.com/docs/changelog/readme.md); [GitBook glossary](https://gitbook.com/docs/resources/glossary.md)
- Mintlify web editor: "Visual mode" (real-time preview of the published output) and "Source mode" (direct MDX and frontmatter). It handles Git automatically through a GitHub App or GitLab integration, and commits are signed by the Mintlify app unless the user authorises their own account — [Mintlify editor docs](https://www.mintlify.com/Mintlify/docs/editor); [Mintlify drafts](https://index.mintlify.com/docs/editor/drafts)
- TinaCMS: stores Markdown, MDX or JSON in the repo, and visual-editor edits become commits. Click-on-page visual editing requires instrumenting the frontend with the `useTina` hook and React components; Astro support is experimental — [Lucky Media: TinaCMS vs Decap](https://www.luckymedia.dev/compare/tina-cms-vs-decap-cms); [Lucky Media: Tina CMS](https://www.luckymedia.dev/insights/tina-cms)
- Decap CMS: form/markdown editor with a preview pane that, out of the box, shows raw field values rather than a rendered page, and has no in-context visual editing — [Lucky Media: TinaCMS vs Decap](https://www.luckymedia.dev/compare/tina-cms-vs-decap-cms)

### Inferences
- Papyro's choice of markdown storage puts it in the portability camp (Dev.to, Bear, Mataroa, Writebook), which avoids Ghost's two format migrations (Mobiledoc to Lexical, with lazy conversion on open). The price is that rich elements (callouts, CTAs, embeds, galleries) need a markdown extension syntax, comparable to Dev.to Liquid tags or MDX components, rather than native cards.
- Writebook is the closest architectural analogue: Rails, markdown stored server-side, a toolbar that inserts markdown syntax instead of a WYSIWYG model. Mintlify's visual/source dual mode over one MDX file is the best-in-class hybrid pattern if Papyro ever wants WYSIWYG without giving up markdown storage.
- Dev.to's "compile on save" Liquid approach shows the trade-off of render-time extensions. Cached HTML goes stale when a tag implementation changes, so re-rendering or versioning the renderer is needed.

### Gaps
- Substack's export format (HTML archive?) and whether markdown input/paste is officially supported: no official help-center source found.
- Medium's internal storage format and export format: not found in this pass.
- Docusaurus authoring (pure MDX in an IDE, no hosted editor) and Hugo + Decap specifics: not researched in depth; no sources fetched.
- Whether 37signals released House as a standalone open-source editor (it was announced as "soon" in 2024): unverified.
- Write.as hosted vs WriteFreely differences: not researched.

## 2. Embeds and rich elements (images, video/social, code, callouts, CTAs, footnotes, tables, dividers, bookmarks, paywall)

### Takeaway
Ghost and Substack set the bar for long-form and newsletter writing. Both have native image (caption plus alt), gallery, embed via URL paste, callout, button/CTA, divider, and paywall/preview break; Ghost adds bookmark cards, toggles, headers, product, file and audio cards, and per-card web/email/member visibility. Markdown-first platforms reach parity through extension syntax (Dev.to Liquid tags, Ghost's Markdown card, MDX components). Tables remain a weak spot across the WYSIWYG newsletter tools, as do footnotes on mobile.

### Cited Findings
**Ghost card catalogue** (from [Ghost help: cards](https://ghost.org/help/cards)):
- Image (upload, paste, drag or URL; caption plus alt text), Gallery (up to 9 reorderable images), Markdown, HTML, Divider (`---` shortcut), Bookmark (paste a URL as the first thing in an empty paragraph, or `/bookmark {url}`), Email content (newsletter-only), Call to action (image, optional sponsor label, button; shown in web, email or both, targeted to public, free or paid), Public preview (paywall break), Button, Callout (emoji plus background colour), GIF search, Toggle (collapsible), Audio, Video (loop, thumbnail, width), File, Product, Header, Embeds (YouTube, Spotify, SoundCloud via URL paste), Signup form.
- Insertion: type `/` on an empty line or click `+`. The HTML card can be restricted to public, free-member or paid-member audiences.
- An older forum thread had users asking for footnote shortcuts in Koenig (footnotes worked only in the Markdown card) — [Ghost forum: footnote shortcut](https://forum.ghost.org/t/ghost-markdown-shortcut-for-footnote/14160/8.md)

**Substack** ([Substack features](https://substack.com/features)):
- Code blocks with syntax highlighting, inline and block LaTeX, footnotes, pull quotes, callouts, images with caption and alt text, galleries, Unsplash search, native audio/video, oEmbed (YouTube, Spotify, X, Bluesky, Datawrapper, Polymarket), Substack post embeds, recipe blocks with schema.org markup, polls, survey buttons, CTA buttons, and a paywall break anywhere in a post.
- Tables: sources conflict. One 2026 review says tables were "finally added in 2024", while writer guides say there is no native table block and recommend Datawrapper embeds or screenshots. Long tables reportedly need a web browser or email to view — [schoolmaker Substack review 2026](https://schoolmaker.com/blog/substack-review); [reallygoodbusinessideas: tables on Substack](https://www.reallygoodbusinessideas.com/p/how-to-add-tables-to-substack); [automato](https://automato.substack.com/p/how-to-add-powerful-tables-and-graphs)
- Mobile-browser footnote popups reportedly overflow the screen, and footnotes imported from WordPress lose their target — [Substack note](https://substack.com/@barsoom/note/c-70815836); [edintone: importing WordPress](https://edintone.substack.com/p/should-it-be-easy-to-import-wordpress)
- No underline for emphasis, and weak handling of tables and fonts — [grahamseibert](https://grahamseibert.substack.com/p/about-editing-and-navigating-in-substack)

**Medium**
- Tables are weak or unsupported for complex data. Third-party publishing tools list Medium as a channel where tables, columns and inline images are unsupported — [StoryChief help](https://help.storychief.io/en/articles/2304043-can-i-add-tables-columns-and-inline-images-in-a-story); [Level Up: tables on Medium](https://levelup.gitconnected.com/3-tips-to-sharing-beautiful-tables-on-medium-post-25dab18670e)

**WordPress**
- WP 6.3 (Aug 2023) added a native Footnotes feature. You select text and choose More > Footnote, the Footnotes block auto-links and formats the notes, and the notes are stored as post meta and tracked in revisions — [Make WP Test: 6.3](https://make.wordpress.org/test/2023/06/27/help-test-wordpress-6-3/); [core changeset footnotes.php](https://core.trac.wordpress.org/changeset/56305/branches/6.3/src/wp-includes/blocks/footnotes.php)

**Dev.to Liquid tags** ([DEV editor guide](https://dev.to/p/editor_guide); [Forem liquid tags](https://developers.forem.com/frontend/liquid-tags)):
- Universal `{% embed URL %}` (YouTube, GitHub, X, CodePen, Spotify, Vimeo…), platform tags (`link`, `user`, `tag`, `comment`, `podcast`, `organization`), non-URL tags `{% card %}`, `{% cta link %}`, `{% details %}` / `{% spoiler %}` / `{% collapsible %}`, and `{% katex %}` (with an `inline` option). The full list has about 28 tags, including `github`, `codepen`, `stackblitz`, `codesandbox`, `replit`, `twitch` and `wikipedia`.
- Captions require raw HTML `<figcaption>`. An image between numbered list items must be indented or the numbering restarts. Hidden author notes are written as HTML comments.

**Hashnode**
- Slash commands surface the content blocks, and the product targets technical writing (code blocks, embeds) — [Hashnode docs: editor basics](https://docs.hashnode.com/blogs/editor/editor-basics-and-commands)

**Bear Blog**
- Mistune extensions cover strikethrough, superscript and similar syntax; richer elements rely on raw HTML or community plugins — [fischr](https://fischr.bearblog.dev/markdown-power-editor-for-bear-blog/)

### Inferences
- A minimal "card parity" set for an editorial app (beyond CommonMark): image with caption and required alt, gallery, URL-paste embed (oEmbed), callout, button/CTA, divider, footnotes, tables, bookmark/link card, code with highlighting. Paywall/preview break matters only if memberships exist. Papyro can express these as fenced or directive markdown extensions (e.g. `:::callout`, `{% embed %}`-style tags) rendered server-side, which keeps the preview tab accurate.
- "Paste a URL on an empty line to get an embed or bookmark" (Ghost) is the cheapest high-delight interaction to copy into a markdown editor: on paste, convert the URL to an embed directive.
- Footnotes and tables are recurring writer pain points on WYSIWYG newsletter tools, which is a concrete area where markdown storage gives Papyro an advantage.

### Gaps
- Ghost Lexical's native handling of tables (there was no table card in the card list found): unconfirmed.
- Medium's current embed and code-block feature set: not fetched from an official source.
- Per-platform image paste/drag behaviour on Dev.to (upload button returning markdown is confirmed; drag-drop is not).

## 3. Editorial workflow (drafts, autosave/conflicts, revisions/diff, scheduling, previews, SEO, collaboration, multi-author, translations, accessibility)

### Takeaway
Revision history with one-click restore is now standard (Ghost since Oct 2023, Substack, WordPress), but true visual diffing is rare outside docs tools: Mintlify offers a visual/text diff against published, and GitBook change requests act like pull requests. Shareable secret draft links (Dev.to), branch preview URLs (Mintlify) and real-theme preview are the preview baselines. Real-time co-editing is still unusual. Hashnode Enterprise has it; WordPress pulled it from 7.0 in May 2026, though it shipped block-level Notes (comments) in 6.9 and 7.0. Native multilingual content is absent from Ghost, Substack and Medium, which is a clear differentiator for Papyro.

### Cited Findings
**Drafts, autosave, conflicts**
- Ghost: since Oct 17 2023 the editor saves multiple versions in the background, shows who edited what and when, and restores any version in one click — [Ghost changelog: post history](https://ghost.org/changelog/post-history/)
- Ghost limitations reported by users: the history list does not include the current state, so "latest" cannot be restored. Older community reports say Ghost kept the last 10 revisions without a UI (restore was done via SQL). A 2024 commit added local, in-browser revisions (limit 5) as a data-loss guard — [Ghost forum: restore latest version](https://forum.ghost.org/t/restore-the-latest-version-in-history/51882); [stosberg: revert via SQL](https://mark.stosberg.com/reverting-to-previous-post-revision-in-ghost-using-the-cli/); [ark mirror commit](https://ark.sudovanilla.org/Infrastructure/ghost/commit/202fd7ebbd4afa7f49d06cd8c869eb0d95e2a344) (the commit details came via a search summary; treat them as indicative)
- Ghost Admin API exposes `updated_at`, but the overview page does not document conflict checking (from prior knowledge, Ghost requires `updated_at` on PUT for collision detection; this was not verified in this pass) — [Ghost Admin API: Posts](https://docs.ghost.org/admin-api/posts/overview)
- Substack: drafts with autosave, version history with restore, scheduling, republishing on a schedule, post templates for recurring formats — [Substack features](https://substack.com/features)
- Dev.to: autosave arrived with the "V2 editor" — [DEV changelog: upgraded editor](https://www.dev.to/devteam/changelog-upgraded-editor-45mk)
- WriteFreely: auto-saving editor — [WriteFreely features](https://writefreely.org/features/)
- WordPress still uses post locking: only one editor at a time — [DreamHost: WP 7.0](https://www.dreamhost.com/blog/wordpress-7-0/)

**Revisions and diffing**
- Mintlify: every changed file in the publish menu opens in a diff view against the published version, visual in visual mode and text in source mode — [Mintlify editor docs](https://www.mintlify.com/Mintlify/docs/editor)
- GitBook: change requests are "similar to pull requests"; when live edits are locked, every change needs a change request. Since July 2026 change requests open on the Changes tab (review mode) by default — [GitBook glossary](https://gitbook.com/docs/resources/glossary.md); [GitBook changelog](https://gitbook.com/docs/changelog/readme.md)
- WordPress 6.3 extended revisions to global styles (timestamps plus users), with revert rather than a clear side-by-side diff in the sources found; footnotes are tracked in post revisions — [Hostinger: WP 6.3](https://www.hostinger.com/blog/?p=5290); [Make WP Test](https://make.wordpress.org/test/2023/06/27/help-test-wordpress-6-3/)
- TinaCMS and Decap: content is versioned as Git commits, which makes it reviewable like code — [Lucky Media](https://www.luckymedia.dev/compare/tina-cms-vs-decap-cms)

**Previews and preview links**
- Dev.to: unpublished drafts and scheduled posts have shareable "public but secret" links for feedback; they don't appear in feeds or on the profile — [DEV editor guide](https://dev.to/p/editor_guide)
- Mintlify: each save to a feature branch builds a preview deployment at `organization-branch-name.mintlify.site`. Previews are public by default and can be restricted to org members — [Mintlify editor docs](https://www.mintlify.com/Mintlify/docs/editor)
- Micro.blog: the Preview button was improved to render tables and footnotes like the published blog (the parity principle) — [manton.org 2020](https://www.manton.org/2020/07/28/web-posting-markdown.html)
- Decap: the default preview shows raw field values, not the rendered theme, which is a common criticism — [Lucky Media](https://www.luckymedia.dev/compare/tina-cms-vs-decap-cms)
- TinaCMS: click-to-edit on the live page with a real-time sidebar preview; drafts, review states and branch previews sit in Tina Cloud's paid tier (reported as $49/month Team Plus and partly beta; may be stale) — [Lucky Media](https://www.luckymedia.dev/compare/tina-cms-vs-decap-cms)

**SEO panel**
- Ghost post fields: `meta_title`, `meta_description`, `og_image`, `og_title`, `og_description`, `twitter_image`, `twitter_title`, `twitter_description`, `canonical_url`, `custom_excerpt`, `codeinjection_head`/`codeinjection_foot`, `custom_template`, `visibility`, `newsletter`, `email_only`, `authors[]` plus `primary_author` — [Ghost Admin API: Posts](https://docs.ghost.org/admin-api/posts/overview)
- Substack: per-post SEO/social title, description and image; headline A/B testing; email send toggled per post — [Substack features](https://substack.com/features)
- Dev.to: front matter `description` (social cards), `canonical_url`, `cover_image` (1000×420 recommended), `series`, `tags` (max 4) — [DEV editor guide](https://dev.to/p/editor_guide)
- Ghost's 2026 changelog has "Optimize your site for AI search" (Jul 16 2026) and a new staff admin toolbar (Jun 18 2026); no editor-specific 2026 entries were visible on page 1 — [Ghost changelog](https://ghost.org/changelog/)

**Collaboration and multi-author**
- Substack: bylines and co-authors, guest writer invitations, team roles (admin, contributor, byline) — [Substack features](https://substack.com/features)
- Hashnode: real-time collaboration (Enterprise plan). Collaborators open a shared draft link or "Team Drafts" and see each other's cursors; inline commenting on drafts — [Hashnode docs: real-time collaboration](https://docs.hashnode.com/blogs/editor/real-time-collaboration); [Hashnode blogs product](https://hashnode.com/products/blogs)
- WordPress: Notes (block-level comments) arrived in 6.9. Real-time co-editing was removed from 7.0 on 2026-05-08 (Mullenweg was "not confident the current approach is robust enough"), and 7.0 shipped 2026-05-20 with Notes upgrades (email notifications, Suggestions mode). RTC may return in 7.1, expected around Dec 2026 — [DreamHost: WP 7.0 what got cut](https://www.dreamhost.com/blog/wordpress-7-0/); [365i](https://www.365i.co.uk/blog/2025/09/12/wordpress-7-0-release-date-features-guide-2025/) (third-party coverage; official release notes not fetched)
- Ghost: `authors` is an array (multi-author) with a `primary_author` — [Ghost Admin API](https://docs.ghost.org/admin-api/posts/overview)

**Translations / multilingual**
- Ghost has no native multi-language content. It translates only system text (emails, Portal, search, comments; 33+ languages), and Ghost Admin is not internationalised. Workarounds are multiple instances, custom routing with tags and theme work, or JS overlays (Weglot, Localize). A 2026 forum thread notes the roadmap doesn't mention translations — [Ghost docs: translation FAQ](https://docs.ghost.org/faq/translation); [Ghost forum: native multilingual](https://forum.ghost.org/t/native-multilingual-support/49539/2); [Ghost forum: automated translations](https://forum.ghost.org/t/automated-translations-service-for-multi-language-content/61363); [Ghost + Weglot](https://ghost.org/integrations/weglot)
- Substack: only publication-level language settings; no per-post translations found — [Substack features](https://substack.com/features)

**Accessibility**
- Dev.to's guide tells authors to replace the image placeholder text with real alt text, start sections at H2, and avoid H1 because the title is the H1 (guidance only; no enforced check found) — [DEV editor guide](https://dev.to/p/editor_guide)
- Ghost and Substack expose alt-text fields on images — [Ghost help: cards](https://ghost.org/help/cards); [Substack features](https://substack.com/features)

### Inferences
- Papyro's "articles in EN/ES with translations" is a real gap in the long-form competitor set (Ghost, Substack, Medium have no per-post translation workflow). Worth leaning into: side-by-side source/translation view, translation status per locale, "source changed since translation" flags, and per-locale slug and SEO fields.
- The table-stakes workflow for an editorial app: autosave plus server-side revisions with restore, scheduling, a preview that renders on the real theme (Micro.blog's parity lesson; Decap's raw-field preview is the anti-pattern), a shareable secret preview link (Dev.to), and an SEO panel modelled on Ghost's field set (meta title/description, OG/Twitter overrides, canonical, custom excerpt).
- Conflict handling is under-documented everywhere. Post locking (WordPress) or optimistic `updated_at` checks are the pragmatic choices for a Rails app without CRDTs. Ghost's addition of local browser revisions as a data-loss backstop suggests server autosave alone was not enough.
- Visual diff between revisions is a differentiator in docs tools (Mintlify, GitBook) but absent from Ghost and Substack. Because Papyro stores markdown, a text diff (and a rendered diff via the preview renderer) is cheap.
- No platform found enforces accessibility. A "missing alt text" pre-publish check would be above market baseline.

### Gaps
- Ghost scheduling UI details, device previews (desktop/mobile/email preview toggle) and preview-link sharing: not verified from official docs in this pass (Ghost is widely known to offer web/email/mobile preview, but this is unverified here).
- Reading time display per platform (Medium shows it on stories; Ghost themes show reading time): not sourced.
- Hashnode revision history for blog drafts: no documentation found ("versioning" is mentioned only for Hashnode's Docs product).
- WordPress Polylang/WPML and Hashnode multilingual workflows: not researched in this pass.
- Internal-linking assistance (link search/autocomplete in editor) per platform: not sourced. Dev.to's `{% link %}` tag is the only internal-link-card mechanism confirmed.
- Medium's draft-sharing, revision and scheduling features: not fetched.

## 4. What writers praise and complain about

### Takeaway
Complaints follow each model's weak side. Block/WYSIWYG tools frustrate markdown writers (Medium's lack of markdown, Substack tables and footnotes, early Koenig missing word count and IME issues). Markdown textareas frustrate people who want toolbars, autosave and rich embeds (the Bear Blog plugin ecosystem). Dev.to's Liquid tags are powerful but leak implementation details (compile-on-save, escaping `raw`, list-numbering gotchas).

### Cited Findings
- Ghost Koenig (2018 beta): users missed the word count of the old markdown editor (word count was added in 1.25.0). Chinese input failed, and one user went back to the markdown editor. Users asked for footnote shortcuts outside the Markdown card — [Ghost forum: Koenig beta](https://forum.ghost.org/t/koenig-editor-beta-release/1284); [Ghost forum: Replacing editor](https://forum.ghost.org/t/replacing-editor/2264.md); [Ghost forum: footnote shortcut](https://forum.ghost.org/t/ghost-markdown-shortcut-for-footnote/14160/8.md) (stale: 2018-2020)
- Ghost post history: a bug report says the current state is missing from history — [Ghost forum](https://forum.ghost.org/t/restore-the-latest-version-in-history/51882)
- Substack: no native table block (contested), footnote popups off-screen on mobile, no underline, weak fonts/tables, lossy WordPress import — [reallygoodbusinessideas](https://www.reallygoodbusinessideas.com/p/how-to-add-tables-to-substack); [Substack note](https://substack.com/@barsoom/note/c-70815836); [grahamseibert](https://grahamseibert.substack.com/p/about-editing-and-navigating-in-substack); [edintone](https://edintone.substack.com/p/should-it-be-easy-to-import-wordpress)
- Substack lock-in debate is about audience and network effects (follower export, archive SEO), not editor format — [werd.io](https://werd.io/to-maintain-their-independence-publishers-are-fleeing-substack/); [HN](https://news.ycombinator.com/item?id=33613373)
- Medium: frustrating for markdown users, and markdown import "always fails miserably with the formatting" — [DEV: Medium worth it?](https://dev.to/dag7dev/medium-is-it-worth-your-time-and-effort-1njm)
- Hashnode: incomplete markdown support in an older guide; slash menu missing on mobile — [freeCodeCamp](https://www.freecodecamp.org/news/freecodecamp-hashnode-publication-guide/); [Hashnode docs](https://docs.hashnode.com/blogs/editor/editor-basics-and-commands)
- Bear Blog: the minimalism is praised, but users built toolbars, power editors and autosave replacements for the bare textarea — [fischr](https://fischr.bearblog.dev/markdown-power-editor-for-bear-blog/); [Kami](https://kami.bearblog.dev/how-to-replace-the-default-editor-with-quill/)
- Mataroa praised for import/export breadth (markdown, epub, SSG); criticised for lacking tags and nav customisation — [imperfect.bearblog.dev](https://imperfect.bearblog.dev/mataroa-versus-bear/)
- Dev.to: Liquid tags need re-save to refresh, `raw` escaping is awkward, an image inside a list restarts the numbering, and captions need raw HTML — [Forem docs](https://developers.forem.com/frontend/liquid-tags); [DEV editor guide](https://dev.to/p/editor_guide)
- Decap: the raw-field preview is a top criticism versus Tina's on-page editing; Tina's visual editing needs developer instrumentation — [Lucky Media](https://www.luckymedia.dev/compare/tina-cms-vs-decap-cms)
- WordPress: the RTC removal from 7.0 shows how hard real-time co-editing is even for the largest CMS — [DreamHost](https://www.dreamhost.com/blog/wordpress-7-0/)

### Inferences
- For Papyro's markdown editor, the evidence suggests keeping markdown as the source of truth but adding: word count and reading time, a formatting toolbar that inserts syntax (Writebook style), IME-safe input (CodeMirror-class editors handle composition well), footnote and table helpers, and paste-URL-to-embed.
- Writers' strongest negative reactions come from lossy import/export and from preview not matching the published output. Both are avoidable with markdown storage plus the same server renderer for the preview and public pages.

### Gaps
- No high-signal HN or Reddit threads specifically on Ghost Lexical (post-2023) or Substack's editor were found; most evidence is forum posts and blogs, much of it pre-2024.
- No 2025-2026 user reviews of Writebook's House editor were found.

## 5. Best in class: long-form editorial vs technical docs

### Takeaway
Long-form and newsletter leaders (Ghost, Substack) win on rich cards, audience-aware content (web vs email, free vs paid), scheduling, SEO/social fields and one-click restore. Docs leaders (Mintlify, GitBook, Tina) win on Git-backed review: branches and change requests, visual and text diffs, per-branch preview URLs, and a visual/source dual mode over markdown or MDX. The ideal for Papyro, a markdown-stored editorial app, is a hybrid: long-form polish (cards via markdown directives, alt text, SEO panel, scheduling, secret preview links) with docs-style review (revision diff, translation status), which no single competitor combines with native multilingual content.

### Cited Findings
- Long-form: Ghost card set plus per-card audience targeting — [Ghost help: cards](https://ghost.org/help/cards); Substack drafts, version history, scheduling, templates, co-authors, SEO image and title, headline A/B tests — [Substack features](https://substack.com/features)
- Docs: Mintlify visual/source modes, branch previews and diff view — [Mintlify editor docs](https://www.mintlify.com/Mintlify/docs/editor); GitBook change requests (PR-like), two-way Git Sync, review-mode default (Jul 2026) — [GitBook changelog](https://gitbook.com/docs/changelog/readme.md); [GitBook Git Sync](https://gitbook.com/docs/integrations/git-sync)
- Developer blogging: Dev.to markdown plus front matter plus Liquid embeds plus secret draft links — [DEV editor guide](https://dev.to/p/editor_guide); Hashnode slash commands plus markdown, Enterprise real-time collaboration and inline comments — [Hashnode docs](https://docs.hashnode.com/blogs/editor/real-time-collaboration)
- Minimal: Bear, WriteFreely and Mataroa trade features for speed and portability — [WriteFreely](https://writefreely.org/features/); [Mataroa vs Bear](https://imperfect.bearblog.dev/mataroa-versus-bear/)

### Inferences
- Feature-priority sketch for Papyro Studio, ranked by competitor prevalence and writer pain:
  1. Preview parity: the same server renderer for the preview tab and the public site, including footnotes and tables (Micro.blog lesson).
  2. Server-side revision history with restore plus a text diff (Ghost/Substack parity; diff beats them).
  3. Autosave with conflict detection (optimistic `lock_version`/`updated_at`), optionally with a local backup.
  4. Image UX: paste, drag and upload with mandatory alt text and an optional caption, plus a pre-publish missing-alt check.
  5. Embed directives: URL paste becomes an embed or bookmark; callout, CTA button, divider, footnotes, tables.
  6. SEO panel (meta title/description, OG image, canonical, slug) per locale, plus reading time and word count.
  7. Scheduling and a shareable secret preview link.
  8. Translation workflow (per-locale status, stale-translation detection), which no long-form competitor has natively.
  9. Later: editorial comments (WordPress Notes-style, block or paragraph anchored) before real-time co-editing, which even WordPress deferred.

### Gaps
- Docusaurus authoring UX (IDE plus MDX, no hosted editor) and Hugo + Decap editorial workflow (Decap's optional "editorial workflow" with draft/in review/ready states on Git backends) were not verified from primary docs in this pass; one secondary source claims Decap lacks native workflow tooling, which conflicts with the researcher's prior knowledge.
- No quantitative data (usage share, satisfaction scores) per editor was found.
