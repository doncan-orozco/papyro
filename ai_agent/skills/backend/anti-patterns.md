# Anti-Patterns (What NOT to Do)

**Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md#-architecture--organization)**

This skill documents common mistakes and their correct alternatives for Papyro development.

## Model Anti-Patterns

### ❌ DON'T: Business Logic in Models

```ruby
# WRONG
class User < ApplicationRecord
  def send_welcome_email
    UserMailer.welcome(self).deliver_now
  end
  
  def calculate_reputation
    posts.sum(:likes) * 2 + comments.count
  end
end
```

✅ **DO**: Put business logic in Operations or Services

```ruby
# app/concepts/users/operation/send_welcome.rb
module Users
  module Operation
    class SendWelcome < Trailblazer::Operation
      step :find_user
      step :send_email
      
      def find_user(ctx, params:, **)
        user = ::User.find_by(id: params[:user_id])
        return false unless user
        ctx[:model] = user
        true
      end
      
      def send_email(ctx, model:, **)
        UserMailer.welcome(model).deliver_now
        true
      end
    end
  end
end

# app/services/users/reputation_calculator.rb
module Users
  class ReputationCalculator
    def initialize(user)
      @user = user
    end
    
    def call
      (@user.posts.sum(:likes) * 2) + @user.comments.count
    end
  end
end
```

### ❌ DON'T: Validations in Models

```ruby
# WRONG
class Article < ApplicationRecord
  validates :title, presence: true
  validates :slug, format: { with: /\A[a-z0-9-]+\z/ }
  validates :status, inclusion: { in: %w[draft published] }
end
```

✅ **DO**: Use dry-validation Contracts only

```ruby
# app/concepts/articles/contract/create.rb
module Articles
  module Contract
    class Create < Dry::Validation::Contract
      params do
        required(:title).filled(:string)
        required(:slug).filled(:string)
        required(:status).filled(:string)
      end
      
      rule(:slug) do
        unless value =~ /\A[a-z0-9-]+\z/
          key.failure(I18n.t('errors.messages.invalid_slug_format'))
        end
      end
      
      rule(:status) do
        unless %w[draft published].include?(value)
          key.failure(I18n.t('errors.messages.invalid_status'))
        end
      end
    end
  end
end

# app/models/article.rb
class Article < ApplicationRecord
  # NO validations (only persistence)
  enum :status, { draft: 0, published: 1 }
end
```

### ❌ DON'T: Callbacks in Models

```ruby
# WRONG
class Article < ApplicationRecord
  after_save :invalidate_cache
  after_create :notify_subscribers
  before_destroy :check_dependencies
  
  private
  
  def invalidate_cache
    Rails.cache.delete("articles")
  end
  
  def notify_subscribers
    NotificationJob.perform_later(id)
  end
  
  def check_dependencies
    throw(:abort) if comments.any?
  end
end
```

✅ **DO**: Call steps explicitly in Operations

```ruby
# app/concepts/articles/operation/create.rb
module Articles
  module Operation
    class Create < Trailblazer::Operation
      step :validate_input
      step :create_article
      step :invalidate_cache    # Explicit step
      step :notify_subscribers  # Explicit step
      
      def create_article(ctx, validated_params:, **)
        article = ::Article.new(validated_params)
        if article.save
          ctx[:model] = article
          true
        else
          ctx[:errors] = article.errors.to_hash
          false
        end
      end
      
      def invalidate_cache(ctx, **)
        Rails.cache.delete("articles")
        true
      end
      
      def notify_subscribers(ctx, model:, **)
        NotificationJob.perform_later(model.id)
        true
      end
    end
  end
end

# app/concepts/articles/operation/destroy.rb
module Articles
  module Operation
    class Destroy < Trailblazer::Operation
      step :find_article
      step :check_dependencies  # Explicit step
      step :destroy_article
      
      def check_dependencies(ctx, model:, **)
        if model.comments.any?
          ctx[:errors] = { base: [I18n.t('errors.messages.has_dependencies')] }
          return false
        end
        true
      end
    end
  end
end
```

