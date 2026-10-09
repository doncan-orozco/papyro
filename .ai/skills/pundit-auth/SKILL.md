---
name: pundit-auth
description: "Pundit authorization and role management. Use when creating or editing files in `app/policies/`, calling `authorize`/`policy_scope` in controllers, adding policies for sub-resources or namespaces (Studio), handling `NotAuthorizedError`, or adding integer-enum roles to users."
license: MIT
---

# Rails Authorization (Pundit)

Pundit provides minimal, explicit authorization through plain Ruby policy classes.

## Quick Rules

Cite as `pundit-auth R<n>`. Detail and examples follow below / in references/.

R1. **Authorize every action.** Every controller member/collection action calls `authorize` (or `policy_scope` for collections); no action ships without one. → detail: Anti-Patterns to Avoid
R2. **Authorize in controllers only.** No `authorize`/Pundit calls inside Operations; the controller authorizes before invoking the operation. → detail: Papyro Integration Rules
R3. **Authorize model before operation.** update/destroy find and authorize the model first, then pass it to the operation; create authorizes the class and takes ownership from `Current.user`. → detail: Papyro Integration Rules
R4. **Policy naming and base.** Policies live in `app/policies/`, are named `[Model]Policy`, and inherit `ApplicationPolicy`. → detail: Policy Standards
R5. **Predicate methods.** Policy query methods end in `?`, return booleans, and stay small and predicate-focused (no branch-heavy bodies). → detail: Policy Standards
R6. **Scopes for collections.** Visibility filtering lives in `Scope#resolve` (returning a Relation) with the same rules as member permissions, never ad-hoc in controllers. → detail: Scope Standards
R7. **Role-based params via policy.** Role-sensitive mass assignment uses `expected_attributes_for_action` in the policy, not controller conditionals. → detail: Strong Parameters with Policies
R8. **No god-object policies.** Domain verbs (`publish?`, `feature?`, `approve?`) get a namespaced policy (e.g. `Studio::PublicationPolicy`), not the root model policy. → detail: references/namespaced-policies.md
R9. **No action-name overrides.** `authorize record, :other?` inside a differently named action signals a missing bounded-context policy; create one so `create?` maps to `create?`. → detail: Anti-Patterns to Avoid
R10. **Call skip helpers directly.** Use `skip_authorization`/`skip_policy_scope` directly (e.g. `before_action :skip_authorization`), never wrapped in private methods or applied globally. → detail: Anti-Patterns to Avoid
R11. **Not-found via rescue_from.** Use `rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found` in `ApplicationController`; no inline `rescue RecordNotFound` in actions. → detail: Anti-Patterns to Avoid
R12. **Guard Pundit verification in handlers.** Rescue branches that bypass authorization/scoping call `skip_authorization`/`skip_policy_scope` (guarded by `pundit_policy_authorized?`/`pundit_policy_scoped?`). → detail: Anti-Patterns to Avoid
R13. **Translated NotAuthorizedError.** `Pundit::NotAuthorizedError` is rescued in `ApplicationController` with translated messages. → detail: Error Handling
R14. **Headless policies take two args.** Symbol-backed policies (`authorize :admin_area, :access?`) define `initialize(user, _record)`. → detail: Headless Policies
R15. **Integer enum roles.** Roles are `enum :role, { member: 0, ... }` with explicit hash mapping, an integer column `default: 0, null: false`, and 0 as the least-privileged role. → detail: references/role-management.md

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

> **ApplicationController Baseline:** baseline and per-namespace not-found overrides → [references/controller-baseline.md](references/controller-baseline.md)

> **Controller Patterns:** collections, members, policy_class, conditional authorization → [references/controller-patterns.md](references/controller-patterns.md)

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

> **Namespaced Policies:** bounded-context and sub-resource policies → [references/namespaced-policies.md](references/namespaced-policies.md)

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
