---
name: pundit-auth
description: Professional authorization guidance using the Pundit gem. Use when defining access control logic in Rails, creating policies, managing unauthorized access redirects, or scoping database queries based on user roles.
license: MIT
---

# Rails Authorization (Pundit)

Pundit provides minimal, explicit authorization through plain Ruby policy classes.

This skill defines the baseline standards for Papyro and aligns with official Pundit guidance from https://github.com/varvet/pundit.

## Core Principles

1. Explicit authorization in every controller action
2. Policy classes are plain Ruby objects and must stay simple
3. Prefer policy scopes for collections, not ad-hoc filtering
4. Keep authorization in controllers and policy objects, not in Operations
5. Use verification hooks to catch missing authorization during development

## Reference Map

- **[references/advanced-patterns.md](references/advanced-patterns.md)**
  Use for namespaced policies, custom policy resolution, and more advanced authorization structures.
- **[references/testing.md](references/testing.md)**
  Use for policy, scope, and controller authorization test patterns.

## ApplicationController Baseline

```ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  after_action :verify_pundit_authorization

  rescue_from Pundit::NotAuthorizedError, with: :handle_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  private

  def verify_pundit_authorization
    if action_name == "index"
      verify_policy_scoped
    else
      verify_authorized
    end
  end

  def pundit_user
    Current.user
  end

  def handle_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    message = I18n.t("#{policy_name}.#{exception.query}", scope: "pundit", default: I18n.t("admin.errors.unauthorized"))

    redirect_to(request.referrer || root_path, alert: message)
  end

  def handle_not_found
    skip_authorization unless pundit_policy_authorized?
    skip_policy_scope unless pundit_policy_scoped?
    render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
  end
end
```

Notes:
- Use `pundit_user` when your app does not expose `current_user` (Rails 8 generator uses `Current.user`).
- If your app switches users in-session, call `pundit_reset!` after switching.
- `handle_not_found` guards Pundit verification with `pundit_policy_authorized?` / `pundit_policy_scoped?` so the `after_action` hook does not raise a second error.

## Overriding Not-Found Behaviour per Namespace