### ❌ DON'T: Query Logic in Models (Scopes)

```ruby
# WRONG
class Article < ApplicationRecord
  scope :published, -> { where(status: :published) }
  scope :recent, -> { order(created_at: :desc).limit(10) }
  scope :by_author, ->(author_id) { where(author_id: author_id) }
  
  def self.popular
    where("views_count > ?", 1000).order(views_count: :desc)
  end
end
```

✅ **DO**: Use Query Objects in `app/queries/`

```ruby
# app/queries/articles/published_query.rb
module Articles
  class PublishedQuery
    def self.call(scope = Article.all)
      scope.where(status: :published)
    end
  end
end

# app/queries/articles/recent_query.rb
module Articles
  class RecentQuery
    def self.call(scope = Article.all, limit: 10)
      scope.order(created_at: :desc).limit(limit)
    end
  end
end

# app/queries/articles/by_author_query.rb
module Articles
  class ByAuthorQuery
    def self.call(scope = Article.all, author_id:)
      scope.where(author_id: author_id)
    end
  end
end

# app/queries/articles/popular_query.rb
module Articles
  class PopularQuery
    def self.call(scope = Article.all, min_views: 1000)
      scope.where("views_count > ?", min_views)
           .order(views_count: :desc)
    end
  end
end

# Usage in controller
def index
  @articles = Articles::PublishedQuery.call
  @articles = Articles::RecentQuery.call(@articles)
end
```

## Operation Anti-Patterns

### ❌ DON'T: Finding Resources in Both Controller and Operation

```ruby
# WRONG - Double query + security risk
# Controller
def update
  article = Current.user.articles.find_by!(id: params[:id])  # Query #1 WITH scope
  result = Articles::Operation::Update.call(
    params: article_params.to_h.merge(id: article.id)  # Pass ID only
  )
end

# Operation
def find_article(ctx, params:, **)
  article = ::Article.find_by(id: params[:id])  # Query #2 WITHOUT scope!
  ctx[:model] = article  # Could access resources user doesn't own!
end
```

✅ **DO**: Pass Pre-Authorized Model to Operation

```ruby
# CORRECT - Single query, secure
# Controller
def update
  # Authorization happens here with scope
  article = Current.user.articles.find_by!(id: params[:id])
  
  # Pass pre-authorized model
  result = Articles::Operation::Update.call(
    model: article,  # Model already authorized
    params: article_params.to_h
  )
end

# Operation (no find step needed)
module Articles
  module Operation
    class Update < Trailblazer::Operation
      step :validate_input
      step :update_article
      
      # No find_article step - model already provided
      
      def update_article(ctx, model:, validated_params:, **)
        if model.update(validated_params)
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

**Why?**
- ✅ Single DB query (performance)
- ✅ Authorization enforced at controller level
- ✅ No risk of bypassing scopes
- ✅ Clear separation of concerns

### ❌ DON'T: Updating Ownership in Update Operations

```ruby
# WRONG - Allows changing ownership
def update
  result = Articles::Operation::Update.call(
    params: article_params.to_h.merge(user_id: params[:user_id])  # BAD!
  )
end

# Operation
def update_article(ctx, model:, validated_params:, **)
  model.update(validated_params)  # Could change user_id!
end
```

✅ **DO**: Protect Ownership Fields

```ruby
# CORRECT - Ownership doesn't change on update
def update
  article = Current.user.articles.find_by!(id: params[:id])
  result = Articles::Operation::Update.call(
    model: article,
    params: article_params.to_h  # NO user_id
  )
end

# Operation
def update_article(ctx, model:, validated_params:, **)
  # Explicitly exclude ownership fields
  model.update(validated_params.except(:id, :user_id, :created_at))
end
```

### ❌ DON'T: Hardcoded Error Messages

```ruby
# WRONG
def validate_user(ctx, params:, **)
  unless params[:email].present?
    ctx[:errors] = { base: ["Email is required"] }
    return false
  end
  
  unless params[:email].include?("@")
    ctx[:errors] = { base: ["Email is invalid"] }
    return false
  end
  
  true
