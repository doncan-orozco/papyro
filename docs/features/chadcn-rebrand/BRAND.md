# chadcn brand guide

The one source the rebrand items of the `chadcn-rebrand` epic copy from (README, docs intros, demo catalog, doctor and
generator output). If a wording here and a wording in an item disagree, this file wins; change it here first.

> Status: proposal. The mascot and the tagline need a maintainer's sign-off at the review of the PR that adds this file,
> before the wave 3 items (#266-#269) start copying from it.

## The name

- **chadcn**, always lowercase, one word, also at the start of a sentence (like `shadcn`). Never "ChadCN", "Chadcn UI" or
  "chad-cn".
- The Ruby module is `Chadcn` and the gem is `chadcn`: that casing belongs to code, not prose.
- It is a play on `shadcn` (the upstream project) and "Chad", the internet archetype of someone calm, capable and
  unbothered. The joke is the attitude of the library (same components, less ceremony), never a person.
- npm already has an unrelated package named `chadcn`. Our gem lives on RubyGems only; the README says "the Ruby gem" the
  first time it names the package, and we never publish to npm under that name.

## Assets

All originals are in this folder and are hand-written SVG drawn from basic shapes (rectangles, lines and two curves). They
are original artwork: they copy no meme drawing (in particular not the well-known "Yes Chad" / Nordic Gamer image), trace
no photo and depict no real person. Keep it that way when editing them: no portraits, no celebrity or streamer features,
no third-party meme templates.

| File | Use on | Notes |
|---|---|---|
| `mascot-light.svg` | light backgrounds | dark ink (`#09090b`), light face (`#fafafa`) |
| `mascot-dark.svg` | dark backgrounds | same figure with a light outline (`#fafafa`) and a light-grey face (`#e4e4e7`) |
| `wordmark-light.svg` | light backgrounds | mascot at 0.75 scale + `chadcn` set in the system UI sans stack, bold, tight tracking |
| `wordmark-dark.svg` | dark backgrounds | same, light ink |

Rules:

- Colors are the neutral shadcn zinc pair (`#09090b` / `#fafafa`, plus `#18181b` and `#e4e4e7`): monochrome, so it sits next
  to any theme a user pastes from ui.shadcn.com/themes. No brand color, no gradients.
- Pick the variant by background. The packaged README is rendered by rubygems.org and rubydoc, where `dev/` does not
  exist, so the README uses absolute URLs built from the gemspec's `repository`, `gem_path` and `ref` (they change
  together when the gem moves to its own repository):

  ```html
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/doncan-orozco/papyro/main/gems/chadcn/dev/brand/wordmark-dark.svg">
    <img src="https://raw.githubusercontent.com/doncan-orozco/papyro/main/gems/chadcn/dev/brand/wordmark-light.svg" alt="chadcn" width="352" height="96">
  </picture>
  ```

- Embed with `<img alt="...">` (or `<picture>`). If an SVG is inlined, inline one variant only and switch colors with
  CSS, or rename its `id`s, so a page never has duplicate ids. Next to a visible "chadcn" heading the image is decorative
  (`alt=""`); without one it is `alt="chadcn"`.

- The mascot never appears inside components, component previews or the generated markup of an app. It belongs to the
  README hero, the docs index and the demo catalog header.
- Minimum size: 32 px tall for the mascot, 24 px tall for the wordmark. Do not recolor, stretch, rotate or add props to it.
- The wordmark's text is live SVG text; a consumer that needs pixel-identical output (a social preview image) exports a PNG
  from it rather than outlining the glyphs by hand.
