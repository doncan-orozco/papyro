---
description: Top-Down feature planning (City -> House -> Rooms -> Bricks) with greenfield scaffolding for Rails 8 + Phlex + Stimulus.
argument-hint: "<ticket text or @ticket.md> [--epic <text|@file>] [--dry-run]"
allowed-tools: Agent, Read, Grep, Glob, TodoWrite, Bash(git:*)
---

# Top-Down Feature Planning: City, House, Rooms, Bricks

Target: $ARGUMENTS
If $ARGUMENTS is empty, ask for the ticket text (and epic text if one exists).

Input convention — parse $ARGUMENTS as: `[ticket...] [--epic <text|@file>] [--dry-run]`
- `ticket...` (required): raw ticket text with acceptance criteria, or `@path/to/ticket.md` (`Read` it first; never truncate intent).
- `--epic <text|@file>`: parent epic context (City). Optional but recommended; without it you derive a minimal City Map from the codebase and say so.
- `--dry-run`: output blueprint + file list only, write no files.
- No issue-tracker API is wired in. You are the orchestrator (main session); `Agent` fan-out is the pipeline.

You are the orchestrator. You DO NOT write business logic. You produce a City-aware blueprint, then fan out greenfield scaffolding to the Builder. Planning is Top-Down, the exact inverse of `/audit-feature`: Epic (City) → Ticket (House) → Files (Rooms) → Methods (Bricks, left as TODOs).

Stack facts: Ruby 4.0 / Rails 8.1 / SQLite, Phlex views + components, Turbo + Stimulus (importmap), Tailwind, dry-operation/dry-monads/dry-validation under `app/concepts/**`, Pundit, Mobility + route_translator (EN + ES mandatory), Minitest. **Workspace:** two repos of ours that often ship one feature together: the HOST (`papyro`: public site, auth, models/schema/migrations, locales, fixtures) and the Studio ENGINE (`papyro_studio`, sibling `../papyro_studio`: authoring UI mounted on the `studio` subdomain, namespaces `PapyroStudio::` for controllers and `Studio::` for concepts/components/policies/Stimulus). Every blueprint file is tagged `repo: host|studio`. Host owns schema, models, auth, locales (ALL EN+ES keys, even for engine UI) and fixtures; the engine owns Studio controllers/routes/views/components/policies/Stimulus and its tests (which boot the host: `bin/rails test ../papyro_studio/test/...` from the host root). Engine code never adds migrations or models.

## Phase 0 — City Map (you do this)
1. `REPO` = `git rev-parse --show-toplevel`. Resolve `HOST` (`git rev-parse --show-toplevel`) and `ENGINE` (`.bundle/config` `BUNDLE_LOCAL__PAPYRO_STUDIO`, else `<HOST>/../papyro_studio`). Build the City Map from the pasted `--epic` text (ubiquitous language, boundaries) and codebase reality in BOTH repos via `Grep`/`Glob`/`Read`: `db/schema.rb`, `app/models`, `app/concepts/*/{operation,contract,query,presenter,validator,service}`, `app/policies`, `app/controllers` + `config/routes.rb` (subdomain constraints, `localized` block), `app/views`, `app/components/{ui,shared,public,…}`, `app/javascript/controllers`, `app/jobs`, `app/mailers`, `config/locales` (host), and in the engine `app/controllers/papyro_studio`, `app/concepts/studio`, `app/components/studio`, `app/policies/studio`, `app/javascript/controllers/studio`, `config/routes.rb`, `config/importmap.rb`. Record only what exists — never invent infrastructure.
2. Output a compact City Map: `domain`, `existing_infrastructure`, `ubiquitous_language` (3–10 terms). No epic ⇒ mark `DERIVED_FROM_CODE` and keep it minimal.

## Skill Catalog & Layer Map (Phases 1–2; the same law the audit enforces)
Skills live in `<HOST>/.ai/skills/<name>/SKILL.md` and govern both repos.

| Layer / path | Holds | Skills to bind | Returns |
|---|---|---|---|
| `app/controllers/**`, `config/routes.rb` | HTTP boundary: parse, authorize, dispatch, render. Strict REST; transitions are sub-resource controllers | `controller`, `pundit-auth`, `naming-conventions` | redirect/render |
| `app/concepts/*/operation/**` | one write intent per operation, explicit deps, transactions for multi-write | `operation-pattern`, `naming-conventions` | payload hash / failure with `code` |
| `app/concepts/*/contract/**` | structural validation (dry-validation) | `operation-pattern` (layered validation) | contract result |
| `app/concepts/*/query/**` | reads, filtering, sorting (unpaginated Relation) | `query-object-pattern` | `ActiveRecord::Relation` |
| `app/concepts/*/presenter/**` | display logic (SimpleDelegator over `Core::Presenter::Base`) | `presenter-pattern` | display values |
| `app/models/**`, validators | schema, associations, simple validations, state predicates; no scopes, no business logic | `models` (+ `i18n` for Mobility) | — |
| `app/policies/**` | Pundit policies and scopes | `pundit-auth` | boolean / scope |
| `app/views/**`, `app/components/**` | dumb Phlex views, sub-components, UI vs domain components | `phlex-view-pattern`, `accessibility`, `i18n` (`design-system` for `components/ui`) | HTML |
| `app/javascript/controllers/**` (host) and `studio:app/javascript/controllers/studio/**` | Stimulus behavior (declared targets/values, cleanup in `disconnect`) | `stimulus`, `accessibility` | — |
| `app/jobs/**`, `app/mailers/**`, `app/services/**` | thin job shells, mailers with presenter-fed views, external clients | `jobs-and-mailers`, `operation-pattern` | — |
| `app/channels/**` | Action Cable | `realtime` | — |
| `db/migrate/**` | safe migrations (strong_migrations) | `sqlite` | — |
| `config/locales/**` | EN + ES keys, fully qualified | `i18n` | — |
| `test/**` | Minitest per concept; system tests for Hotwire flows | `testing` | — |

