# Namespaced Policies

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
