# Prohibited Practices

**Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md)**

This is a quick list of anti-patterns. For complete guidelines, see the verification checklist.

## Practices to Avoid

- No ActiveRecord callbacks.
- No ActiveRecord validations.
- No business logic in models or controllers.
- No Strong Params filtering.
- No Redis when Solid Cache/Queue works.
- No polling when WebSockets available.
- No hidden magic; keep flow explicit.

> **For detailed requirements and checklist, see [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md) and [SELF_REVIEW_CHECKLIST.md](../../SELF_REVIEW_CHECKLIST.md)**

