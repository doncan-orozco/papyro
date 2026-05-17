# Host-Coupled Engine Pattern (Papyro + PapyroStudio)

Use this reference when the private `PapyroStudio` engine runs as a mounted boundary of the host app instead of a standalone app with its own dummy test harness.

## Ownership Matrix

- Host app owns:
  - Database schema and migrations
  - Core models (`User`, `Article`, related translations)
  - Authentication/session lifecycle (`Current.user`, signed session cookie)
  - Public site routing and localized root behavior
- Engine owns:
  - Studio route space and controllers mounted on `studio` subdomain
  - Studio views/components/assets and orchestration boundary
  - Studio-focused request/policy/presenter test suites

## Routing Boundary

- Host mounts engine under subdomain constraint and mount alias in host routes.
- Engine routes should remain RESTful and can use unscoped helper names internally.
- During helper migration, a compatibility bridge may keep legacy `studio_*` helper methods delegating to unscoped helpers.

## Session Boundary

- Shared session behavior across host and studio subdomains requires all auth cookies to be domain-aware, not only the Rails session store cookie.
- If a custom signed cookie is used for auth lookup (for example `session_id`), write it with `domain: :all`.
- Resume-session flow should upgrade legacy host-only cookies by re-persisting with shared domain options.
- Logout should delete both shared-domain and host-only variants to avoid stale auth state.

## Test Harness Pattern (No Dummy App)

- Engine `test/test_helper.rb` can load host environment directly:
  - Set `RAILS_ENV=test`
  - Resolve host app root (for example sibling `../papyro`)
  - Require host `config/environment`
  - Reuse host fixtures path
- Run engine tests from host app directory so DB and app boot are consistent.

## Recommended Command Flow

From host app root:

1. `bin/rails test`
2. `bin/rails test ../papyro_studio/test`
3. `bin/rails test:with_studio`

Use host smoke integration tests to verify mount/subdomain/session boundaries, and keep domain-depth studio tests inside the engine suite.

Last validated on: 2026-05-16
