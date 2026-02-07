# Prohibited Practices

- No ActiveRecord callbacks.
- No ActiveRecord validations.
- No business logic in models or controllers.
- No Strong Params filtering.
- No Redis when Solid Cache/Queue works.
- No polling when WebSockets available.
- No hidden magic; keep flow explicit.
