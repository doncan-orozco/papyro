---
name: architecture
description: "Papyro app architecture: where code lives (`app/concepts/*/{operation,contract,query,presenter,service}`), vertical-slice and no-namespace-stuttering rules, host-coupled Studio engine (papyro_studio, first-party sibling repo, edited together with the host), request-scoped `Current` attributes. Use when deciding where new code belongs, adding a page/component/frame, or organizing files across layers."
---

# Architecture (Clean Architecture + dry-rb)

## Quick Rules

Cite as `architecture R<n>`. Detail and examples follow below / in references/.

R1. **Concepts vertical slice.** Domain backend code lives in `app/concepts/{domain}/{operation,contract,query,service,validator,presenter}/`, not in horizontal top-level folders. → detail: Vertical Slice Rule
R2. **Namespaced classes.** Classes use `Domain::Layer::Name` (e.g. `Articles::Query::Published`) with file paths matching module nesting for Zeitwerk. → detail: Vertical Slice Rule
R3. **No namespace stuttering.** Class and file names never repeat the domain or layer (`Published`, not `PublishedQuery`; `Body`, not `BodyValidator`). → detail: No Namespace Stuttering
R4. **Thin controllers.** Controllers only authorize and call namespaced concept objects; no domain logic in them. → detail: references/controllers.md
R5. **Models persist only.** `app/models/` holds persistence concerns; reads go to query objects and writes to operations. → detail: references/models.md
R6. **Write flow order.** Mutations follow Pundit at the controller, then contract, then operation (model rules and persist), returning `Success(payload)` or `Failure(model: ...)`. → detail: Operations Flow
R7. **Operation `call` returns plain payload.** `call` returns a plain hash (e.g. `{ model: article }`), never an explicit `Success(...)`. → detail: references/session-learnings-mutation-flows.md
R8. **Contracts structural only.** Contracts check types, coercion and key presence; uniqueness, state and persisted-format rules live in models. → detail: references/session-learnings-mutation-flows.md
R9. **One operation per intent.** State transitions get one operation each (`Publish`, `Unpublish`), with no `action` flag branching and controller actions mapping 1-to-1. → detail: references/session-learnings-mutation-flows.md
R10. **Update flows.** Update contracts accept partial payloads, assign only validated keys, and never make ownership fields (e.g. `user_id`) mutable. → detail: references/session-learnings-mutation-flows.md
R11. **Consistent failure payload.** Failures return `{ model:, errors: }` with contract errors injected into an ActiveModel instance. → detail: references/session-learnings-mutation-flows.md
R12. **Refactor cleanup.** Structural moves delete legacy duplicate files, update all call sites, and keep path, module and class names aligned. → detail: Refactor Safety Checklist
R13. **Host owns schema and auth.** Studio engine code leaves schema, core models and session lifecycle to the host, and does not fork domain logic; engine tests run from host root. → detail: references/host-coupled-engine-pattern.md
R14. **Shared-domain auth cookies.** Custom signed auth cookies are written with `domain: :all`, and logout deletes shared-domain and host-only variants. → detail: references/host-coupled-engine-pattern.md
R15. **Current for request state.** Request-scoped state uses `Current` (`ActiveSupport::CurrentAttributes`), with `I18n.locale` and `Time.zone` synced in `ApplicationController`; unit tests assign `Current.user` manually. → detail: references/current-context.md

## Dependencies
- dry-monads
- dry-validation

## File Structure (Domain + Rails Conventions)
```
app/
  concepts/
    articles/
      operation/
        create.rb
        update.rb
      contract/
        create.rb
        update.rb
      query/
        published.rb
      service/
        content_analysis.rb
      presenter/
        default.rb
      validator/
        body.rb
  
  components/        ← Reusable UI components (Phlex)
    game/
      player_card.rb
    ui/
      button.rb
  
  views/             ← Page-level views (Phlex)
    games/
      index.rb
      show.rb
    players/
      index.rb
  
  controllers/       ← Thin controllers
  channels/          ← WebSocket channels
  models/            ← ActiveRecord (persistence only)
  javascript/
    controllers/
      studio/
        articles/
          autosave_controller.js
```

### Vertical Slice Rule

For domain-specific backend code, prefer `app/concepts/{domain}/...` over horizontal top-level folders.

#### 🚫 No Namespace Stuttering
**Do not repeat the domain or type in the class or file name.**
For example, use `Published` (not `PublishedQuery`), `Body` (not `BodyValidator`), and `Default`/`Show` (not `ArticlePresenter`/`ShowPresenter`).

**Correct:**
- `app/concepts/articles/query/published.rb` → `Articles::Query::Published`
- `app/concepts/articles/validator/body.rb` → `Articles::Validator::Body`
- `app/concepts/articles/presenter/default.rb` → `Articles::Presenter::Default`

**Incorrect:**
- `published_query.rb`, `body_validator.rb`, `article_presenter.rb`

