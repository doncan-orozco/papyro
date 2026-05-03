---
name: layered-validation-operation-pattern
description: Standardize mutation flows using Dry::Validation contracts for structural validation, Operations for orchestration, and ActiveModel for seamless UI error rendering.
---

# Application Mutation Pattern (Layered Validation)

## When to Use
- Any `create`, `update`, or complex state mutation initiated by a user.
- Endpoints requiring strict type coercion, sanitization, and format validation.
- Workflows where business rules and database constraints must be strictly separated.

## Responsibilities & Boundaries: Contract vs. Model
To keep the application Domain-Driven and resilient, validation is split into strict layers. It is critical to understand the difference between validating *input* and validating *state*.

1. **Authorization (Pundit):** "Are you allowed to do this?" Halts execution via exceptions at the Controller level.
2. **Structural Input Validation (Dry::Validation Contract):** "Is the data you gave me structurally sound?" Verifies types, required keys, string formats, and applies sanitization (like stripping whitespace). **Contracts do not touch the database.**
3. **Orchestration (Operation):** Runs the contract, checks global business rules, and maps any failures to an ActiveModel for the UI.
4. **Record State Validation (ActiveRecord Model):** "Does this data safely reflect business reality and database constraints?" Verifies uniqueness, foreign key integrity, and state machine transitions right before persistence.

---

## MANDATORY RULE: Graceful Failures via Monads

**Operations MUST never raise exceptions for expected validation or business logic failures.**

If a user submits an invalid slug or violates a business rule, the operation must return a `Dry::Monads` `Failure`. Exceptions are reserved strictly for unexpected system crashes or authorization breaches (handled by Pundit).

---

## MANDATORY RULE: The Rails Pragmatic Return Shape

**Operations MUST always return an ActiveModel instance in a Failure tuple when a form re-render is expected.**

To maintain compatibility with standard Rails form builders (`form_with`, `ActionView` helpers), do not return raw `dry-validation` error hashes to the controller. The Operation must intercept contract errors, instantiate an unpersisted database model, inject the errors onto that model, and return it.

---

## 1. The Base Operation Setup

All operations must inherit from an `ApplicationOperation` base class that provides the `inject_errors!` helper.

```ruby
# app/operations/application_operation.rb
class ApplicationOperation < Dry::Operation
  include Dry::Monads[:result]

  private

  def model_errors(model)
    model.errors.messages
  end

  # Cleanly injects a hash of errors (like from a Contract) into an ActiveModel
  def inject_errors!(model, errors_hash)
    errors_hash.each do |field, messages|
      Array(messages).each do |message|
        model.errors.add(field, message)
      end
    end
    
    model
  end

  # Helper to instantly fail with a global business logic error
  def fail_with_business_error!(model, message)
    model.errors.add(:base, message)
    fail_with_model!(model)
  end

  def fail_with_model!(model)
    Failure(model: model, errors: model_errors(model))
  end
end
```

---

## 2. Defining Custom Types for Sanitization

Instead of manually sanitizing parameters inside the Operation, use `dry-types` to automatically coerce and sanitize inputs during the Contract's schema evaluation phase.

Define reusable custom types in a centralized module:

```ruby
# app/lib/types.rb
require "dry-types"

module Types
  include Dry.Types()

  # Automatically strips leading/trailing whitespace
  StrippedString = Types::String.constructor(&:strip)
  
  # Automatically strips whitespace and downcases the string
  NormalizedSlug = Types::String.constructor { |value| value.to_s.strip.downcase }
end
```

---

## 3. Defining the Contract (Input Validation)

Contracts live in a `Contract` namespace within your domain. They are strictly for type checking, presence, sanitization, and formatting. **Do not query the database (e.g., `Article.exists?`) inside a contract.**

By passing your custom `Types` into the `params` block, the data is automatically sanitized before the custom `rule` blocks evaluate it, and the sanitized data is returned in the final `contract.to_h`.

```ruby
# app/contracts/articles/contract/create.rb
module Articles
  module Contract
    class Create < Dry::Validation::Contract
      STATUSES = %w[draft published archived].freeze
      SLUG_FORMAT = /\A[a-z0-9-]+\z/

      params do
        # Inputs are stripped and downcased instantly
        required(:title).filled(Types::StrippedString)
        required(:slug).filled(Types::NormalizedSlug)
        required(:status).filled(Types::StrippedString)
        optional(:body).maybe(:string)
      end

      # Rules only run if the params block succeeded
      rule(:title) do
        key.failure(I18n.t("dry_schema.errors.max_size?", num: 255)) if value && value.length > 255
      end

      rule(:slug) do
        if value && value !~ SLUG_FORMAT
          key.failure(I18n.t("articles.forms.validation.slug_invalid_format"))
        end
      end
      
      rule(:status) do
        key.failure(I18n.t("articles.forms.validation.status_invalid")) if value && !STATUSES.include?(value)
      end
    end
  end
end
```

---

## 4. The Operation Implementation

Operations orchestrate the flow using the `step` syntax. Notice that the manual `sanitize_params` method is gone, because the Contract handles it.

