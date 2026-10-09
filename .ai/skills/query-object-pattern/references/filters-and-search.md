# Filters and Search Guidance

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