end
```

✅ **DO**: Use I18n for all error messages

```ruby
# In Contract
module Users
  module Contract
    class Create < Dry::Validation::Contract
      params do
        required(:email).filled(:string)
      end
      
      rule(:email) do
        unless value.include?("@")
          key.failure(I18n.t('errors.messages.invalid_email'))
        end
      end
    end
  end
end

# Or in Operation if needed
def validate_user(ctx, params:, **)
  unless user_can_perform_action?
    ctx[:errors] = { 
      base: [I18n.t('errors.messages.insufficient_permissions')] 
    }
    return false
  end
  true
end
```

### ❌ DON'T: Passing ActiveRecord Objects to Jobs

```ruby
# WRONG
class NotifyUserJob < ApplicationJob
  def perform(user)
    # User object gets serialized - can cause issues
    UserMailer.notification(user).deliver_now
  end
end

# Calling it
NotifyUserJob.perform_later(user) # Bad!
```

✅ **DO**: Pass IDs, let jobs fetch fresh records

```ruby
# CORRECT
class NotifyUserJob < ApplicationJob
  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user  # Handle case where user was deleted
    
    UserMailer.notification(user).deliver_now
  end
end

# Calling it
NotifyUserJob.perform_later(user.id) # Good!
```

## Service Anti-Patterns

### ❌ DON'T: Implicit Dependencies

```ruby
# WRONG
class UserService
  def send_email(user)
    Mailer.send(user.email) # Where does Mailer come from?
  end
  
  def process_payment(user, amount)
    PaymentGateway.charge(amount) # Global dependency
  end
end
```

✅ **DO**: Inject dependencies

```ruby
# CORRECT
class UserService
  def initialize(mailer: UserMailer, payment_gateway: PaymentGateway.new)
    @mailer = mailer
    @payment_gateway = payment_gateway
  end
  
  def send_email(user)
    @mailer.send(user.email)
  end
  
  def process_payment(user, amount)
    @payment_gateway.charge(amount)
  end
end

# Usage in Operation
def send_notification(ctx, model:, **)
  service = UserService.new
  service.send_email(model)
  true
end
```

## Controller Anti-Patterns

### ❌ DON'T: Accessing Internal Operation Context

```ruby
# WRONG
def create
  result = Articles::Operation::Create.call(params: params)
  
  article = result[:model]              # OK - documented public key
  temp_data = result[:temp_calculation] # WRONG - internal key
  debug_info = result[:_debug]          # WRONG - internal key
  
  # Using internal keys couples controller to Operation internals
end
```

✅ **DO**: Only access explicit result keys documented by the Operation

```ruby
# CORRECT
def create
  result = Articles::Operation::Create.call(params: params)
  
  # Only access documented keys
  if result.success?
    article = result[:model]   # Documented public key
    redirect_to article_path(article)
  else
    errors = result[:errors]   # Documented public key
    flash.now[:alert] = format_errors(errors)
    render :new, status: :unprocessable_entity
  end
end
```

**Rule:** Operations should document which ctx keys are public API. Controllers should only access those keys.

## View Anti-Patterns

### ❌ DON'T: Missing Turbo Frame Wrapping

```ruby
# WRONG - in views/articles/update.rb
class Views::Articles::Update < Views::Base
  def view_template
    # Missing turbo_frame_tag wrapper
    div(class: "article") do
      h1 { @article.title }
    end
  end
end
```

✅ **DO**: Wrap frame responses in matching turbo_frame_tag

```ruby
# CORRECT
class Views::Articles::Update < Views::Base
  def view_template
    turbo_frame_tag("article_#{@article.id}") do
      div(class: "article") do
        h1 { @article.title }
      end
    end
  end
end
```

### ❌ DON'T: Hardcoded Strings in Views

```ruby
# WRONG
class Views::Home::Index < Views::Base
  def view_template
    h1 { "Welcome to Papyro" }
    p { "Your publishing platform" }
  end
end
```

✅ **DO**: Use i18n keys

```ruby
# CORRECT
class Views::Home::Index < Views::Base
  def view_template
    h1 { t(".title") }
    p { t(".subtitle") }
  end
