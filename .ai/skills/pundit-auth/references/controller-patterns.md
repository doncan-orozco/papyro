# Controller Patterns

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