Repo placement test: schema, models, auth/session, public pages, locales, fixtures ⇒ `host`; Studio/authoring controllers, engine routes, Studio views/components/policies/operations/presenters and their Stimulus ⇒ `studio`; a feature touching both gets entries in both repos ordered host-first (schema/models/locales) with the cross-repo contract spelled out (route helper names, model API the engine calls, locale keys). Never put authoring UI in the host or a model/migration in the engine.

Placement test for ANY new Ruby file: changes state ⇒ operation (+ contract); finds records ⇒ query; formats for display ⇒ presenter (never in the view or controller); decides access ⇒ policy; shows HTML ⇒ Phlex view/component; reacts to the browser ⇒ Stimulus; queue entry ⇒ thin job + operation. Controllers get no logic, models get no scopes.

## Phase 1 — House Blueprint (one planner call)
1. Send ONE `feature-blueprint-planner` call with `EPIC_CONTEXT + TICKET (verbatim) + CODEBASE_EXCERPTS (routes, schema, related files, trimmed)`. Demand strict JSON `ticket, city_notes, house_blueprint[]`, each entry `action, file_path, skills_to_apply, responsibility, contract, acceptance_trace`.
2. Validate yourself: every entry traces to an AC bullet; every `create` justifies why no City entry sufficed; placement follows the Layer Map; each mutation has ONE operation per intent (no action-flag operations, no controller-side orchestration of several operations); each new controller action is one of the 7 REST actions or a sub-resource controller; every controller entry names its Pundit policy and the operation/query it calls; every view entry names its presenter and uses no logic; every user-facing string has EN + ES locale entries in the blueprint; every model change binds `models` (no scopes, no callbacks orchestrating writes); every migration binds `sqlite` and is strong_migrations-safe; every Stimulus entry lists its targets/values and the view that uses it; every new file has a test entry: host mirrors its path under `test/`; engine tests go to `studio:test/{controllers,policies,concepts}/studio/**`; every entry carries `repo`; cross-repo contracts are listed; no migration or model appears under `studio`. Invalid ⇒ retry ONCE naming the defect; still bad ⇒ stop and show the defect to the user. Never scaffold from a broken blueprint.

## Phase 2 — Greenfield Scaffold (parallel per file)
Resolve each entry's `skills_to_apply` (+ path-matched skills from the audit's Phase 0.5 matrix) to ABSOLUTE `SKILL.md` paths, `Glob` to verify, and pass them as `<SKILL_FILES>` (paths only, max 5 per file); the Builder `Read`s them in full first.
1. ONE `senior-rails-dev` call PER blueprint file, all in the SAME block, prompt = `Scaffold greenfield skeleton ONLY. No business logic — TODO blocks. <SKILL_FILES> + file_path + responsibility + contract + acceptance_trace. Rules: operations inherit the project's operation base, take explicit dependencies, return the documented payload/failure-code shape, one public \`call\`; contracts validate structure only; queries return an unpaginated Relation; presenters inherit \`Core::Presenter::Base\`; controllers hold only authorize → dispatch → render/redirect with qualified \`t("…")\` keys and \`status: :unprocessable_entity\` on invalid models; views are Phlex, dumb, read only the presenter, no fetch or queries; Stimulus controllers declare targets/values and clean up in disconnect; locale keys added to BOTH en and es; migrations safe for strong_migrations; a Minitest test file created alongside each Ruby file. Minimal diff, no global formatters.`
2. The Builder writes files + tests + TODOs and returns `git status` of created files. The blueprint is frozen during scaffolding. If a Builder reports a blueprint contradiction, stop that file, surface it, continue the rest.

## Phase 3 — Handoff (you do this)
1. Write `ARCHITECTURE.md` in the branch (one `senior-rails-dev` file-write call, or inline on `--dry-run`): City Map summary, blueprint table (file → action → skill → AC trace), contracts, the developer TODO list, the per-repo branch names, and the verify command `/audit-feature <branch> [--fix]` (it audits both repos). Per repo policy, implementation docs do NOT belong in the repo root: write to `docs/features/<ticket-slug>/ARCHITECTURE.md`.
2. Publish the blueprint table + TODOs verbatim and state `scaffolded_files: N, logic_todos: M, audit_command: /audit-feature <branch>`.
3. Close todos. The developer fills the TODOs, opens a PR, and the audit verifies the boundaries planning established.

## Rules
- Top-Down only: never audit here, never write logic in scaffolds (TODOs only).
- One session throughout (planner JSON and skill bodies stay prompt-cached).
- Cost: planner is one heavy call (`opus`); scaffolds are parallel Builder calls (`sonnet`). Cap blueprints at 15 files across both repos; larger epics split per ticket.
- Never commit or push in either repo. Output files + diff stat per repo only.
