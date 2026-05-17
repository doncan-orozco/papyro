---
name: query-object-pattern
description: Build reusable query objects for read flows across the application using a Domain-Driven Design (DDD) approach, strict functional interfaces, declarative pipelines, and filtering rules.
---

# Application Query Object Pattern

## Common Query Scopes
- Read/list/search flows across the application
- Complex visibility predicates encapsulating business rules
- Reusable filtering logic across multiple endpoints

## Responsibilities
- Build ActiveRecord relation for read concerns only.
- Encapsulate visibility rules and domain boundaries (e.g., `Published`, `Owned`, `Accessible`).
- Apply search and sorting.
- Return a plain `ActiveRecord::Relation` - never paginate inside the query object.
- The caller is responsible for pagination on the returned relation.
- Expose only `.call(filters, scope: nil)` as the public entry point.

---

## MANDATORY RULE: Records Must Be Plain ActiveRecord Models

**Query objects MUST return plain ActiveRecord model instances with only schema-defined attributes.**

Never use `SELECT` to attach virtual attributes, computed columns, or column aliases to the returned records. Doing so mutates the AR model shape in ways that are invisible to serializers, specs, and callers.

### Forbidden patterns

```ruby
# FORBIDDEN — adds virtual attributes that are not part of the schema
relation.select(
  "tags.*",
  "tags.id AS tag_id",          # alias of a real column
  "tags.name AS tag_name",       # alias of a real column
  "COUNT(taggings.id) AS usage_count",   # computed, not a column
  "MIN(taggings.created_at) AS first_used_at"  # computed, not a column
)
```

These aliases inject extra attributes onto model instances — they are not declared on the model class and will silently disappear or raise errors when serializers, `pluck`, or reload is called.

### Allowed patterns

```ruby
# OK — selects only schema columns; all attributes are model-native
relation.select(:id, :name, :taggings_count, :created_at)

# OK — default select (all schema columns)
relation.where(taggings: {context: "tags"})

# OK — aggregate/reporting data should be computed in a separate plain Ruby
#      struct or hash, not appended to AR model instances
tags = Articles::PublishedQuery.call(filters)
report = tags.group(:context).count   # returns a Hash, not model instances
```

If you need to expose computed data (counts, aggregates, derived labels) alongside model attributes, compute them separately in the controller or a dedicated presenter — **not inside the query object's select**.

---

## MANDATORY RULE: ORM Methods Over Raw SQL Strings

Active Record's ORM query methods are safe, readable, and database-agnostic. Use them first. Drop to raw SQL only when there is no ORM equivalent, and document why.

### Conditions: Do's and Don'ts

#### Hash Conditions (preferred)

Use a hash whenever the condition is equality, range, subset, or a joined-table attribute.

```ruby
# equality
where(status: :active)
where(out_of_print: false)

# range
where(created_at: 1.week.ago..)
where(year_published: ...50.years.ago.year)

# IN / subset
where(orders_count: [1, 3, 5])

# joined table hash — clean and injection-safe
where(taggings: {context: "tags", taggable_type: "Event"})
where(orders: {created_at: time_range})

# NOT
where.not(status: :cancelled)
where.not(orders_count: [1, 3, 5])

# OR / AND (preferred over raw string ORs)
local_banks.or(global_banks).or(private_banks)
where(id: [1, 2]).and(where(id: [2, 3]))
```

#### Array Conditions (when hash is not enough)

Use `?` positional placeholders or named `:key` placeholders. Never interpolate variables directly.

```ruby
# positional placeholders — safe
where("price > ?", 100)
where("title = ? AND out_of_print = ?", params[:title], false)
where("created_at >= :start AND created_at <= :end", start: 1.week.ago, end: Time.current)
```

For `LIKE` searches, use `sanitize_sql_like` to prevent wildcard injection:

```ruby
# safe LIKE — sanitize user input before wrapping with %
where("LOWER(tags.name) LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(query.downcase)}%")
```

#### Pure String Conditions (FORBIDDEN with user input)

