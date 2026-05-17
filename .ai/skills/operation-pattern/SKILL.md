---
name: operation-pattern
description: Golden archetype for write Operations in Papyro. Use when implementing, refactoring, or reviewing files in `app/concepts/*/operation/`. Covers single-intent mutation commands, explicit dependencies, multi-write transactions, `ApplicationOperation` result payloads, failure-code routing, and locale-aware persistence.
---

# Golden Operation Skill (Papyro)

Use this skill whenever you create, edit, or review a mutation flow in `app/concepts/*/operation/`.

This skill complements:
- `.ai/skills/controller/SKILL.md` for the HTTP boundary
- `.ai/skills/layered-validation-operation-pattern/SKILL.md` for contract layering
- `.ai/skills/error-handling/SKILL.md` for controller/result integration

Reference examples:
- `references/canonical-examples.md` for compact create, update, article state-command, and translation state-command shapes

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

Papyro uses `ApplicationOperation < Dry::Operation` with `Dry::Monads[:result]`.

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
- Reuse `inject_errors!`, `fail_with_model!`, and `fail_with_code!` from `ApplicationOperation`.

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

If an operation performs more than one write, or if a partial write would leave the domain in an invalid split state, wrap the workflow in a transaction.

Typical triggers:
- update settings + publish state in one command
- save a model + save a related translation
- persist a record + enqueue durable side effects that depend on that write

Canonical pattern:

```ruby
def call(model:, settings_params: {}, locale: I18n.locale)
  persisted_model = step publish_with_optional_settings(
    model: model,
    settings_params: settings_params,
    locale: locale
  )

  { model: persisted_model }
end

def publish_with_optional_settings(model:, settings_params:, locale:)
  transaction_failure = nil
  preserved_failure = nil

  persisted_model = Mobility.with_locale(locale) do
    ActiveRecord::Base.transaction do
      prepared_model = if settings_params.present?
        result = apply_settings(model: model, settings_params: settings_params, locale: locale)
        unless result.success?
          transaction_failure = result
          raise ActiveRecord::Rollback
        end

        result.value!
      else
        model
      end

      publishable_model = validate_publishable(prepared_model)
      unless publishable_model.success?
        if publishable_model.failure[:code] == :already_published
          preserved_failure = publishable_model
          prepared_model
        else
          transaction_failure = publishable_model
          raise ActiveRecord::Rollback
        end
      else
        persisted_model = persist_publish_state(publishable_model.value!)
        unless persisted_model.success?
          transaction_failure = persisted_model
          raise ActiveRecord::Rollback
        end

        persisted_model.value!
      end
    end
  end

  return transaction_failure if transaction_failure
  return preserved_failure if preserved_failure

  Success(persisted_model)
end
```

If there is only one `save`, rely on the transaction Active Record already wraps around that single persistence call.
Use the `preserved_failure` branch only when the business rule explicitly allows metadata changes to persist while rejecting the state transition. All other failures should roll back.

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

```ruby
module Articles
  module Operation
    class Publish < ApplicationOperation
      def call(model:, settings_params: {}, locale: I18n.locale)
        persisted_model = step publish_with_optional_settings(
          model: model,
          settings_params: settings_params,
          locale: locale
        )

        { model: persisted_model }
      end

      private

      def publish_with_optional_settings(model:, settings_params:, locale:)
        transaction_failure = nil
        preserved_failure = nil

        persisted_model = Mobility.with_locale(locale) do
          ActiveRecord::Base.transaction do
            prepared_model = if settings_params.present?
              result = apply_settings(model: model, settings_params: settings_params, locale: locale)
              unless result.success?
                transaction_failure = result
                raise ActiveRecord::Rollback
              end

              result.value!
            else
              model
            end

            publishable_model = validate_publishable(prepared_model)
            unless publishable_model.success?
              if publishable_model.failure[:code] == :already_published
                preserved_failure = publishable_model
                prepared_model
              else
                transaction_failure = publishable_model
                raise ActiveRecord::Rollback
              end
            else
              persisted_model = persist_publish_state(publishable_model.value!)
              unless persisted_model.success?
                transaction_failure = persisted_model
                raise ActiveRecord::Rollback
              end

              persisted_model.value!
            end
          end
        end

        return transaction_failure if transaction_failure
        return preserved_failure if preserved_failure

        Success(persisted_model)
      end

      def apply_settings(model:, settings_params:, locale:)
        return Success(model) if settings_params.blank?

        result = Articles::Operation::Update.new.call(
          model: model,
          params: settings_params,
          locale: locale
        )

        return Success(result.value![:model]) if result.success?

        result
      end

      def validate_publishable(model)
        return fail_with_code!(model, :trashed, message: I18n.t("studio.articles.operations.update.trashed")) if model.trashed?
        return fail_with_code!(model, :already_published, message: I18n.t("errors.messages.article_already_published")) if model.published?

        Success(model)
      end

      def persist_publish_state(model)
        model.published_at ||= Time.current
        return Success(model) if model.save

        fail_with_model!(model)
      end
    end
  end
end
```

## Review Checklist

- Does this operation represent one domain intent?
- Are all dependencies explicit in the method signature?
- Is structural validation delegated to a contract where appropriate?
- If multiple writes happen, is the workflow transactional?
- Does failure return a stable payload with the right `:code` and/or `:model`?
- Can the controller stay dumb and route purely on success/failure outcome?