end

# config/locales/en/pages.yml
en:
  home:
    index:
      title: "Welcome to Papyro"
      subtitle: "Your publishing platform"

# config/locales/es/pages.yml
es:
  home:
    index:
      title: "Bienvenido a Papyro"
      subtitle: "Tu plataforma de publicación"
```

## Component Anti-Patterns

### ❌ DON'T: Components Without **attrs Support

```ruby
# WRONG - can't use Stimulus attributes
class Components::UI::Button < Components::Base
  def initialize(text:)
    @text = text
  end
  
  def view_template
    button(class: "btn") { @text }
  end
end
```

✅ **DO**: Include **attrs for Stimulus support

```ruby
# CORRECT
class Components::UI::Button < Components::Base
  def initialize(text:, **attrs)
    @text = text
    @attrs = attrs
  end
  
  def view_template
    button(class: "btn", **@attrs) { @text }
  end
end

# Usage with Stimulus
render Components::UI::Button.new(
  text: "Click me",
  data: { 
    controller: "button", 
    action: "click->button#handleClick" 
  }
)
```

## Testing Anti-Patterns

### ❌ DON'T: Testing Implementation Details

```ruby
# WRONG - testing internal Operation steps
test "calls validate_input step" do
  operation = Articles::Operation::Create.new
  assert operation.validate_input({}, params: valid_params)
end
```

✅ **DO**: Test public behavior and outcomes

```ruby
# CORRECT - test the result and side effects
test "creates article with valid params" do
  assert_difference "Article.count", 1 do
    result = Articles::Operation::Create.call(params: valid_params)
    assert_predicate result, :success?
    assert_instance_of Article, result[:model]
  end
end

test "fails with invalid params" do
  assert_no_difference "Article.count" do
    result = Articles::Operation::Create.call(params: invalid_params)
    assert_predicate result, :failure?
    assert result[:errors].key?(:title)
  end
end
```

## Security Anti-Patterns

### ❌ DON'T: Authorization in Operations

```ruby
# WRONG
class Articles::Operation::Destroy < Trailblazer::Operation
  step :find_article
  step :check_permissions  # DON'T do this here
  step :destroy_article
  
  def check_permissions(ctx, model:, current_user:, **)
    unless current_user.admin?
      ctx[:errors] = { base: ["Not authorized"] }
      return false
    end
    true
  end
end
```

✅ **DO**: Authorization at controller level

```ruby
# CORRECT
class ArticlesController < ApplicationController
  before_action :require_admin, only: [:destroy]
  
  def destroy
    # Authorization already checked
    result = Articles::Operation::Destroy.call(params: params)
    # Handle result...
  end
  
  private
  
  def require_admin
    raise Pundit::NotAuthorizedError unless Current.user&.admin?
  end
end
```

## I18n Anti-Patterns

### ❌ DON'T: Use Relative Translation Keys

```ruby
# WRONG - Relative keys in views
class Articles::Show < Views::Base
  def view_template
    h1 { t(".title") }  # BAD: Magic scope resolution
    p { t(".description") }
  end
end
```

✅ **DO**: Use Fully-Qualified Keys

```ruby
# CORRECT - Explicit, grep-able keys
class Articles::Show < Views::Base
  def view_template
    h1 { t("articles.show.title") }  # GOOD: Explicit and portable
    p { t("articles.show.description") }
  end
end
```

**Why?**
- ✅ Explicit: You know exactly which translation is used
- ✅ Grep-able: Easy to find all usages
- ✅ Portable: Works in components/partials anywhere
- ✅ No magic: No scope resolution confusion

### ❌ DON'T: Use strftime for Date/Time Formatting

```ruby
# WRONG - Hardcoded format, no localization
div { article.published_at.strftime("%B %-d, %Y") }
div { article.updated_at.strftime("%Y-%m-%d %H:%M") }
```

✅ **DO**: Use I18n.l (localize)

```ruby
# CORRECT - Respects locale, centralized formats
div { I18n.l(article.published_at, format: :long) }
div { I18n.l(article.updated_at, format: :short) }
div { I18n.l(article.created_at.to_date) }
```

```yaml
# config/locales/en/app.yml
en:
  date:
    formats:
      long: "%B %-d, %Y"
      short: "%b %-d"
