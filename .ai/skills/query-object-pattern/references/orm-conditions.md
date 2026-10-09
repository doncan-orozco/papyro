# ORM Conditions over Raw SQL

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
