# Prohibited Practices

- No ActiveRecord callbacks.
- No ActiveRecord validations.
- No business logic in models or controllers.
- No Strong Params filtering.
- No Redis when Solid Cache/Queue works.
- No polling when WebSockets available.
- No hidden magic; keep flow explicit.

> **For detailed pre-commit checklist, see [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md) and [SELF_REVIEW_CHECKLIST.md](../../SELF_REVIEW_CHECKLIST.md)**

