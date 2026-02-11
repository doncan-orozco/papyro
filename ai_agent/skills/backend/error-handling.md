# Error Handling & Result Patterns

**Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md#-architecture--organization)**

This skill covers error handling, result extraction, and authorization patterns for Papyro.

## Authorization Patterns

**Key Principle: Authorization happens at controller level**, BEFORE calling Operations.

### Controller Authorization
```ruby
class ArticlesController < ApplicationController
  before_action :require_admin, only: [:publish, :destroy]
  
  def publish
    # Authorization already checked by before_action
    result = Articles::Operation::Publish.call(
      params: params.permit(:id, :action).to_h,
      current_user: Current.user
    )
    
    case result
    in Dry::Monads::Success
      redirect_to article_path(result[:model]), notice: t(".success")
    in Dry::Monads::Failure[*, **]
      flash.now[:alert] = format_errors(result[:errors])
      render :show, status: :unprocessable_entity
    end
  end
  
  private
  
  def require_admin
    raise Pundit::NotAuthorizedError unless Current.user&.admin?
  end
end
```

### Authorization Guidelines
- ✅ Check permissions in controller `before_action`
- ✅ Use pundit or simple scope checks
- ✅ Pass `current_user` to Operation for audit trail or user-scoped queries
- ❌ Operations do NOT enforce authorization (controllers do)
- ✅ Document in tests which operations require authorization

## Error Handling Patterns

### Controllers Handling Operation Failures

```ruby
# Pattern 1: Simple redirect on success, render on failure
def create
  result = Articles::Operation::Create.call(params: article_params)

  case result
  in Dry::Monads::Success
    redirect_to article_path(result[:model]), notice: t(".success")
  in Dry::Monads::Failure[*, **]
    flash.now[:alert] = format_errors(result[:errors])
    render :new, status: :unprocessable_entity
  end
end

# Pattern 2: Turbo Stream response
def create
  result = Articles::Operation::Create.call(params: article_params)

  case result
  in Dry::Monads::Success
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to article_path(result[:model]) }
    end
  in Dry::Monads::Failure[*, **]
    flash.now[:alert] = format_errors(result[:errors])
    render :new, status: :unprocessable_entity
  end
end

# Helper to format validation errors
private

def format_errors(errors)
  errors.map { |field, messages|
    "#{field.to_s.humanize}: #{Array(messages).join(', ')}"
  }.join("; ")
end
```

### Channels Handling Operation Failures

```ruby
class GameChannel < ApplicationCable::Channel
  def move(data)
    result = Game::Operation::MovePlayer.call(
      params: data.merge(game_id: params[:game_id]),
      current_user: current_user
    )
    
    case result
    in Dry::Monads::Success
      # Operation already broadcast; do nothing
    in Dry::Monads::Failure[:invalid_move, error:]
      transmit({ type: 'error', message: error })
    in Dry::Monads::Failure[key, data]
      transmit({ type: 'error', message: error_message(key, data) })
    end
  end
  
  private
  
  def error_message(key, data)
    I18n.t("errors.game.#{key}", fallback: "An error occurred")
  end
end
```

### Jobs Handling Operation Failures

```ruby
class RegeneratePlayerStatsJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound
  
  def perform(player_id)
    result = Game::Operation::RegenerateStats.call(
      params: { player_id: player_id }
    )
    
    case result
    in Dry::Monads::Success
      # Success path (idempotent)
      logger.info "Stats regenerated for player #{player_id}"
    in Dry::Monads::Failure[:not_found]
      # Non-retryable error - discard
      logger.warn "Player #{player_id} not found, skipping regeneration"
    in Dry::Monads::Failure[:player_dead]
      # Don't retry for dead players
      logger.info "Player #{player_id} is dead, skipping stats"
    in Dry::Monads::Failure[:server_error, error:]
      # Retryable error (default retry behavior)
      logger.error "Server error regenerating stats: #{error}"
      raise error # Let Solid Queue retry
    end
  end
end
```

## Result Extraction Patterns

