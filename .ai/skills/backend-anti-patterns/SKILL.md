---
name: backend-anti-patterns
description: Common mistakes and anti-patterns to avoid in Papyro backend development. Use when reviewing code or implementing features to ensure compliance with best practices. Covers code commenting, controller patterns, operation patterns, authorization, query patterns, and validation anti-patterns.
---

# Backend Anti-Patterns

Use this skill as the fast reject-list for backend work. Keep the SKILL body focused on red flags and load the references only for the area you are touching.

## Core Red Flags

- Business logic in models
- Active Record validations used as the primary business-validation layer
- Model callbacks orchestrating write flows
- Scopes hiding read logic that belongs in query objects
- Authorization inside operations instead of at the controller or channel boundary
- Controller and operation both looking up the same record
- Update operations changing ownership fields such as `user_id`
- Hardcoded user-facing strings in operations, controllers, mailers, or jobs
- Relative translation keys like `t(".title")`
- Components without `**attrs` support
- Compound trigger helpers wrapping another button component inside the trigger
- Tests asserting private implementation details instead of public behavior

## Apply This Workflow

1. Identify the layer you are changing: cross-cutting foundations, domain logic, presentation/i18n, or tests.
2. Scan the matching reference file for the anti-patterns in that layer.
3. Load the companion implementation skill if you need the positive pattern, not just the warning.
4. Verify the final code against [../../copilot-instructions.md](/.github/copilot-instructions.md).

## Reference Map

- **[references/foundations.md](references/foundations.md)**
  Use for comment quality, `ApplicationController` composition, shared dry-schema message strategy, and route identifier consistency.
- **[references/domain-logic.md](references/domain-logic.md)**
  Use for models, operations, services, controllers, and authorization boundaries.
- **[references/presentation-and-i18n.md](references/presentation-and-i18n.md)**
  Use for views, components, Turbo frames, translation keys, and formatting helpers.
- **[references/testing.md](references/testing.md)**
  Use for behavior-first testing and result-payload assertions.

## Companion Skills

Load the focused skill when you need the recommended implementation pattern:

- **[../architecture/SKILL.md](../architecture/SKILL.md)** for operations, contracts, controllers, queries, and services
- **[../error-handling/SKILL.md](../error-handling/SKILL.md)** for `Dry::Monads::Result` payload handling
- **[../i18n/SKILL.md](../i18n/SKILL.md)** for locale structure and translation-key conventions
- **[../frontend/SKILL.md](../frontend/SKILL.md)** for Phlex and Stimulus composition rules
- **[../testing/SKILL.md](../testing/SKILL.md)** for positive test patterns
- **[../database-anti-patterns/SKILL.md](../database-anti-patterns/SKILL.md)** and **[../sqlite/SKILL.md](../sqlite/SKILL.md)** for migration safety

## Review Heuristics

- If the change adds hidden magic, it is probably the wrong abstraction boundary.
- If a controller passes only an ID to an update/destroy operation after already authorizing the record, it is probably duplicating work and weakening authorization.
- If a translation key is not domain-shaped and grep-able, it will age badly.
- If a test has to know too much about the operation internals, it is probably testing the wrong thing.

For verification, see [../../copilot-instructions.md](/.github/copilot-instructions.md).
