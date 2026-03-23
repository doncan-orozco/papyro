---
name: error-handling
description: Error handling, result patterns, and authorization patterns with Trailblazer Operations. Use when implementing controllers calling Operations, handling success/failure results, implementing authorization, or managing result extraction. Covers controller-operation interaction, authorization patterns, and common error scenarios.
---

# Error Handling & Result Patterns

## Calling Operations from Controllers

### Key Principle: Controller Authorizes → Operation Executes

**Controllers are responsible for:**
1. Authorization (before calling Operation)
2. Loading pre-authorized resources with scoped queries
3. Passing authorized resources to Operations

**Operations are responsible for:**
1. Business logic execution
2. Validation
3. Persistence

---

### Pattern 1: Create Operations (No Existing Model)

Pass params only, including ownership field:

```ruby
# Controller
def create
  result = Articles::Operation::Create.call(
    params: article_params.to_h.merge(user_id: Current.user.id)  # Set owner on create
  )
  
  if result.success?
    redirect_to articles_path, notice: I18n.t("articles.operations.create.success")
  else
    @article = result[:model] || Article.new(article_params)
    @errors = result[:errors]
    render :new, status: :unprocessable_entity
  end
end
```

### Pattern 2: Update/Destroy Operations (Existing Model)

**✅ CORRECT: Pass pre-authorized model**

```ruby
# Controller
def update
  # 1. Authorize: find with scope
  article = Current.user.articles.find_by!(id: params[:id])
  
  # 2. Call Operation with pre-authorized model
  result = Articles::Operation::Update.call(
    model: article,  # Pass the authorized model
    params: article_params.to_h  # NO user_id - ownership doesn't change
  )
  
  if result.success?
    redirect_to articles_path, notice: I18n.t("articles.operations.update.success")
  else
    @article = result[:model]
    @errors = result[:errors]
    render :edit, status: :unprocessable_entity
  end
rescue ActiveRecord::RecordNotFound
  redirect_to articles_path, alert: I18n.t("articles.errors.not_found")
end

def destroy
  # 1. Authorize with scope
  article = Current.user.articles.find_by!(id: params[:id])
  
  # 2. Pass pre-authorized model
  result = Articles::Operation::Destroy.call(model: article)
  
  if result.success?
    redirect_to articles_path, notice: I18n.t("articles.operations.destroy.success"), status: :see_other
  else
    redirect_to articles_path, alert: I18n.t("articles.operations.destroy.failure"), status: :see_other
  end
rescue ActiveRecord::RecordNotFound
  redirect_to articles_path, alert: I18n.t("articles.errors.not_found"), status: :see_other
end
```

**Operation receives pre-authorized model:**

```ruby
module Articles
  module Operation
    class Update < Trailblazer::Operation
      step :validate_input
      step :update_article
      
      # NO find_article step - model already provided and authorized
      
      def validate_input(ctx, params:, **)
        contract = Articles::Contract::Update.new
        result = contract.call(params)
        
        if result.success?
          ctx[:validated_params] = result.to_h
          true
        else
          ctx[:errors] = result.errors.to_h
          false
        end
      end
      
      def update_article(ctx, model:, validated_params:, **)
        # Model is pre-authorized by controller
        # Do NOT update ownership fields
        if model.update(validated_params.except(:id, :user_id))
          ctx[:model] = model
          true
        else
          ctx[:errors] = model.errors.to_hash
          false
        end
      end
    end
  end
end
```

---

### Why This Pattern?

**Benefits:**
- ✅ **Single DB query**: Controller finds once with authorization scope
- ✅ **Clear separation**: Controller authorizes, Operation executes business logic
- ✅ **Security**: Operation can't bypass authorization by using unscoped queries
- ✅ **Testability**: Operations test business logic, controllers test authorization
- ✅ **Performance**: No duplicate queries

**❌ WRONG: Finding in both controller and operation**
```ruby
# Controller
article = Current.user.articles.find_by!(id: params[:id])  # Query #1 WITH scope
result = Articles::Operation::Update.call(params: { id: article.id })  # Pass ID

# Operation
def find_article(ctx, params:, **)
  article = ::Article.find_by(id: params[:id])  # Query #2 WITHOUT scope - SECURITY RISK!
  ctx[:model] = article
end
```

**Problems:**
- 🔴 Two DB queries
- 🔴 Operation bypasses authorization scope
- 🔴 Can access resources user doesn't own

---

### Pattern 3: Operations Without Authorization (Background Jobs)

For background jobs, pass IDs (not objects) because jobs are serialized to a queue:

```ruby
# Controller/Operation that enqueues job
ArticlePublishJob.perform_later(article.id)  # Pass ID, not object

# Job
class ArticlePublishJob < ApplicationJob
  def perform(article_id)
    article = Article.find(article_id)  # Re-fetch in job context
    # ... business logic
  end
end
```

**Why pass IDs to jobs?**
- Jobs are serialized to a background queue
- State might change between enqueue and execution
- Cross-process communication requires serializable data

---

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
    

    if result.success?
      redirect_to article_path(result[:model]), notice: t("articles.operations.publish.success")
    else
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

**Note:** Trailblazer Operations return `Trailblazer::Operation::Result` objects (not Dry::Monads). Use `result.success?` / `result.failure?` methods.

```ruby
# Pattern 1: Simple redirect on success, render on failure
def create
  result = Articles::Operation::Create.call(params: article_params)

  if result.success?
    redirect_to article_path(result[:model]), notice: t("articles.operations.create.success")
  else
    @article = result[:model] || Article.new(article_params)
    @errors = result[:errors]
    flash.now[:alert] = format_errors(@errors)
    render :new, status: :unprocessable_entity
  end
end

# Pattern 2: Turbo Stream response
def create
  result = Articles::Operation::Create.call(params: article_params)

  if result.success?
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to article_path(result[:model]) }
    end
  else
    @errors = result[:errors]
    flash.now[:alert] = format_errors(@errors)
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
    
    if result.success?
      # Operation already broadcast; do nothing
    else
      error_key = result[:error_key] || :unknown_error
      transmit({ type: 'error', message: I18n.t("errors.game.#{error_key}", fallback: "An error occurred") })
    end
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
    
    if result.success?
      logger.info "Stats regenerated for player #{player_id}"
    else
      error_key = result[:error_key]
      
      case error_key
      when :not_found
        logger.warn "Player #{player_id} not found, skipping regeneration"
      when :player_dead
        logger.info "Player #{player_id} is dead, skipping stats"
      when :server_error
        logger.error "Server error regenerating stats: #{result[:error]}"
        raise result[:error] # Let Solid Queue retry
      else
        logger.error "Unknown error regenerating stats for player #{player_id}"
      end
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
  
  if result.success?
    redirect_to articles_path, notice: t("articles.operations.create_and_publish.success")
  else
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