# config/locales/es/app.yml
es:
  date:
    formats:
      long: "%-d de %B de %Y"
      short: "%-d %b"
```

### ❌ DON'T: Manual Currency/Number Formatting

```ruby
# WRONG - No localization, hardcoded format
span { "$#{article.price.round(2)}" }
span { "#{article.views} views" }
```

✅ **DO**: Use Number Helpers with I18n

```ruby
# CORRECT - Respects locale settings
span { number_to_currency(article.price) }          # => "$1,234.56" (en) or "€1.234,56" (es)
span { "#{number_with_delimiter(article.views)} views" }  # => "1,234,567 views"
```

### ❌ DON'T: Share Error Keys Without Domain Scoping

```ruby
# WRONG - Generic error keys clash across domains
# config/locales/en/errors.yml
en:
  errors:
    title_blank: "Title cannot be blank"  # Which title? Article? User profile?
    name_invalid: "Name is invalid"       # Article name? User name?
```

✅ **DO**: Domain-Scope All Error Messages

```ruby
# CORRECT - Domain-scoped for context
# config/locales/en/articles.yml
en:
  articles:
    errors:
      title_blank: "Article title cannot be blank"
      title_too_short: "Article title must be at least 3 characters"

# config/locales/en/users.yml
en:
  users:
    errors:
      name_blank: "User name is required"
      name_invalid: "User name can only contain letters"
```

**Usage in Operations:**
```ruby
def validate(ctx, params:, **)
  unless params[:title].present?
    ctx[:errors] = { title: [I18n.t("articles.errors.title_blank")] }
    return false
  end
  true
end
```

### ❌ DON'T: Hardcode User-Facing Text

```ruby
# WRONG - English hardcoded in view
class Articles::Index < Views::Base
  def view_template
    h1 { "All Articles" }  # BAD
    if @articles.empty?
      p { "No articles found" }  # BAD
    end
  end
end
```

✅ **DO**: Use I18n for ALL User-Facing Text

```ruby
# CORRECT - Everything translatable
class Articles::Index < Views::Base
  def view_template
    h1 { t("articles.index.title") }
    if @articles.empty?
      p { t("articles.index.empty") }
    end
  end
end
```

```yaml
# config/locales/en/articles.yml
en:
  articles:
    index:
      title: "All Articles"
      empty: "No articles found"

# config/locales/es/articles.yml
es:
  articles:
    index:
      title: "Todos los artículos"
      empty: "No se encontraron artículos"
```

### ❌ DON'T: Mix Operation Messages with Domain Keys

```ruby
# WRONG - Operation success/failure mixed with views
en:
  articles:
    show:
      title: "Article"
    create_success: "Created!"  # BAD: Not organized
```

✅ **DO**: Group Operation Messages Under `operations` Namespace

```ruby
# CORRECT - Clear organization
en:
  articles:
    show:
      title: "Article Details"
    operations:
      create:
        success: "Article created successfully"
        failure: "Failed to create article"
      update:
        success: "Article updated"
      destroy:
        success: "Article deleted"
```

```ruby
# Usage in controller
redirect_to articles_path, notice: I18n.t("articles.operations.create.success")
```

## Summary

**Key Takeaways:**
- Models: Persistence only (no validations, callbacks, scopes, business logic)
- Contracts: All validations with I18n error messages
- Operations: Business logic with explicit steps
- Services: Injected dependencies, single responsibility
- Query Objects: All read logic instead of model scopes
- Controllers: Authorization before Operations, only access documented ctx keys
- Views/Components: Fully-qualified i18n keys, proper base classes, **attrs support
- Jobs: Pass IDs not objects
- Tests: Test behavior not implementation
- I18n: Fully-qualified keys, I18n.l for dates, number helpers, domain-scoped errors

For verification, see: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md)