1. Put read flows in `app/concepts/{domain}/query/` using `Domain::Query::*` namespaces (no stuttering).
2. Put domain services in `app/concepts/{domain}/service/` using `Domain::Service::*` namespaces.
3. Put domain validators in `app/concepts/{domain}/validator/` using `Domain::Validator::*` namespaces.
4. Put domain presenters in `app/concepts/{domain}/presenter/` using `Domain::Presenter::*` namespaces.
5. Keep controllers thin and call these namespaced objects directly.

### Refactor Safety Checklist (Required)

When performing structural refactors (renames/moves between `app/presenters`, `app/queries`, and `app/concepts`):

1. Remove legacy duplicate files immediately after references are migrated.
2. Verify file path, module nesting, and class name alignment for Zeitwerk.
3. Confirm all call sites are updated (controllers, views, operations, tests).
4. Run targeted suites for touched domains before full test runs.
5. Finish with full regression (`bin/rails test` and `bin/rails test:system`).

## Host-Coupled Engine Pattern (Papyro Studio)

`papyro_studio` is our own engine (sibling repo `../papyro_studio`), mounted under the `studio` subdomain and often edited in the same change as the host:

1. The host owns database schema, core models (`User`, `Article`), fixtures, ALL locale files and the authentication/session lifecycle.
2. The engine owns Studio routes, controllers, `Studio::` concepts/views/components/policies and Stimulus controllers; it never adds migrations or models.
3. Keep mutations and policies aligned with host-domain behavior so the engine does not fork domain logic.
4. Run engine tests from the host root (`bin/rails test ../papyro_studio/test/...`): the engine has no dummy app.
5. Plan and audit cross-repo features together (`/plan-feature`, `/audit-feature` handle both repos).

For the ownership matrix, mount boundary, test helper wiring, and run commands, load:
- [references/host-coupled-engine-pattern.md](references/host-coupled-engine-pattern.md)

## Implementation Notes

This file focuses on patterns and examples. For requirements, see:
- [Architecture rules](/.github/copilot-instructions.md#-architecture--organization)
- [Queries](/.github/copilot-instructions.md#queries-read-model)
- [Services](/.github/copilot-instructions.md#services)
- [Task and issue requirements](/.github/copilot-instructions.md#taskissue-requirements)

For the canonical mutation-command shape, also load `.ai/skills/operation-pattern/SKILL.md`.
For all view and component work in `app/views/` or `app/components/`, load `.ai/skills/phlex-view-pattern/SKILL.md` — it is the primary source of frontend structure guidelines.

## Reference Map

- **[references/architecture-overview.md](references/architecture-overview.md)**
  Use for layer responsibilities and high-level composition guidance.
- **[references/operations.md](references/operations.md)**
  Use for write-flow patterns with `Core::Operation` and `Dry::Monads`.
- **[references/contracts.md](references/contracts.md)**
  Use for dry-validation contract structure and examples.
- **[references/controllers.md](references/controllers.md)**
  Use for thin controller patterns and operation orchestration.
- **[references/queries.md](references/queries.md)**
  Use for query-object structure and read-model boundaries.
- **[references/services.md](references/services.md)**
  Use for focused domain service patterns.
- **[references/jobs.md](references/jobs.md)**
  Use for background job orchestration around operations.
- **[references/models.md](references/models.md)**
  Use for persistence-only model guidance.
- **[references/deployment.md](references/deployment.md)**
  Use for deployment considerations that affect architecture decisions.
- **[references/WRITEBOOK_IMPLEMENTATION_SUMMARY.md](references/WRITEBOOK_IMPLEMENTATION_SUMMARY.md)**
  Use as a larger end-to-end implementation example when you need a concrete slice of the architecture in practice.
- **[references/session-learnings-mutation-flows.md](references/session-learnings-mutation-flows.md)**
  Use for compact, recent decisions on mutation operation shape, validation boundaries, and update-flow anti-patterns.
- **[references/host-coupled-engine-pattern.md](references/host-coupled-engine-pattern.md)**
  Use for host-app/engine ownership boundaries, mounted subdomain routing, shared-session expectations, and host-driven engine test execution.

Example: custom collection actions can support Turbo Frames when they describe a domain subset. See:
- [Turbo Frames](/.github/copilot-instructions.md#-turbo-frames)
## Operations Flow (typical)
1. Authorize at the controller boundary (Pundit)
2. Validate and sanitize with dry-validation contract
3. Build model and enforce business rules in the operation
4. Persist model and rely on ActiveRecord state validations
5. Return `Success(payload)` or `Failure(model: ...)` for form rerender paths

## For Verification & Requirements

See [copilot-instructions.md](/.github/copilot-instructions.md#-architecture--organization) for complete requirements.

> **Controller Concerns and Common Development Patterns:** adding pages, components, frames, Stimulus → [references/common-development-patterns.md](references/common-development-patterns.md)