```ruby
# FORBIDDEN — SQL injection risk; user controls the WHERE clause
where("title = '#{params[:title]}'")
where("title LIKE '%#{params[:title]}%'")

# FORBIDDEN — even with trusted data, prefer array or hash form
where("status = 'active'")        # use: where(status: :active)
where("taggings_count >= 100")    # use: where("taggings_count >= ?", 100)
```

Pure string conditions are **never acceptable** when the string contains any user-supplied value. They are acceptable only for rare structural SQL fragments with no user input (e.g., raw `CASE` expressions as grouping keys), and must be accompanied by a comment explaining why no ORM alternative exists.

#### Ordering

```ruby
# preferred — symbol/hash form
order(name: :asc)
order(created_at: :desc)
order(:name, created_at: :desc)

# acceptable — string only when multi-column or table-qualified
order("tags.name ASC, tags.created_at DESC")

# FORBIDDEN — user-controlled direction must be validated before use
order("#{params[:field]} #{params[:dir]}")   # inject risk — sanitize first
```

Always normalize sort direction to a safelist and explicitly validate sort fields against an allowlist in the query object.

#### Joins

Prefer named association joins over raw SQL strings:

```ruby
# preferred
joins(:taggings)
left_joins(:taggings)
joins(:author, :reviews)
joins(reviews: :customer)

# only if no association exists
joins("INNER JOIN taggings ON taggings.tag_id = tags.id")
```

---

## MANDATORY RULE: Base Scope Must Be the Root of Your Domain

**`base_scope` MUST ALWAYS return the full, unfiltered domain collection.**

`base_scope` is NOT a place to apply filters. All filtering logic—including status, visibility, and domain boundaries—**MUST be defined in named pipeline steps**.

### Why This Matters

1. **Composability**: Callers may pass a custom `scope:` argument. If `base_scope` already filters, the caller's scope is completely ignored and filtering rules become hidden.
   
   ```ruby
   # If PublishedQuery.base_scope = Article.where(status: :published)
   # Then this call IGNORES the custom scope entirely:
   relation = PublishedQuery.call(filters, scope: Article.where(category: "tech"))
   # Result: Only published articles, category filter is lost!
   ```

2. **Transparency**: Pipeline steps are visible and explicit. A reader can instantly see what filters are applied by reading the `pipeline` declaration. Filters hidden in `base_scope` are invisible.

3. **Testing**: When testing a pipeline step in isolation, you need to pass a custom scope. If `base_scope` applies unremovable filters, tests become fragile.

4. **Reuse**: Query objects are meant to be composed. If you need "published only" _and_ "accessible to user", separate queries should work together via the `scope:` parameter.

### Correct Pattern

```ruby
# ✅ CORRECT — unfiltered base, all filtering in pipeline
module Articles
  class PublishedQuery < ApplicationQuery
    base_scope { Article.all }

    pipeline :filter_by_status,
             :filter_by_category,
             :apply_ordering

    private

    def filter_by_status(current_scope)
      current_scope.where(status: :published)
    end

    def filter_by_category(current_scope)
      return current_scope if filters[:category_id].blank?
      current_scope.where(category_id: filters[:category_id])
    end
  end
end
```

### Incorrect Pattern

```ruby
# ❌ WRONG — base_scope applies a filter
module Articles
  class PublishedQuery < ApplicationQuery
    # DO NOT DO THIS
    base_scope { Article.where(status: :published) }

    pipeline :filter_by_category,
             :apply_ordering

    # Problem: The "published" filter is invisible and unmovable.
    # Callers cannot pass a custom scope that filters differently.
  end
end
```

---

## Domain-Driven Repository Conventions

In this codebase, we follow a Domain-Driven Design (DDD) approach. All query objects live under `app/queries/` grouped by their specific resource or domain module, and inherit from `ApplicationQuery`.

### The Domain Rule
Do not build "God Queries" (e.g., one massive `ArticlesQuery` that tries to handle public searches, admin lists, and personal drafts). 
Instead, build small, composable query objects named after their **business logic boundary**:
- `Articles::PublishedQuery`
- `Articles::OwnedQuery`
- `Users::ActiveQuery`
- `Courses::QuestionBanks::AccessibleQuery`

