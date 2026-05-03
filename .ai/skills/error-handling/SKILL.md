---
name: error-handling
description: Error handling, result patterns, and authorization patterns with dry-rb operations. Use when implementing controllers calling operations, handling success/failure monads, implementing authorization, or managing payload extraction. Covers controller-operation interaction, authorization patterns, and common error scenarios.
---

# Error Handling & Result Patterns (dry-rb)

## Calling Operations from Controllers

### Key Principle: Controller Authorizes -> Operation Executes

Controllers are responsible for:
1. Authorization before calling operations
2. Loading pre-authorized resources with scoped queries
3. Passing authorized models/params to operations

Operations are responsible for:
1. Validation and business rules
2. Persistence and side effects
3. Returning `Dry::Monads::Result` payloads

## Pattern 1: Create Operations

```ruby
def create
  authorize Article, policy_class: Studio::ArticlePolicy

  result = Articles::Operation::Create.new.call(
    params: article_params.to_h,
    user: Current.user
  )

  if result.success?
    redirect_to studio_articles_path, notice: t("studio.articles.operations.create.success")
  else
    article = result.failure[:model] || Article.new(article_params)
    render Views::Studio::Articles::New.new(article: article), status: :unprocessable_entity
  end
end
```

Create-operation guidance:
- In operations inheriting from `Dry::Operation`, return a plain payload hash from `call` (for example `{ model: user }`).
- For contract failures, hydrate a model for re-render with permitted typed inputs, but exclude passwords from reassignment.
- Prefer model-driven nested assignment (`assign_attributes`) when the model is configured with nested attributes.

## Pattern 2: Update/Destroy Operations

```ruby
def update
  article = policy_scope(Article).find(params[:id])
  authorize article, policy_class: Studio::ArticlePolicy

  result = Articles::Operation::Update.new.call(model: article, params: article_params.to_h)

  if result.success?
    redirect_to studio_articles_path, notice: t("studio.articles.operations.update.success")
  else
    render Views::Studio::Articles::Edit.new(article: result.failure[:model] || article), status: :unprocessable_entity
  end
end

def destroy
  article = policy_scope(Article).find(params[:id])
  authorize article, policy_class: Studio::ArticlePolicy

  result = Articles::Operation::Destroy.new.call(model: article)

  if result.success?
    redirect_to studio_articles_path, notice: t("studio.articles.operations.destroy.success"), status: :see_other
  else
    redirect_to studio_articles_path, alert: t("studio.articles.operations.destroy.failure"), status: :see_other
  end
end
```

## Result Extraction Patterns

Use `Dry::Monads::Result` payload access explicitly:

```ruby
result = Users::Operation::Update.new.call(params: user_params, user: user)

if result.success?
  updated_user = result.value![:model]
else
  errors = result.failure[:errors]
end
```

Rules:
- Never use transition shims like `result[:model]`
- Prefer `result.value!` only inside success branches
- Use `result.failure` only inside failure branches

## Operation Payload Contract

Keep payload keys consistent across operations.

Success payloads commonly include:
- `:model`

Failure payloads commonly include:
- `:errors`
- `:model`

For operations inheriting from `Dry::Operation`, `call` should return a plain payload hash (for example `{ model: user }`) and let `Dry::Operation` perform the outer monad wrapping.

## Channels and Jobs

### Channels

```ruby
def publish(data)
  article = policy_scope(Article).find(data.fetch("id"))
  authorize article, policy_class: Studio::PublicationPolicy

  result = Articles::Operation::Publish.new.call(model: article)
  return if result.success?

  transmit(type: "error", errors: result.failure[:errors])
end

def unpublish(data)
  article = policy_scope(Article).find(data.fetch("id"))
  authorize article, policy_class: Studio::PublicationPolicy

  result = Articles::Operation::Unpublish.new.call(model: article)
  return if result.success?

  transmit(type: "error", errors: result.failure[:errors])
end
```

### Jobs

```ruby
def perform
  result = Maintenance::ConsumeResources.new.call
  return if result.success?

  message = Array(result.failure.dig(:errors, :base)).compact.join(", ")
  raise ConsumeResourcesFailed, (message.presence || "consume resources failed")
end
```

## Anti-Patterns

- Authorization inside operations
- Unscoped model lookups in operations
- Returning booleans instead of Result monads
- Mixing success/failure payload shapes per operation step
- Accessing success payload in failure branch and vice versa

## Summary

Use dry-rb operations with explicit Result payloads, keep authorization in controllers, and keep failure handling deterministic and shape-stable.
