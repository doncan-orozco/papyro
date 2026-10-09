# Host-Coupled Engine Pattern (Papyro + PapyroStudio)

`papyro` (the HOST) and `papyro_studio` (the Studio ENGINE) are two repositories of ours that ship as one product. The engine is private as a gem, but it is first-party code: agents and developers read, audit and edit it exactly like the host. Features frequently span both repos (a workspace), so plan and audit them together.

## Workspace Layout

- Host: `/Users/doncan/Documents/papyro`. Engine: sibling `../papyro_studio` (same parent directory).
- The host Gemfile points at the GitHub repo (`gem "papyro_studio", git: …, branch: "main"`), but `.bundle/config` carries `BUNDLE_LOCAL__PAPYRO_STUDIO: "<path to sibling>"`, so Bundler loads the sibling checkout directly. Edits in the engine are live in the host with no push or `bundle update`. Before releasing, push the engine and run `bundle update papyro_studio` in the host so `Gemfile.lock` records the new SHA.
- Claude Code: `.claude/settings.local.json` in the host grants the engine directory (`permissions.additionalDirectories` + allow rules). Sessions started in the engine get the host skills via the engine's `CLAUDE.md`.

## Ownership Matrix

- Host owns:
  - Database schema, migrations and seeds
  - Core models (`User`, `Article`, translations, `AuthorProfile`…) and fixtures
  - Authentication/session lifecycle (`Current.user`, signed `session_id` cookie)
  - Public site routing, localized root behavior, mounting the engine
  - ALL locale files (`config/locales/{en,es}`), including the strings used by Studio UI
  - Skills (`.ai/skills`), CI and the shared test tasks
- Engine owns:
  - Studio routes (`config/routes.rb`), `PapyroStudio::*Controller`s mounted on the `studio` subdomain
  - `Studio::` concepts (presenters/operations), Phlex views and `Studio::` components
  - `Studio::*Policy` Pundit policies
  - Stimulus controllers under `app/javascript/controllers/studio/**` (identifiers `studio--…`), pinned by the engine's `config/importmap.rb`
  - Studio request/policy/presenter tests
- The engine never adds migrations or models. If a feature needs schema or a model change, that change goes in the host first.

## Engine File Map

| Concern | Engine path |
|---|---|
| Controllers | `app/controllers/papyro_studio/*_controller.rb`, concerns in `app/controllers/concerns/papyro_studio/` |
| Operations / presenters | `app/concepts/studio/**` (autoload path added in `lib/papyro_studio/engine.rb`) |
| Views / components | `app/views/**` and `app/components/studio/**` (Phlex; `Views`/`Components` namespaces pushed to the host autoloader) |
| Policies | `app/policies/studio/*_policy.rb` |
| Stimulus | `app/javascript/controllers/studio/**` |
| Tests | `test/{controllers,policies,concepts}/studio/**`, helpers in `test/test_helpers/` |

## Routing Boundary

- The host mounts the engine under a `studio` subdomain constraint with the `papyro_studio` mount alias.
- Engine routes stay RESTful and use unscoped helper names internally; state transitions are sub-resources (`resource :publication`, `resource :restoration`…). From host code, link into Studio through the mounted-engine proxy so URLs carry the subdomain.
- During helper migration, a compatibility bridge may keep legacy `studio_*` helper methods delegating to the unscoped helpers.

## Session Boundary

- Shared session across host and `studio` subdomains requires every auth cookie to be domain-aware, not only the Rails session store cookie.
- A custom signed cookie used for auth lookup (for example `session_id`) is written with `domain: :all`.
- Resume-session upgrades legacy host-only cookies by re-persisting with shared-domain options.
- Logout deletes both shared-domain and host-only variants.

## Test Harness Pattern (No Dummy App)

- The engine's `test/test_helper.rb` boots the host (`HOST_APP_ROOT = ../papyro`) and reuses the host fixtures, so engine tests only run with a host checkout beside them.
- Always run engine tests FROM THE HOST ROOT.

## Recommended Command Flow (from the host root)

1. `bin/rails test` (host only)
2. `bin/rails test ../papyro_studio/test` (engine only) or one file: `bin/rails test ../papyro_studio/test/controllers/studio/articles_controller_test.rb`
3. `bin/rails test:with_studio` (host + engine, no system tests); `bin/rails test:system_with_studio` for system tests (engine system tests only if `../papyro_studio/test/system` exists; Studio flows today are host system tests under `test/system/studio`)
4. Lint per repo: `bin/rubocop` in the host and `bin/rubocop` in the engine (engine CI runs lint only)

Use host smoke integration tests for mount/subdomain/session boundaries and keep domain-depth Studio tests in the engine suite.

## Cross-Repo Feature Checklist

1. Schema/model/locale/fixture changes land in the host first.
2. Engine code touches host models only through their public API and relies on `Current.user` from the shared session.
3. Every user-facing string used by the engine has `en` and `es` keys in the host.
4. Route helper names used across the mount match on both sides.
5. Tests exist in the owning repo (see the file map) and pass from the host root.
6. Commits and pushes happen per repo; the host `Gemfile.lock` is updated only when releasing an engine change.

Last validated on: 2026-10-08
