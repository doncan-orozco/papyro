# Backend Anti-Patterns: Domain Logic

## Models

Models are for persistence and associations.

Avoid:
- business rules in model instance methods
- Active Record validations as the primary validation layer
- callbacks for write orchestration
- scopes that hide read logic in the model layer

Prefer:
- contracts for validation
- operations for writes and side effects
- query objects for reads

```ruby
# BAD
class Article < ApplicationRecord
  validates :title, presence: true
  before_save :publish_if_ready
  scope :published, -> { where(status: :published) }
end

# GOOD
class Article < ApplicationRecord
  belongs_to :user
  enum :status, { draft: 0, published: 1, archived: 2 }
end
```

## Operations

Avoid:
- doing the same lookup in the controller and the operation
- authorization checks inside operations
- changing ownership fields in update operations
- hardcoded error strings returned directly from operations
- passing AR objects into background jobs
- update flows that require `prepare_defaults` just to satisfy contract required fields
- form-object orchestration for simple CRUD updates that can be handled by contract + model
- wrapping the final `call` return in `Success(...)` when inheriting from `Dry::Operation`
- database/state checks in contracts (uniqueness, ownership, cross-record constraints)

Prefer:
- controllers authorizing and passing `model:` into update/destroy operations
- contracts returning validation errors as structured hashes
- jobs receiving scalar identifiers and reloading state in the job context

```ruby
# BAD
article = Current.user.articles.find(params[:id])
result = Articles::Operation::Update.new.call(params: { id: article.id, user_id: params[:user_id] })

# GOOD
article = policy_scope(Article).find(params[:id])
authorize article
result = Articles::Operation::Update.new.call(model: article, params: article_params.to_h)
```

## Services

Avoid implicit global dependencies.

```ruby
# BAD
class PublishArticle
  def call(article)
    Rails.cache.delete("articles")
    NotificationJob.perform_later(article.id)
  end
end
```

Prefer explicit collaborators or keep the side effects as named operation steps.

## Controllers

Controllers should only orchestrate request-level concerns.

Avoid:
- reading undocumented internal operation data
- mixing response formatting with domain logic
- mutating operation payloads in the controller

Prefer:
- `result.success?` / `result.failure?`
- `result.value![:model]` only in success branches
- `result.failure[:errors]` only in failure branches

```ruby
if result.success?
  redirect_to article_path(result.value![:model])
else
  flash.now[:alert] = format_errors(result.failure[:errors])
  render :new, status: :unprocessable_entity
end
```

## Security

Authorization belongs at the controller, channel, or policy boundary.

Avoid:
- admin checks inside operations
- unscoped `find` calls after a scoped controller lookup already happened

Prefer:
- `policy_scope(...).find(...)`
- `authorize record`
- passing pre-authorized models to the operation
