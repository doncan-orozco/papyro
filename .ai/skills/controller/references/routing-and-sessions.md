# Routing, Engine and Session Details

## Mounted Engine Route Handling (Papyro Studio)

For the mounted Studio engine (our sibling repo `papyro_studio`) used in this repository:

1. In host code, generate studio links through the mounted-engine proxy (`papyro_studio`) so URLs carry the studio subdomain boundary explicitly.
2. In engine code, prefer unscoped route helpers (`articles_path`, `article_path`) after removing route helper prefix scopes.
3. During migrations, keep temporary compatibility wrappers for legacy `studio_*` helper names in one helper module; wrappers should delegate to unscoped helpers and be removed after call sites are migrated.
4. Keep REST semantics unchanged while migrating helper names.

## Cross-Subdomain Session Cookie Rules

When authentication uses a custom signed cookie (for example `session_id`) in addition to Rails session storage:

1. Persist the signed cookie with `domain: :all` so host and `studio` subdomain share auth state.
2. In resume-session logic, re-persist found sessions using shared-domain cookie options to upgrade legacy host-only cookies.
3. On logout, delete both shared-domain and host-only cookie variants.
4. Keep redirect fallback after successful login deterministic (for this app, localized home path) unless an explicit return URL exists.
