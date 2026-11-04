# Markdown gem: maintainer decisions

Status: APPROVED by the maintainer on 2026-11-04. Every open decision in REQUIREMENTS.md is answered below.

## Gem name

**Decided: `papyro-md`.**

| Place | Value |
|-------|-------|
| RubyGems gem | `papyro-md` |
| npm package | `papyro-md` |
| Ruby constant | `PapyroMd` (not `Papyro::Md`: it would share a namespace with the host app) |
| CSS token prefix | `--md-*` (`--md-primary`, `--md-primary-foreground`) |
| Avo field type, generator namespace | derived from the name (`papyro_md`), settled in the implementation epic |

Checked 2026-11-04: `papyro-md` returns 404 on both rubygems.org and registry.npmjs.org, so it is free today. Reserve it
by publishing early. `REQUIREMENTS.md` uses `Md` / `md:install` as placeholders; they read as `PapyroMd` and the
generator namespace above.

## Approved requirements

### Decided

| ID | Decision |
|----|----------|
| D-01 | `papyro-md`, see above |
| D-02 | The gem ships `has_markdown`. Papyro renames its own macro first (code only, host and engine call sites in one change), before the gem enters its bundle |
| D-03 | No Phlex runtime dependency. `render_in` objects serve Phlex, ERB and ViewComponent; an optional kit (0.2) gives Phlex sugar |
| D-04 | Cap commonmarker at the next minor (`~> 2.10.1`); widen in a gem patch once the frozen-fixture CI job passes on the new minor |
| D-09 | Publish the gem and the npm package from 0.1, from one release workflow |
| D-12 | Rails 8.1+ on Ruby 3.3+ |
| D-13 | Companion repository in Papyro's flow workspace during 0.x, standalone from 1.0; admin integrations stay optional files in it |
| D-14 | The gem defaults to Unicode GitHub-style slugs; Papyro keeps its legacy slugger through 0.x and decides at 1.0 |
| RAILS 4 | The WTFPL licence of `reverse_markdown` is accepted (app-side fallback for the Action Text migration, never in the gemspec) |

### Decided: recommendations approved as written in REQUIREMENTS.md

| ID | Recommendation |
|----|----------------|
| D-05 | One `config.authorize` hook with the actions `:preview`, `:upload`, `:read_upload`, `:read`, `:propose`, `:withdraw`, `:apply`, `:review`; fails closed except `:preview` |
| D-06 | Generated hook allows `:preview` for `authenticated?` / `current_user`, else `true` with a warning; CSRF and `rate_limit` always on |
| D-07 | Keep the renderer replacement (DX-21) with the final sanitizer still applied; schedule after 1.0 |
| D-08 | CodeMirror as one prebuilt file plus shim pins for the four core packages |
| D-10 | Mermaid in a companion gem (named `papyro-md-mermaid` to match the gem name; REQUIREMENTS.md's placeholder was `md-mermaid`) |
| D-11 | Extension budget recounted as eight mechanisms |
| D-15 | Source is the default mode through 0.x; Live ships when EDIT-34 passes in Live mode |
| Area decisions | Every other row of the area-decision table is taken as the synthesis view states it |

## Repository

**Go.** Create `doncan-orozco/papyro-md`. Creating the repository is a maintainer step; the implementation epic starts from this file.