- Item #266 copies these files to `gems/chadcn/dev/brand/` (the packaged gem does not ship them, so nothing packaged
  links to them relatively); this folder stays the original. Item #269 keeps its own copy for the host in
  `app/assets/images/brand/` (the host never reads the gem's `dev/`). That path is outside #269's Owns today, so the
  item's Owns needs `app/assets/images/brand/**` added before it starts (epic-flow R5).

## Tagline

**Primary (needs sign-off):**

> shadcn/ui for Phlex. Built different.

Alternatives offered for the sign-off, in order of preference:

1. "The shadcn/ui port that never skips leg day."
2. "shadcn/ui, in Ruby, unbothered."

The tagline goes under the wordmark in the README hero and on the demo catalog header. It is the only line of meme copy
that may appear above the fold; the factual description paragraph ("shadcn/ui for Phlex: the same component API, the
same Tailwind class strings and the same behavior as the React originals...") follows it unchanged.

Surfaces in the host app are bilingual (`i18n` R1). The host design-system page renders the tagline and the short
disclaimer from `config/locales/{en,es}/design_system.yml`:

| key | en | es |
|---|---|---|
| `design_system.brand.tagline` | shadcn/ui for Phlex. Built different. | shadcn/ui para Phlex. De otra pasta. |
| `design_system.brand.disclaimer` | Not affiliated with shadcn. Built on shadcn/ui (MIT). | Sin afiliación con shadcn. Basado en shadcn/ui (MIT). |
| `design_system.brand.wordmark_alt` | chadcn | chadcn |

The gem's own surfaces (README, docs, dummy catalog, doctor, generators) are English only. The ES tagline is part of the
maintainer sign-off.

## Approved one-liners

Use at most one one-liner per page (the tagline does not count), never two in a row. Each maps to a fact the reader can
check, so the joke always carries information.

| # | Line | Where it fits | The fact behind it |
|---|---|---|---|
| 1 | "Same components, unbothered." | README "Why chadcn" intro | 1:1 shadcn API and markup |
| 2 | "Upgrades are a `bundle update`. No sweat." | README / docs install intro | components live in the gem, not in your app |
| 3 | "Radix behavior, zero React." | docs behavior/JavaScript intro | Stimulus controllers on shared primitives |
| 4 | "All checks passed. You're in peak condition." | `chadcn:doctor` SUCCESS line | doctor: 0 warnings, 0 failures |
| 5 | "Installed. Your app just got a jawline." | install generator SUCCESS line | generator finished without errors |

## Voice rules

The meme is a seasoning on the docs and the developer experience, not on the product. A user reading an error, a screen
reader user, a translator or someone who never heard of the meme must lose nothing.

### Allowed surfaces

- README: the hero (wordmark, tagline) and at most one one-liner, in one section intro.
- Docs: the first paragraph of a guide (`docs/*.md` intros) and the docs index.
- Demo catalog (`dev/dummy`): the page header and the empty/landing state.
- `chadcn:doctor` and the install generator: the final SUCCESS line only, printed after the factual summary.
- CHANGELOG: one line of prose directly under a release heading; the heading itself stays `## [x.y.z] - YYYY-MM-DD`
  (Keep a Changelog) and every entry stays factual.

### Forbidden surfaces

- Component markup and everything it renders: class names, `data-slot`, `data-*` attributes, default text, placeholder
  copy, ARIA attributes, `sr-only` text, `aria-label`s and every other accessibility label.
- Exceptions, error messages, warnings, deprecation notices, doctor FAIL/WARN lines and generator conflict prompts.
- API documentation: YARD comments, method and option docs, `docs/` reference sections (anything below a guide's intro).
- Code identifiers beyond the name itself: no `gigachad`, `based`, `sigma` in method, class, option, controller or CSS
  names. Stimulus identifiers are `chadcn--<component>` and nothing more.
- Upstream names: shadcn/ui component names (`Dialog`, `Select`, `Sidebar`...), Radix, Lucide and Tailwind terms keep their
  upstream spelling and meaning. We never write "chadcn/ui" for the upstream project or rename a component.
- `llms.txt` and `llms-full.txt`: agents read them, like the doctor's JSON report.
- Commit messages, issue and PR titles, test names.

### Tone

- Calm confidence, never contempt. The joke is that chadcn is relaxed because the work is done (verbatim markup, browser
  parity tests), not that other tools or their users are lesser. No "virgin vs Chad" comparisons, no punching at React,
  shadcn, other Ruby UI libraries or their authors.
- No body shaming, gender or dating jokes, slurs, gym-bro insults or crude language. The tagline, its alternatives and the
  approved one-liners are the whole vocabulary ("jawline", "leg day", "unbothered", "no sweat", "built different",
  "peak condition"); anything new is added here by PR first.
- Plain English the reader can parse without the meme. If a line only works for people who know the reference, cut it.
- One line, then facts. A meme line never replaces information and is never longer than one sentence.

### Doctor and generator output

The SUCCESS line comes last, after the factual output and its summary line, on its own line, only in the text format and
only on a clean run: for the doctor, `counts[:warn].zero? && counts[:fail].zero?` (stricter than `Report#ok?`, which
ignores warnings), appended by `Report#to_text`; for the install generator, no conflict and no skip. The eject generator
prints no meme line. The JSON report never carries it: CI and agents parse that.

```text
[PASS] tailwindcss-rails: 4.3.0 bundles engine CSS
[PASS] importmap: chadcn--* controllers are pinned
[PASS] theme: app/assets/tailwind/theme/theme.css is valid

3 passed, 0 warnings, 0 failed
All checks passed. You're in peak condition.
```

(The check names above are illustrative; the line format is today's `Doctor::Report#to_text`.) A run with a warning or a
failure keeps today's neutral `[WARN] ...` / `[FAIL] ...` / `fix: ...` lines and prints no meme line at all. The
SUCCESS line is plain ASCII, so it reads the same in any terminal and in CI logs.

## Disclaimer and credit

Every surface that shows the wordmark (README, docs index, demo catalog footer) carries this text, verbatim:

> chadcn is an independent, community-maintained port of [shadcn/ui](https://ui.shadcn.com) to Phlex. It is not affiliated
> with, endorsed by or sponsored by shadcn or the shadcn/ui project. Component structure, class strings and behavior derive
> from shadcn/ui (MIT License, Copyright (c) 2023 shadcn); accessibility behavior follows Radix UI (MIT) and icons are
> Lucide (ISC). Every third-party notice is in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). chadcn itself is MIT licensed.

The link target is adjusted to the surface (`../THIRD_PARTY_NOTICES.md` from `docs/`, the repository URL in the
catalog); the wording is not. The docs index is `docs/README.md` (created by #267).

Short form, for the gemspec `description` and the demo catalog footer:

> Not affiliated with shadcn. Built on shadcn/ui (MIT).

Rules:

- `THIRD_PARTY_NOTICES.md` keeps every license text and copyright line unchanged (shadcn/ui, Radix UI, Lucide,
  Floating UI, tw-animate-css, Sonner); the rebrand only renames the project and the gem paths the notices cite.
- "shadcn" and "shadcn/ui" are always written the upstream way and link to ui.shadcn.com the first time they appear on a
  page.
- The mascot and wordmark are never combined with shadcn's own logo or presented as an official shadcn artifact.

## Checklist for the items that copy from this guide

- [ ] #266 README, gemspec, CHANGELOG: hero with `<picture>` wordmark, primary tagline, one-liner 1 or 2, full disclaimer,
      short disclaimer in the gemspec, absolute asset URLs in the README, assets copied to `gems/chadcn/dev/brand/` (not
      packaged).
- [ ] #267 docs and llms files: one-liner 2 or 3 in guide intros only; reference sections and llms files stay neutral;
      disclaimer in the docs index.
- [ ] #268 doctor and generators: one-liners 4 and 5 as SUCCESS lines; FAIL/WARN output unchanged and neutral; tests that
      a clean report's `to_text` ends with one-liner 4, a report with one warning has no such line, and `to_json` never
      contains it.
- [ ] #269 demo catalog and the host design-system page: wordmark + tagline in the header, short disclaimer in the footer
      (host strings from the EN+ES keys above), assets copied to `app/assets/images/brand/`; component previews
      untouched.
