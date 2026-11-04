# Markdown gem requirements: research docs

This folder holds the research behind a standalone Rails gem for markdown viewers and editors (placeholder name `Md`
until the maintainer sign-off picks one), with Papyro as its first consumer. No code is written here: every doc ends in
numbered requirements that the implementation is planned from.

## How the docs fit together

1. **Inputs.** The benchmark report (`../reports/Markdown editor benchmark.md`) and its research notes
   (`../research_notes/Markdown editor benchmark/`) already settle the big choices: markdown text is the only source of
   truth, commonmarker 2.x with one sanitized pipeline, CodeMirror 6 decorating the text, four layers (render core,
   viewer, editor, optional agent layer). Area docs cite them instead of researching them again.
2. **Area docs** (this folder). One doc per area, each copied from `TEMPLATE.md`, each owning one area code. A doc
   answers its questions, lists findings with sources, and turns them into requirements with IDs of its own code.
3. **Synthesis** (`../REQUIREMENTS.md`). Merges the area docs: a traceability table with every requirement ID,
   conflicts resolved or escalated, the Rails integration plan, a release plan that assigns every MUST, and the open
   decisions with recommendations.
4. **Sign-off** (`../DECISIONS.md`). A maintainer answers the open decisions, picks the gem name and approves the
   repository. The implementation epic starts from `REQUIREMENTS.md` and `DECISIONS.md`.

The priorities hold for every area, in this order: developer experience, then the writer's and reader's experience,
then customization. A requirement that adds API surface says what it costs a newcomer.

## Area codes

| Code | Doc | Covers |
|------|-----|--------|
| `DX` | `developer-experience.md` | install, configuration, public API, quick start, upgrades |
| `RAILS` | `rails-framework-integration.md` | Active Record, Action Text, Active Storage, Action Cable, Turbo, i18n |
| `ASSETS` | `asset-pipeline-integration.md` | JavaScript and CSS delivery: importmap, jsbundling, Propshaft, Sprockets |
| `VIEWS` | `view-and-form-integration.md` | ERB, Phlex and ViewComponent, form builders, admin frameworks |
| `THEME` | `theming-and-customization.md` | design tokens, theming the viewer and the editor, overrides |
| `EDIT` | `editor-ux.md` | the editing experience: toolbar, shortcuts, preview, uploads, accessibility |
| `RENDER` | `render-and-viewer.md` | the rendering pipeline, dialect, sanitizing, the viewer |
| `AGENT` | `agent-layer.md` | suggestions, review, MCP access for AI agents |
| `PRIOR` | `prior-art-teardown.md` | Marksmith, Lexxy and other prior art |
| `PAPYRO` | `papyro-as-consumer.md` | what Papyro needs to adopt the gem |

The checker knows these codes (`AREAS` in `.claude/scripts/markdown_gem/requirements_check.rb`); a test keeps this table
and that list in sync.

## Writing an area doc

Copy `TEMPLATE.md` to the doc your area owns and replace every marker in angle brackets. The doc has these H2
sections, all required: **Scope**, **Questions**, **Findings**, **Requirements**, **Developer experience notes**,
**Open decisions**, **Sources**. Extra sections and H3 subsections are fine.

### Requirement format

Every top-level list item under `## Requirements` is a requirement, written on one list item (continuation lines
indented under it):

```markdown
- **DX-01** (MUST) `bin/rails generate md:install` sets up the gem in one command. Acceptance: a new Rails app renders
  the editor after the generator with no other step.
```

- **ID**: the area code, a dash and a number of at least two digits (`DX-01`, `RENDER-12`). Number in order, never
  reuse or renumber an ID once the doc is merged: the synthesis and the implementation trace by ID. Mention another
  area's requirement by its ID in prose; never define it.
- **Priority** (MoSCoW): `MUST` (the gem fails its priorities without it, so it belongs in a release plan),
  `SHOULD` (expected, may come after the first release), `COULD` (nice to have). WON'T items go to the Scope section as
  out of scope, not to Requirements.
- **Acceptance**: `Acceptance:` followed by a one-line check a reviewer or a test can run.

Put intro prose before the first item and group with H3 headings if it helps; do not use other top-level lists in this
section (nest them under a requirement instead).

### Sources

One source per list item, as a URL with its access date: `- https://github.com/basecamp/lexxy (accessed 2026-11-03)`.
The checker counts distinct URLs in this section only (at least five by default); paths to the benchmark report and
research notes are welcome as well but do not count.

### Placeholders

The checker fails on `TODO`, `TBD` and on template markers (`<...>` spans such as `<AREA>` or `<one-line check>`).
Lowercase HTML tags (`<kbd>`, `<br/>`), autolinks (`<https://...>`) and anything inside code spans or fenced code
blocks are not markers, so ERB and HTML examples belong in backticks. A marker is caught only when it opens and closes
on one line, which is how the template writes them.

## The synthesis traceability table

`../REQUIREMENTS.md` has a `## Traceability` section with a table that lists every requirement ID of the area docs,
one per row. Only table rows inside that section count; IDs mentioned elsewhere do not.

```markdown
## Traceability

| ID | Priority | Release | Doc | Notes |
|----|----------|---------|-----|-------|
| DX-01 | MUST | 0.1 | developer-experience.md | |
```

## Running the checker

```bash
ruby .claude/scripts/markdown_gem/requirements_check.rb --area DX docs/features/markdown-editor/requirements/developer-experience.md
ruby .claude/scripts/markdown_gem/requirements_check.rb --synthesis docs/features/markdown-editor/REQUIREMENTS.md docs/features/markdown-editor/requirements
```

- `--area CODE FILE [--min-sources N]` fails when a required section is missing, a placeholder remains, a requirement
  lacks the `**CODE-NN** (MUST|SHOULD|COULD)` opening or an `Acceptance:` clause, an ID repeats, or Sources has fewer
  than N (default 5) distinct URLs.
- `--synthesis FILE DIR` fails when an ID defined in `DIR/*.md` (this README and `TEMPLATE.md` excluded) is missing
  from the traceability table of FILE, and names where each missing ID is defined.

Findings print as `file:line: message`. Exit 0 passes, 1 means findings, 2 means bad input (unknown area code, missing
file, a directory without research docs, bad flags). A missing section is reported at the heading where it belongs.
The checker's tests live in `test/lib/markdown_gem/` (`bin/rails test test/lib/markdown_gem`).