When a bounded-context namespace needs different not-found behaviour (e.g., Studio redirects to the creator's list instead of rendering 404.html), override `handle_not_found` in the namespace base controller:

```ruby
# app/controllers/studio/base_controller.rb
module Studio
  class BaseController < ApplicationController
    private

    def handle_not_found
      skip_authorization unless pundit_policy_authorized?
      skip_policy_scope unless pundit_policy_scoped?
      redirect_to studio_articles_path, alert: t("articles.errors.not_found")
    end
  end
end
```

All Studio controllers inherit this redirect automatically. No inline rescue blocks needed in any child controller.

## Controller Patterns

### Collections

Use `policy_scope` for collection actions.

```ruby
def index
  articles = policy_scope(Article)
  render Views::Articles::Index.new(articles: articles)
end
```

If you intentionally do not scope in an index action, call `skip_policy_scope`.

### Member Actions

Use `authorize(record)` for member actions. When the action name corresponds to the policy query name, let Pundit infer it instead of passing the query symbol explicitly.

```ruby
def show
  article = Article.find(params[:id])
  authorize article
  render Views::Articles::Show.new(article: article)
end
```

### Non-standard Query Names

Use explicit queries only when the controller action name does not match the policy query name, or when authorizing a headless policy.

```ruby
authorize article, :publish?
authorize :admin_area, :access?
```

**Prefer creating a namespaced policy over using `:action_name?` overrides.** See _Namespaced Policies_ below.

### Authorizing with a Specific Policy Class

When a controller lives in a bounded-context namespace (`Studio::`, `Admin::`, etc.), tell Pundit which policy to use via `policy_class:` instead of relying on automatic inference from the model name.

Works for both class-level (new/create) and instance-level (edit/update/destroy) authorization:

```ruby
# Class-level: authorizing "can this user create any article in Studio?"
def new
  authorize Article, policy_class: Studio::ArticlePolicy
  # ...
end

def create
  authorize Article, policy_class: Studio::ArticlePolicy
  # ...
end

# Instance-level: authorizing a specific record
def update
  authorize article, policy_class: Studio::ArticlePolicy
  # ...
end
```

This keeps every authorize call in a Studio controller pointing at `Studio::ArticlePolicy`, so Studio-specific rules never leak into the root `ArticlePolicy`.

When a bounded context uses slug URLs (`to_param` returns slug), use a single memoized reader with slug-only lookup instead of mixed `id || slug` queries:

```ruby
private

def article
  @article ||= Current.user.articles.find_by!(slug: params[:slug])
end
```

If the controller is namespaced under Studio and works with article member routes, ensure routes declare `param: :slug` so controller lookups consistently use `params[:slug]`.

### Conditional Authorization

If an action conditionally authorizes, call `skip_authorization` in the non-authorized branch.

```ruby
def show
  record = Record.find_by(id: params[:id])
  if record
    authorize record
  else
    skip_authorization
    head :not_found
  end
end
```

## Policy Standards

1. Policies live in `app/policies/`
2. Name as `[Model]Policy`
3. Inherit from `ApplicationPolicy`
4. Query methods end in `?` and return booleans
5. Keep policy methods small and predicate-focused

Example:

```ruby
class ArticlePolicy < ApplicationPolicy
  def show?
    record.published? || owner?
  end

  def update?
    owner?
  end

  class Scope < Scope
    def resolve
      return scope.where(status: :published) unless user

      scope.where(user: user)
    end
  end

  private

  def owner?
    user.present? && record.user_id == user.id
  end
end
```

## Scope Standards

Use policy scopes to express visibility rules for collections.

1. Implement `Scope#resolve`
2. Return an `ActiveRecord::Relation` when possible
3. Keep the same rule semantics used by member permissions
4. Avoid duplicating scope logic in controllers

## Strong Parameters with Policies

When attributes vary by role, let policies define permitted attributes.

```ruby
class PostPolicy < ApplicationPolicy
  def expected_attributes_for_action(_action_name)
    return [:title, :body] if user.admin?

    [:title]
  end
end

def update
  post = authorize Post.find(params[:id])
  post.update(expected_attributes(post))
end
```

Prefer this pattern for role-sensitive mass assignment.

## Namespaced Policies (Bounded Contexts)

Use namespaced policies to reflect domain boundaries. Policies are not global objects — publishing an article in a `Studio` context may carry different rules than publishing as an `Admin` or `Moderator`.

### When to Create a Namespaced Policy

Create a namespaced policy whenever a controller sub-namespace represents a **distinct domain context** with its own rules, or when you find yourself overriding the action name in `authorize` (e.g., `authorize article, :publish?` inside a `create` action). That override is a signal that your policy does not align with the controller's domain boundary.

### Pattern: `policy_class` for Discrete Sub-Resources

When a controller treats a concept as a sub-resource (e.g., `Studio::PublicationsController`), create a matching namespaced policy and reference it explicitly with `policy_class`:

```ruby
# app/policies/studio/publication_policy.rb
module Studio
  # Authorizes publish/unpublish within the Studio bounded context only.
  # create? = publish,  destroy? = unpublish — mirrors the controller exactly.
  class PublicationPolicy < ApplicationPolicy
    def create?
      owner? && article_ready_to_publish?
    end

    def destroy?
      owner?
    end

    private

    def owner?
      user.present? && record.user_id == user.id
    end

    def article_ready_to_publish?
      record.title.present?
    end
  end
end
```

```ruby
# app/controllers/studio/publications_controller.rb
def create
  article = find_user_article!
  authorize article, policy_class: Studio::PublicationPolicy
  # ...
end

def destroy
  article = find_user_article!
  authorize article, policy_class: Studio::PublicationPolicy
  # ...
end
```

### Why This Matters

1. **REST alignment** — controller actions (`create`, `destroy`) map directly to policy methods (`create?`, `destroy?`). No action-name overrides needed.
2. **Bounded contexts** — `Studio::PublicationPolicy` governs creator workflows only. An `Admin::PublicationPolicy` could allow force-unpublishing with completely isolated rules.
3. **Skinny god objects** — `ArticlePolicy` covers only universal CRUD (`show?`, `create?`, `update?`, `destroy?`). Domain-specific verbs live in dedicated policies.

### When NOT to Use a Namespaced Policy

If the rule is truly universal (e.g., "only the owner can destroy"), keep it in the root policy. Only extract when the bounded context adds distinct semantics or branching.

### Defense in Depth

Even when `find_user_article!` already scopes to `Current.user` (making unauthorized access return a 404), always keep the `authorize` call. If a future developer changes the finder, the policy is the last safety net.

### Traditional Namespace Syntax (Admin Contexts)

For admin namespaces that rely on Pundit's automatic namespace resolution:

```ruby
authorize([:admin, post])
policy_scope([:admin, Post])
```

For large apps, centralize namespacing via `pundit_namespace` in a base admin controller.

## Headless Policies

Use symbol-backed policies for non-model concepts.

```ruby
authorize :admin_area, :access?
```

Policy must accept two args in `initialize(user, _record)`.

## Error Handling

Rescue `Pundit::NotAuthorizedError` in `ApplicationController` and present translated messages.

Optionally map to HTTP 403 globally:

```ruby
config.action_dispatch.rescue_responses["Pundit::NotAuthorizedError"] = :forbidden
```

## Papyro Integration Rules

1. Authorization is done in controllers before operations
2. For update/destroy, find and authorize the model first, then pass the authorized model to the operation
3. For create, authorize the class and pass ownership from `Current.user`
4. On rescue branches that intentionally bypass authorization (for example not-found redirects), call `skip_authorization`
5. For index actions that intentionally bypass scoping, call `skip_policy_scope`

## Anti-Patterns to Avoid

1. Missing `authorize` in member actions
2. Missing `policy_scope` in collection actions
3. Enforcing authorization inside Operations
4. Calling `skip_authorization` globally to silence verification
5. Writing large, branch-heavy policies that hide intent
6. Mixing visibility filtering into controllers instead of scope classes
7. **God-object policies** — adding every domain verb (`publish?`, `feature?`, `approve?`) to a single root policy (`ArticlePolicy`). Extract to namespaced policies instead.
8. **Action-name overrides as a smell** — `authorize article, :publish?` inside a `create` action signals a missing bounded-context policy. Create `Studio::PublicationPolicy` (or equivalent) so `create?` maps to `create?`.
9. **Wrapping Pundit helpers in private methods** — never wrap `skip_authorization` or `skip_policy_scope` in a private method just to give them a different name (e.g., `def skip_pundit_authorization; skip_authorization; end`). Reference the Pundit method directly as the `before_action` callback:

   ```ruby
   # Bad
   before_action :skip_pundit_authorization
   def skip_pundit_authorization = skip_authorization

   # Good
   before_action :skip_authorization
   ```

10. **Inline `rescue ActiveRecord::RecordNotFound` in controller actions** — use `rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found` in `ApplicationController` instead. Override `handle_not_found` in namespace base controllers for context-specific behaviour. Always guard Pundit verification predicates in the handler:

    ```ruby
    # Bad — repeated in every action
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false

    # Good — once in ApplicationController
    def handle_not_found
      skip_authorization unless pundit_policy_authorized?
      skip_policy_scope unless pundit_policy_scoped?
      render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
    end
    ```

## Testing Guidance

1. Policy unit tests for query methods and scope behavior
2. Controller/request tests asserting unauthorized users are denied
3. Regression tests for conditional skip paths (`skip_authorization`, `skip_policy_scope`)
