---
name: query-object-pattern
description: "Golden archetype for read Query Objects. Use when creating or editing files in `app/concepts/*/query/`: plain ActiveRecord results, hash conditions over raw SQL, unfiltered base scope with a filter pipeline, no pagination in queries."
---

# Application Query Object Pattern

## Quick Rules

Cite as `query-object-pattern R<n>`. Detail and examples follow below / in references/.

R1. **Plain AR records only.** Never use `select` aliases or computed columns (`AS`, `COUNT(...)`) that add virtual attributes; select only schema columns. → detail: MANDATORY RULE: Records Must Be Plain ActiveRecord Models
R2. **Unfiltered base scope.** `base_scope` returns the full domain collection (`Model.all`); no `where` filters in it. → detail: MANDATORY RULE: Base Scope Must Be the Root of Your Domain
R3. **Filters live in pipeline steps.** Every filter is a named step declared with the `pipeline` macro. → detail: Style Rules
R4. **Pure private step methods.** One filter per private method taking `(current_scope)`, guard clauses, returning the scope; never mutate `@scope`/instance state. → detail: Style Rules
R5. **Single entry point.** Public interface is only `.call(filters, scope: nil)`; no keyword-argument call forms; honor a passed `scope:`. → detail: Interface Constraints
R6. **Never paginate.** Return a plain unpaginated `ActiveRecord::Relation`; pagination is the caller's job. → detail: Responsibilities
R7. **ORM over raw SQL.** Use hash/array conditions; no string conditions or interpolated SQL with user input; sanitize LIKE input. → detail: references/orm-conditions.md
R8. **Sort allowlist.** Validate sort field and direction against a strict allowlist before ordering. → detail: Style Rules
R9. **Boundary short-circuit.** A strict-boundary step (tenant/site/user) returns `current_scope.none` when context is missing, never `current_scope`. → detail: Mandatory Context Short-Circuits
R10. **Normalize boolean filters.** Cast form-sourced boolean filters with `ActiveModel::Type::Boolean`. → detail: Boolean Filter Normalization
R11. **Domain naming, no God Queries.** Inherit `ApplicationQuery`, name `Resource::BusinessBoundaryQuery`, one boundary per class. → detail: Domain-Driven Repository Conventions
R12. **Aggregates stay out of records.** Computed counts/derived data go in a separate hash/struct or presenter, not the query's select. → detail: MANDATORY RULE: Records Must Be Plain ActiveRecord Models

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

> **ORM Conditions over Raw SQL:** hash/array conditions, ordering, joins → [references/orm-conditions.md](references/orm-conditions.md)

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

> **ApplicationQuery Base Class and Examples:** base class, house-style and complex examples → [references/base-class-and-examples.md](references/base-class-and-examples.md)

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

> **Filters and Search Guidance:** domain filter and search guidance → [references/filters-and-search.md](references/filters-and-search.md)

## Spec Checklist
- `.call` delegates to `build_query` and returns a plain `ActiveRecord::Relation` (not paginated)
- `.call` is tested as the only public call path used by consumers
- Signature is `.call(filters, scope: nil)` (no keyword-argument call interface)
- Optional `scope:` input is honored over the `base_scope`
- Empty hash behavior is covered: `QueryObject.call({})` returns the base relation
- Case-insensitive title filter works and protects against wildcard injection
- Ordering behavior is covered and enforces the allowed fields
- Use `.to_a.size` (not `.size`) when checking count on grouped/complex relations in specs