### Getting the Main Model

```ruby
result = Articles::Operation::Create.call(params: params)

# Option 1: Safe extraction
if result.success?
  article = result[:model]
  # Use article
else
  errors = result[:errors]
  # Handle errors
end

# Option 2: One-liner (when you know it succeeded)
article = result.success? ? result[:model] : nil
```

### Getting Validation Errors

```ruby
result = Articles::Operation::Create.call(params: params)

if result.failure?
  errors = result[:errors]
  # errors = { title: ["can't be blank"], slug: ["is invalid"] }
  
  # Display specific field error
  title_errors = errors[:title]
  
  # Display all errors
  all_messages = errors.flat_map { |field, messages| Array(messages) }
end
```

### Accessing Context Keys

```ruby
result = Articles::Operation::Create.call(params: params)

# ✅ Documented public keys
model = result[:model]         # Main domain object
errors = result[:errors]       # Validation errors

# ❌ DON'T access internal keys
temp_data = result[:temp_calculation]  # WRONG - leaks Operation internals
```

**Rule:** Only access ctx keys explicitly documented by the Operation.

### Chaining Multiple Operations

```ruby
# Pattern: Sequential operations with early return on failure
def publish_and_notify
  # Operation 1: Create article
  result1 = Articles::Operation::Create.call(params: article_params)
  return result1 if result1.failure?
  
  article = result1[:model]
  
  # Operation 2: Publish article (using result1 data)
  result2 = Articles::Operation::Publish.call(
    params: { id: article.id },
    current_user: Current.user
  )
  return result2 if result2.failure?
  
  # Operation 3: Notify subscribers
  result3 = Articles::Operation::NotifySubscribers.call(
    params: { article_id: article.id }
  )
  
  result3 # Return final result
end

# Usage in controller
def create_and_publish
  result = publish_and_notify
  
  case result
  in Dry::Monads::Success
    redirect_to articles_path, notice: t(".success")
  in Dry::Monads::Failure[*, **]
    flash.now[:alert] = format_errors(result[:errors])
    render :new, status: :unprocessable_entity
  end
end
```

## Operation Context Guidelines

### Setting Errors in Operations

```ruby
class Articles::Operation::Create < Trailblazer::Operation
  step :validate_input
  step :create_article
  
  def validate_input(ctx, params:, **)
    contract = Articles::Contract::Create.new
    result = contract.call(params)
    
    if result.success?
      ctx[:validated_params] = result.to_h
      true
    else
      # ✅ Set errors as Hash with field keys
      ctx[:errors] = result.errors.to_h
      false
    end
  end
  
  def create_article(ctx, validated_params:, **)
    article = ::Article.new(validated_params)
    
    if article.save
      # ✅ Set model on success
      ctx[:model] = article
      true
    else
      # ✅ Set errors from model (if needed)
      ctx[:errors] = article.errors.to_hash
      false
    end
  end
end
```

### Required Context Keys

Every Operation should set:
- **`ctx[:model]`** - On success, the main domain object
- **`ctx[:errors]`** - On failure, Hash with field keys → message arrays

Optional context keys:
- **`ctx[:current_user]`** - For audit trail
- **`ctx[:broadcast_data]`** - For real-time updates
- Custom keys for specific Operations (document them!)

## Testing Error Handling

```ruby
# test/concepts/articles/operation/create_test.rb
class Articles::Operation::CreateTest < ActiveSupport::TestCase
  test "creates article with valid params" do
    result = Articles::Operation::Create.call(params: valid_params)
    
    assert_predicate result, :success?
    assert_instance_of Article, result[:model]
  end
  
  test "fails with invalid title" do
    result = Articles::Operation::Create.call(params: invalid_params)
    
    assert_predicate result, :failure?
    assert result[:errors].key?(:title)
    assert_includes result[:errors][:title], "can't be blank"
  end
  
  test "sets errors as Hash" do
    result = Articles::Operation::Create.call(params: invalid_params)
    
    assert_instance_of Hash, result[:errors]
  end
end
```