### The ApplicationQuery Base Class
*(This exists in `app/queries/application_query.rb`)*
```ruby
class ApplicationQuery
  def self.pipeline(*steps)
    @pipeline_steps = steps.flatten
  end

  def self.pipeline_steps
    @pipeline_steps ||= []
  end

  def self.base_scope(&block)
    @base_scope_proc = block
  end

  def self.evaluated_base_scope
    raise NotImplementedError, "Define a `base_scope` block in #{name}" unless @base_scope_proc
    @base_scope_proc.call
  end

  def self.call(filters = {}, scope: nil)
    initial_scope = scope || evaluated_base_scope
    new(filters, scope: initial_scope).build_query
  end

  attr_reader :filters, :initial_scope

  def initialize(filters, scope:)
    # Protect pipeline steps from symbol/string key mismatches when callers
    # pass ActionController::Parameters or plain hashes.
    @filters = (filters || {}).to_h.with_indifferent_access
    @initial_scope = scope
  end

  def build_query
    self.class.pipeline_steps.reduce(initial_scope) do |current_scope, step|
      send(step, current_scope)
    end
  end
end
```

### Primary House Style Example
```ruby
# app/queries/articles/published_query.rb
module Articles
  class PublishedQuery < ApplicationQuery
    base_scope { Article.all }

    pipeline :filter_by_status,
             :search_by_title,
             :filter_by_category,
             :apply_ordering

    private

    def filter_by_status(current_scope)
      current_scope.where(status: :published)
    end

    def search_by_title(current_scope)
      return current_scope if filters[:query].blank?
      
      safe_query = ActiveRecord::Base.sanitize_sql_like(filters[:query].to_s.downcase)
      current_scope.where("LOWER(articles.title) LIKE ?", "%#{safe_query}%")
    end

    def filter_by_category(current_scope)
      return current_scope if filters[:category_id].blank?
      current_scope.where(category_id: filters[:category_id])
    end

    def apply_ordering(current_scope)
      field = filters.dig(:order, :field)&.to_s
      return current_scope if field.blank? || %w[created_at title].exclude?(field)
      
      dir = (filters.dig(:order, :dir)&.to_s&.downcase == "asc") ? "asc" : "desc"
      current_scope.order(field => dir)
    end
  end
end
```

## Caller Contract
Callers (usually controllers) must define and pass a `filters` hash method. The controller is responsible for choosing the correct Domain Query based on the current context.

```ruby
# In a public controller protecting drafts
def index
  relation = Articles::PublishedQuery.call(filters)
  # ... pagination and rendering
end

# In a private studio controller showing a writer's drafts
def index
  relation = Articles::OwnedQuery.call(filters.merge(owner: current_user))
  # ... pagination and rendering
end
```

## Recommended Shape (Complex Example)
```ruby
# app/queries/courses/question_banks/accessible_query.rb
module Courses::QuestionBanks
  class AccessibleQuery < ApplicationQuery
    SORTABLE_FIELDS = %w[title created_at updated_at].freeze

    base_scope { Courses::QuestionBank.all }

    pipeline :enforce_account_isolation,
             :filter_by_visibility,
             :search_by_title,
             :apply_ordering

    private

    def enforce_account_isolation(current_scope)
      return current_scope.none if filters[:site].blank?
      
      current_scope.joins(:site).where(sites: { account_id: filters[:site].account_id })
    end

    def filter_by_visibility(current_scope)
      return current_scope.none if filters[:site].blank? || filters[:user].blank?

      local_banks = current_scope.where(
        shared_type: Courses::QuestionBank::SHARED_TYPES[:LOCAL],
        site_id: filters[:site].id
      )

      global_banks = current_scope.where(
        shared_type: Courses::QuestionBank::SHARED_TYPES[:GLOBAL]
      )

      private_banks = current_scope.where(
        shared_type: Courses::QuestionBank::SHARED_TYPES[:PRIVATE],
        author_id: filters[:user].id
      )

      local_banks.or(global_banks).or(private_banks)
    end

    def search_by_title(current_scope)
      return current_scope if filters[:query].blank?

      safe_query = ActiveRecord::Base.sanitize_sql_like(filters[:query].to_s.downcase)
      current_scope.where("LOWER(courses_question_banks.title) LIKE ?", "%#{safe_query}%")
    end

    def apply_ordering(current_scope)
      field = filters.dig(:order, :field)&.to_s
      return current_scope if field.blank? || SORTABLE_FIELDS.exclude?(field)

      dir = (filters.dig(:order, :dir)&.to_s&.downcase == "asc") ? "asc" : "desc"
      current_scope.order(field => dir)
    end
  end
end
```

