# Prohibited Practices

**Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md)**

This is a quick list of anti-patterns. For complete guidelines, see the verification checklist.

## Practices to Avoid

- No ActiveRecord callbacks.
- No ActiveRecord validations for business logic (use Contracts instead).
- No business logic in models or controllers.
- No scopes or query methods in models (use Query Objects).
- No Strong Params filtering (validation in Contracts).
- No Redis when Solid Cache/Queue works.
- No polling when WebSockets available.
- No hidden magic; keep flow explicit.

## Allowed Exceptions

- Database constraints in migrations (null: false, indexes, foreign keys).
- Optional safety-net validations in models (paranoid mode, should never trigger).
- Safety-net validations apply in all environments.

> **For detailed requirements and checklist, see [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md) and [SELF_REVIEW_CHECKLIST.md](../../SELF_REVIEW_CHECKLIST.md)**