```ruby
# app/operations/articles/operation/create.rb
module Articles
  module Operation
    class Create < ApplicationOperation
      def call(params:)
        validated_attributes = step validate_input(params)
        model = step build_and_check_business_rules(validated_attributes)
        
        persisted_article = step persist_article(model)

        { model: persisted_article }
      end

      private

      def validate_input(params)
        contract = Articles::Contract::Create.new.call(params)
        
        if contract.failure?
          # 1. Build the dummy model (does not hit the DB)
          article = Article.new(params)
          # 2. Inject the dry-validation errors using the Base class helper
          invalid_article = inject_errors!(article, contract.errors.to_h)
          # 3. Return the Failure with the populated model
          return Failure(model: invalid_article) 
        end

        # contract.to_h contains the cleanly sanitized and coerced data
        Success(contract.to_h)
      end

      def build_and_check_business_rules(attributes)
        article = Article.new(attributes)
        
        # Example: Enforce a global domain rule not tied to a specific attribute
        if Current.user.daily_articles_count > 5
          return fail_with_business_error!(article, I18n.t("articles.errors.daily_limit_reached"))
        end

        Success(article)
      end

      def persist_article(article)
        # ActiveRecord runs state validations (like uniqueness checks) here
        return Success(article) if article.save

        # If DB validation fails, the model already holds the AR errors natively
        fail_with_model!(article)
      end
    end
  end
end
```

---

## 5. The Controller Caller Contract

Controllers remain completely agnostic to *why* the operation failed. They rely on Pundit for authorization and the Operation for everything else.

```ruby
# app/controllers/studio/articles_controller.rb
class Studio::ArticlesController < Studio::BaseController
  def create
    # 1. Authorization: Halts execution if unauthorized
    authorize Article, policy_class: Studio::ArticlePolicy
    
    # 2. Orchestration: Hand off to the pure operation
    result = Articles::Operation::Create.new.call(
      params: article_params.to_h,
      user: Current.user
    )

    # 3. Routing: Handle the Monad outcome
    if result.success?
      redirect_to studio_articles_path, notice: t("studio.articles.operations.create.success")
    else
      # Failure[:model] guarantees an ActiveModel with fully unified errors 
      # (from Contract, Business Rules, or ActiveRecord)
      render Views::Studio::Articles::New.new(article: result.failure[:model]), status: :unprocessable_entity
    end
  end
end
```

---
## 6. The Gold Standard Operation (Canonical Template)

Use this as the default shape for create and complex mutation operations.

```ruby
module Articles
  module Operation
    class Create < ApplicationOperation
      def call(params:, user:)
        attributes = step validate_input(params)
        model = step build_and_enforce_domain_rules(attributes, user)
        persisted_model = step persist_with_transaction(model)

        # Add this step only when real async side effects exist.
        # step enqueue_background_jobs(persisted_model)

        { model: persisted_model }
      end

      private

      def validate_input(params)
        contract = Articles::Contract::Create.new.call(params)
        return Success(contract.to_h) if contract.success?

        article = Article.new(params)
        fail_with_model!(inject_errors!(article, contract.errors.to_h))
      end

      def build_and_enforce_domain_rules(attributes, user)
        article = user.articles.build(attributes)

        if user.restricted_from_publishing?
          return fail_with_business_error!(article, I18n.t("articles.errors.user_restricted"))
        end

        Success(article)
      end

      def persist_with_transaction(article)
        persisted_article = nil

        Article.transaction do
          if article.save
            persisted_article = article
          else
            raise ActiveRecord::Rollback
          end
        end

        return Success(persisted_article) if persisted_article

        fail_with_model!(article)
      end
    end
  end
end
```

### Gold Standard Rules

1. `call` reads as a table of contents for the write flow.
2. Every pipeline step returns `Success(...)` or `Failure(...)` only.
3. Contract errors must be injected into an ActiveModel and returned as `Failure(model: ..., errors: ...)`.
4. Persistence must return deterministic monads; no boolean returns and no silent nil fallthrough.
5. Add a side-effects step only when the operation actually has asynchronous side effects.
6. When inheriting from `Dry::Operation`, `call` must return a plain payload hash, not `Success(...)`, to avoid double-wrapped monads (`Success(Success(payload))`).
7. Update contracts should accept partial payloads with optional keys; do not use `prepare_defaults` to backfill missing values before contract validation.
8. Avoid form objects for simple CRUD updates that can be handled by contract validation + `assign_attributes` + model validations.

---
## 7. Contract Validations vs. Model Validations

You are completely correct that these are two distinct mechanisms. They serve different purposes and live at different layers of your app.

The Contract (The Boundary Guard): "Is this input structurally sound?"

Checks types (Is user_id an integer? Is published_at a datetime?).

Checks presence and required keys.

Strips whitespace and coerces strings.

Goal: Protect the Operation from ever executing with garbage data.

The Model (The State Guard): "Does this data safely reflect business reality and database constraints?"

Checks uniqueness (e.g., "Does this slug already exist in the DB?").

Checks complex state transitions (e.g., "You cannot publish an article if the author is suspended").

Goal: Protect the Database from corruption.

---

## Error Handling Guidance

- **Attribute Typos / Bad Formats:** Handled by the Contract. Re-renders the form with red text under the specific input field.
- **Cross-field Logic or Domain Constraints:** Handled by the Operation logic. Assign to `:base` using `fail_with_business_error!`. Renders at the top of the form.
- **Database Uniqueness / Race Conditions:** Handled by ActiveRecord during the `.save` step. Re-renders the form with red text under the specific input field.
- **Authorization / Permissions:** Handled by Pundit in the Controller. Raises `Pundit::NotAuthorizedError` and redirects the user away from the form entirely.