### Controller Pagination (caller responsibility)
```ruby
question_banks = Courses::QuestionBanks::AccessibleQuery.call(filters)
  .paginate(page: parse_page(params[:page]), per_page: parse_per_page(params[:per_page]))
```

## Style Rules
- Always inherit from `ApplicationQuery`.
- Follow DDD naming: Group queries inside a module representing the resource (`module Articles`), and name the class after the specific business logic (`PublishedQuery`).
- Use `base_scope { Model.all }` (or stricter scopes) to prevent boot-time evaluation issues and define the domain boundary.
- Declare the exact execution sequence using the `pipeline` class macro.
- Keep each filter in a separate private method.
- Methods must be pure: accept `(current_scope)`, apply guard clauses, and return the mutated scope. Never mutate an instance variable (e.g., `@scope`).
- Keep method names readable and explicit.
- Validate sorting inputs against a strict allowlist.
- Normalize boolean-like filter values with `ActiveModel::Type::Boolean` when filters can come from HTML forms (`"0"`, `"1"`, `"true"`, `"false"`).
- Eager loading is allowed and encouraged as a final pipeline step when the boundary guarantees association access in callers (`includes` / `eager_load` for N+1 prevention).

### Mandatory Context Short-Circuits
- If a pipeline step enforces a strict boundary (tenant/account/site/user ownership) and required context is missing, return `current_scope.none`.
- Never return `current_scope` when required boundary context is absent; that can leak data across boundaries.

```ruby
def enforce_tenant_scope(current_scope)
  return current_scope.none if filters[:site].blank?

  current_scope.where(site: filters[:site])
end
```

### Boolean Filter Normalization
```ruby
def filter_by_featured(current_scope)
  return current_scope unless filters.key?(:featured)

  is_featured = ActiveModel::Type::Boolean.new.cast(filters[:featured])
  current_scope.where(featured: is_featured)
end
```

### Optional Eager Loading Step
```ruby
def apply_includes(current_scope)
  current_scope.includes(:author, :tags)
end
```

## Interface Constraints
- Keyword-argument `.call(site:, user:, ...)` forms are not accepted.
- The accepted signature is strictly `.call(filters, scope: nil)` (inherited from base class).

## Suggested Filters For Question Banks
```ruby
{
  site: site,
  user: sessioned_user,
  query: params[:query],
  order: {field: "updated_at", dir: "desc"}
}
```

## Empty Filters Invariant
When `filters` is an empty hash, the query object must return the base scope. This is automatically handled by `ApplicationQuery` gracefully bypassing all pure methods via their guard clauses.

```ruby
query_result = QueryObject.call({})
base_scope_result == query_result
```

## Search Guidance
- If the model/query mixin already provides `search_by`, prefer that repository abstraction.
- Otherwise, use explicit SQL predicates scoped to the resource table.
- Always use `ActiveRecord::Base.sanitize_sql_like` on user input for `LIKE` clauses.
- Keep case-insensitive matching inside the query object, not the controller.

## Spec Checklist
- `.call` delegates to `build_query` and returns a plain `ActiveRecord::Relation` (not paginated)
- `.call` is tested as the only public call path used by consumers
- Signature is `.call(filters, scope: nil)` (no keyword-argument call interface)
- Optional `scope:` input is honored over the `base_scope`
- Empty hash behavior is covered: `QueryObject.call({})` returns the base relation
- Case-insensitive title filter works and protects against wildcard injection
- Ordering behavior is covered and enforces the allowed fields
- Use `.to_a.size` (not `.size`) when checking count on grouped/complex relations in specs
