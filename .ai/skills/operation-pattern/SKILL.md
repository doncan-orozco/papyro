---
name: operation-pattern
description: "Golden archetype for write Operations and Contracts. Use when creating, editing or reviewing files in `app/concepts/*/operation/` or `app/concepts/*/contract/`: single-intent commands, explicit dependencies, transactions, `Core::Operation` result payloads, failure codes, and layered validation (dry-validation + ActiveModel errors)."
---

# Golden Operation Skill (Papyro)

Use this skill whenever you create, edit, or review a mutation flow in `app/concepts/*/operation/`.

This skill complements:
- `.ai/skills/controller/SKILL.md` for the HTTP boundary
- `references/layered-validation.md` for contract layering
- `.ai/skills/controller/references/error-handling.md` for controller/result integration

Reference examples:
- `references/canonical-examples.md` for compact create, update, article state-command, and translation state-command shapes

## Quick Rules

Cite as `operation-pattern R<n>`. Detail and examples follow below / in references/.

R1. **One intent per Operation.** One class per domain intent; no `action:`/`mode:` switching; a controller action never calls two sibling operations for one user action. → detail: RULE 1
R2. **Repository result contract.** `call` returns a plain payload hash on success; failures use `Failure(...)` via `inject_errors!`/`fail_with_model!`/`fail_with_code!`. → detail: RULE 2
R3. **Failure payload shape.** Failure includes `:code` when callers route outcomes and `:model` when a form may re-render. → detail: RULE 2
R4. **No hidden dependencies.** Pass `user:`, `locale:`, `settings_params:` etc. explicitly; never read `params`, `session` or `Current` inside an Operation. → detail: RULE 3
R5. **Layered responsibility.** Contracts validate shape/coercion/format; Operations own workflow and business rules; Models enforce persistence constraints. → detail: RULE 4
R6. **Transactions for multi-write only.** Wrap multiple writes (or metadata + state transition) in one transaction; never wrap a single save/update/destroy. → detail: references/transactions.md
R7. **Explicit locale.** Operations mutating translated attributes accept `locale:` in the `call` signature. → detail: RULE 6
R8. **Stable failure codes.** Controllers branch on `failure[:code]` (e.g. `:already_published`, `:trashed`, `:invalid`), not model internals. → detail: RULE 7
R9. **No boundary concerns.** No authorization/policy checks, rendering, redirects, flash or Turbo markup inside Operations. → detail: What Operations Are For
R10. **No query-only composition.** Operations do not compose read-only queries; reads belong in Query Objects. → detail: What Operations Are For

## What Operations Are For

Operations are the single entry point for domain writes. Their job is to:
- Orchestrate one domain intent per class.
- Enforce business rules and state transitions.
- Coordinate contracts, models, and side effects.
- Return stable result payloads the controller can route on.

Operations are NOT for:
- Authorization or policy checks.
- Query-only read composition.
- Rendering, redirects, flash messages, or Turbo markup.
- Pulling hidden state from `params`, `session`, or `Current`.

## RULE 1: One Operation Per Domain Intent

Prefer one operation per command:
- `Publish`
- `Unpublish`
- `Restore`

Avoid `action:` or `mode:` switching inside a single write operation when the user intent is materially different.

If one controller action represents one user intent but needs multiple mutation steps, compose that workflow inside one higher-level operation. Do not make the controller call two sibling operations just to finish one button click.

## RULE 2: Use the Repository Result Contract

Papyro uses `Core::Operation < Dry::Operation` with `Dry::Monads[:result]`.

Success shape:

```ruby
def call(model:)
  persisted_model = step persist(model)
  { model: persisted_model }
end
```

Failure shape:

```ruby
Failure(model: article, errors: article.errors.messages)
Failure(model: article, errors: article.errors.messages, code: :already_published)
Failure(model: article, errors: article.errors.messages, code: :trashed, message: "...")
```

Rules:
- `call` returns a plain payload hash on success. `Dry::Operation` wraps it.
- Use `Success(...)` and `Failure(...)` in internal step methods and helper methods.
- Include `:code` whenever the caller must route different failure outcomes.
- Include `:model` whenever the caller may need to re-render a form.
- Reuse `inject_errors!`, `fail_with_model!`, and `fail_with_code!` from `Core::Operation`.

## RULE 3: No Hidden Dependencies

Operations must be explicit about every dependency they need.

```ruby
# Good
Articles::Operation::Publish.new.call(
  model: article,
  settings_params: article_params,
  locale: content_locale
)
```

```ruby
# Forbidden
def call
  article = Current.user.articles.find(params[:id])
end
```

Pass `user:`, `locale:`, `settings_params:`, or any other input explicitly. Nested operations should receive the same explicit inputs rather than relying on ambient global state.

## RULE 4: Contracts Validate Structure, Operations Own Workflow

Keep the mutation boundary layered:
- Contracts validate input shape, coercion, and format.
- Operations orchestrate the workflow and business rules.
- Models enforce persistence-time constraints and state validity.

## RULE 5: Use Transactions for Multi-Write Workflows

Wrap multiple writes (or metadata update + state transition) in one transaction so partial updates cannot leak; never wrap a single `save`/`update`/`destroy`. Patterns and examples: [references/transactions.md](references/transactions.md).

## RULE 6: Locale Must Be Explicit

When an operation mutates translated attributes, accept `locale:` explicitly.

```ruby
def call(model:, params:, locale:)
  Mobility.with_locale(locale) do
    persisted_model = step persist(model: model, params: params)
    { model: persisted_model }
  end
end
```

The caller may already wrap the operation in `Mobility.with_locale`, but the operation signature must still expose `locale:` so nested writes and helper steps stay explicit and testable.

## RULE 7: Return Failure Codes the Controller Can Route On

Controllers should not infer business state from model internals. They should branch on stable failure codes.

Good examples:
- `:already_published`
- `:trashed`
- `:invalid`

If a command intentionally persists metadata while refusing a state transition, return the saved model with a specific failure code so the controller can route correctly without re-deriving the business rule.

## Gold Standard Mutation Shape

Full annotated operation: [references/gold-standard-shape.md](references/gold-standard-shape.md). Contract/validation layering: [references/layered-validation.md](references/layered-validation.md). More examples: [references/canonical-examples.md](references/canonical-examples.md).

## Review Checklist

- Does this operation represent one domain intent?
- Are all dependencies explicit in the method signature?
- Is structural validation delegated to a contract where appropriate?
- If multiple writes happen, is the workflow transactional?
- Does failure return a stable payload with the right `:code` and/or `:model`?
- Can the controller stay dumb and route purely on success/failure outcome?