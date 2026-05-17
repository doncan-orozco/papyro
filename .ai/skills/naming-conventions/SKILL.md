---
name: naming-conventions
description: Every class, method, and variable must have a readable, meaningful, explicit name rooted in the domain language. Avoid computer-science jargon when a domain term exists.
---

# Naming Conventions

## Core Principle
Code should read like domain discussion. A casual observer should not be able to tell whether people are talking about the code or the business domain. If a financial analyst can point at a screen and walk programmers through pricing logic line-by-line without switching vocabulary, the naming is right.

## Rules


### Classes and Types
- Name types after the domain concept they represent, not after their technical implementation.
- **Never repeat the namespace or type in the class or file name (no stuttering):**
  - Use `Published` (not `PublishedQuery`), `Body` (not `BodyValidator`), `Default`/`Show` (not `ArticlePresenter`/`ShowPresenter`).
- Prefer `Surname`, `Money`, `Currency`, `EnrollmentPeriod` over `String`, `Float`, `Hash`.
- Compound domain concepts get their own type: `Money` has a `Currency` and an `Amount`, not a raw float.
- Never expose implementation-level details in a class name: `UserList` is worse than `Roster`; `QuestionHashMap` is worse than `QuestionBank`.

### Methods
- Name methods after what they accomplish in the domain, not how they do it.
- A method that determines whether an enrollment is still valid is `active?` or `within_enrollment_period?`, not `check_date_range`.
- Predicate methods (`valid?`, `expired?`, `visible_to?`) read as assertions about the domain state.
- Command methods (`enroll`, `publish`, `archive`) use the domain verb, not the persistence verb (`save`, `insert`, `update`).

### Variables and Parameters
- Name variables after what they hold in the domain, not their type or role in an algorithm.
- Prefer `recipient` over `user`, `enrollment_fee` over `amount`, `due_date` over `date2`.
- Iterator variables in a collection loop should carry the domain term: `questions.each do |question|`, not `items.each do |i|`.
- Boolean variables and parameters read as domain assertions: `allow_retakes`, `requires_approval`, not `flag`, `bool_val`.

### Method Arguments and Keyword Parameters
- Prefer keyword arguments when two or more arguments share a type and the order is not self-evident.
- `enroll(user: user, course: course)` beats `enroll(user, course)` when both are objects.

### Avoid
- Abbreviations that are not universal in the domain (`usr`, `cfg`, `mgr`, `tmp`).
- Technical suffixes that leak implementation (`_hash`, `_array`, `_list`) unless the data structure is itself the domain concept.
- Generic container names (`data`, `result`, `obj`, `thing`, `item`) outside of very narrow local scope.
- Negated names that force double-negation reading: `not_expired?` is harder to read than `active?`.

## Domain-Based Language in Practice

Bad — technical vocabulary leaks into names:
```ruby
def process_data(hash_map)
  hash_map.each do |k, v|
    update_record(k, v.to_f)
  end
end
```

Good — reads like domain conversation:
```ruby
def apply_price_adjustments(trade_adjustments)
  trade_adjustments.each do |instrument, adjustment|
    instrument.reprice(adjustment)
  end
end
```

Bad — type used instead of domain concept:
```ruby
salary = 4500.75          # float
end_date = "2026-06-30"   # string
```

Good — domain types with constraints and meaning:
```ruby
salary = Money.new(amount: 4500.75, currency: :usd)
contract_end = ContractDate.new("2026-06-30")
```

## Ruby-Specific Guidance
- Boolean predicate methods end in `?`: `enrolled?`, `published?`, `overdue?`.
- Destructive/mutating methods end in `!` only when a safe counterpart exists: `publish` vs `publish!`.
- Constants use `SCREAMING_SNAKE_CASE` and are named after the domain value: `MAX_ENROLLMENT_SIZE`, `DEFAULT_PASSING_SCORE`.
- Module and class names use `PascalCase`; all other names use `snake_case`.

## Questions to Ask Before Naming
1. If a domain expert reads this name, does it mean the same thing to them as it does to you?
2. Does the name carry its intent without requiring a comment?
3. Would renaming this reveal a missing domain concept that should be modeled explicitly?
4. Does the name say *what* it is, not *how* it is stored or processed?
