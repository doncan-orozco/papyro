---
name: models
description: "Golden archetype for ActiveRecord models. Use when creating or editing any file in `app/models/` or `app/validators/`: strict file layout, no named scopes (use query objects), extracted validators, state predicates, N+1 prevention, no setter shims, Mobility conventions."
---

# Application Active Record Model Pattern

## Quick Rules

Cite as `models R<n>`. Detail and examples follow below / in references/.

R1. **Strict file layout.** Order: ignored_columns, constants, mixins, third-party macros, associations, callbacks, validations, attributes, public methods, private methods. → detail: MANDATORY RULE: Strict File Layout
R2. **No named scopes.** Never declare `scope :x, -> {}`; query logic goes to Query Objects. → detail: MANDATORY RULE: No Named Scopes
R3. **Simple validations only.** Models hold only declarative Rails validations; no inline if/else `validates` blocks. → detail: MANDATORY RULE: Extract Heavy Validations
R4. **Extract heavy validations.** Multi-association, file size/dimension or branching validations go to a Custom Validator in `app/validators/`. → detail: references/custom-validators-patterns.md
R5. **State via predicates.** Expose state as consolidated boolean predicates (`published?`, `draft?`); callers never compare raw status or timestamp columns. → detail: MANDATORY RULE: State and Booleans Over Raw Status
R6. **Derived status is read-only.** Never define a `status=` (or any setter shim) for derived attributes; state changes go through Operations. → detail: references/orm-performance-and-setters.md
R7. **N+1-safe instance methods.** Search loaded associations in memory (`.find`/`detect`) first, falling back to `.find_by`. → detail: references/orm-performance-and-setters.md
R8. **No translation columns on parent.** Translated attributes live only in the `_translations` table; never as parent columns. → detail: references/mobility-conventions.md
R9. **Store original locale.** Keep `original_locale` as a string on the parent table. → detail: references/mobility-conventions.md
R10. **No display helpers for translations.** Do not add redundant wrappers around Mobility accessors. → detail: references/mobility-conventions.md
R11. **No orchestration in models.** No complex business logic, heavy querying, or callbacks that orchestrate write flows; Operations own that. → detail: What Models Are For
R12. **Domain-language names.** Attributes, methods and classes use domain language, not technical jargon. → detail: Verification Checklist

## What Models Are For

Models represent a **single row of data** from the database. Their responsibility is strictly:
- Define database associations and relationships
- Encapsulate simple validations (presence, length, format, uniqueness)
- Expose derived state checks (boolean predicates like `published?`, `draft?`)
- Configure third-party macros tied directly to the database (`Mobility`, `FriendlyId`, `has_markdown`)

Models are **NOT** for:
- Complex business logic (belongs in Operations)
- Heavy querying (belongs in Query Objects)
- Heavy validation logic (belongs in Custom Validators)
- State mutation orchestration (belongs in Operations)
- Setter shims for read-only derived attributes

---

## MANDATORY RULE: Strict File Layout

Models easily become "Big Balls of Mud" if not structured. **Every model MUST follow this exact top-to-bottom layout.** This creates a predictable table of contents and prevents hidden dependencies.

### Layout Order (Non-negotiable)

1. **`self.ignored_columns`** — If any columns are being removed (only during migration safety window)
2. **Constants** — Format regexes, max lengths, enums, fixed values
3. **Mixins** — `extend` and `include` statements (`extend Mobility`, `include TranslationMetadata`)
4. **Third-Party Macros** — Gems directly tied to the database (`translates`, `friendly_id`, `has_markdown`)
5. **Associations** — `belongs_to`, `has_many`, `has_one`, `has_one_attached`
6. **Callbacks** — `before_validation`, `before_save`, `after_commit`, etc.
7. **Validations** — `validates`, `validates_with`
8. **Attributes** — `attr_reader`, `attr_accessor` (rare; mostly for derived state)
9. **Public Instance Methods** — State checks (`published?`, `draft?`), simple formatting
10. **Private Methods** — Callback logic, internal helpers, default computations

> **Model Layout Example:** full annotated Article model → [references/layout-example.md](references/layout-example.md)

## MANDATORY RULE: No Named Scopes

**Named scopes (`scope :active, -> { ... }`) are FORBIDDEN in this codebase.**

Scopes leak query logic into the model and inevitably grow into complex, untestable SQL chains:
- Scopes create implicit dependencies that are hard to debug
- They hide the shape of the query from callers
- They violate the "single responsibility" principle
- They make the model responsible for *both* data representation and querying

**All query logic MUST be extracted to Domain Query Objects.** (See [`query-object-pattern` skill](../query-object-pattern/SKILL.md).)

The model should represent a single row of data and expose state via methods. Collections and queries are the responsibility of Query Objects.

### Forbidden

```ruby
# FORBIDDEN — query logic leaks into model
scope :active, -> { where(deleted_at: nil) }
scope :published, -> { where(status: :published) }
scope :by_category, ->(cat_id) { joins(:categories).where(categories: { id: cat_id }) }
```

### Correct

```ruby
# Query Objects handle all read logic
# app/queries/articles/published_query.rb
module Articles
  class PublishedQuery < ApplicationQuery
    base_scope { Article.all }
    pipeline :filter_by_status
    
    private
    
    def filter_by_status(current_scope)
      current_scope.where(status: :published)
    end
  end
end

# Model is clean, focused on a single row
class Article < ApplicationRecord
  # No scopes
end
```

---

## MANDATORY RULE: Extract Heavy Validations

Models should only contain **simple, declarative validations** provided by Rails:

```ruby
# OK — Simple, declarative
validates :title, presence: true, length: { maximum: 255 }
validates :slug, uniqueness: true, format: { with: SLUG_FORMAT }
validates :published_at, comparison: { greater_than: Time.current }, allow_nil: true
```

If a validation requires **complex if/else logic, touches multiple associations, or calculates file sizes/dimensions**, it MUST be extracted to a **Custom Validator** in `app/validators/`.

```ruby
# FORBIDDEN — Complex logic in the model
validates :body do |record|
  if record.status == :published && record.body.blank?
    record.errors.add(:body, "cannot be blank for published articles")
  elsif record.status == :draft && record.body.present? && record.body.length < 100
    record.errors.add(:body, "draft must be at least 100 characters when provided")
  end
end
```

### Correct Extraction

```ruby
# app/validators/article_body_validator.rb
class ArticleBodyValidator < ActiveModel::Validator
  def validate(record)
    return if record.body.present?
    
    if record.published?
      record.errors.add(:body, :blank, message: "cannot be blank for published articles")
    end
  end
end

# app/models/article.rb
class Article < ApplicationRecord
  validates_with ArticleBodyValidator
end
```

---

## MANDATORY RULE: State and Booleans Over Raw Status

Never force callers to check raw database values or magic strings. **Encapsulate all state checks into readable boolean methods.**

Consolidate overlapping state checks into semantic predicate methods to prevent bloat and ensure consistency.

### Forbidden — Repetitive and Fragile

```ruby
# FORBIDDEN — Bloat and inconsistency
def published?; published_at.present?; end
def is_published?; published_at.present?; end
def published_status?; status == "published"; end
def article_published?; published_at.present? && !archived?; end

# Callers check raw values
article.published_at.present? && !article.archived_at.present? && !article.deleted_at.present?
```

### Correct — Unified and Semantic

```ruby
# Single source of truth for publication state
def published?
  return false if trashed? || archived?
  original_translation_published? && published_at.present?
end

# Concise, domain-language predicates
def draft?
  !trashed? && !archived? && !published?
end

def trashed?
  deleted_at.present?
end

def archived?
  archived_at.present?
end

# Derived state getter (read-only, never assign to)
def status
  return "archived" if archived?
  return "published" if published?
  "draft"
end

# Caller code is clean
article.published?  # reads as: "Is the article published?"
article.draft?      # reads as: "Is the article a draft?"
```

**Important:** `status` is a **derived read-only property**, not a writable attribute. Do not create a `status=` setter. If you need to set publication state, use explicit operations (`Articles::Operation::Publish`, `Articles::Operation::Unpublish`).

---

> **ORM Performance and Setter Shims:** in-memory finding vs N+1, never create setter shims → [references/orm-performance-and-setters.md](references/orm-performance-and-setters.md)

> **Mobility Conventions on Models:** no translation columns on parent, store original locale, no display helpers → [references/mobility-conventions.md](references/mobility-conventions.md)

## Related Skills & Boundaries

**Apply these companion skills in order:**

1. **[`query-object-pattern` Skill](../query-object-pattern/SKILL.md)** — When you need to find or filter collections. Models have NO scopes; all queries go here.

2. **[`operation-pattern` Skill](../operation-pattern/SKILL.md) (see [layered validation](../operation-pattern/references/layered-validation.md))** — When you need to create/update/delete. Models are simple; Complex validation logic and state mutation go into Contracts and Operations.

3. **[`naming-conventions` Skill](../naming-conventions/SKILL.md)** — When naming model attributes, methods, and classes. Use domain language.

4. **[`i18n` Skill](../i18n/SKILL.md)** — When using `Mobility` for translations. Translation keys, locale switching, and fallback handling.


6. **[`controller` error handling](../controller/references/error-handling.md)** — When models interact with operations and controllers. Understand failure payloads and error injection.

---

## Verification Checklist

Before committing a model, verify:

- [ ] Layout is strict: Constants → Mixins → Macros → Associations → Callbacks → Validations → Attributes → Public → Private
- [ ] No named scopes (queries in Query Objects only)
- [ ] No complex if/else logic in validations (extracted to Custom Validators)
- [ ] State checks are boolean predicates (`published?`, `draft?`, etc.), not raw status comparisons
- [ ] No setter shims for read-only attributes
- [ ] N+1-safe instance methods use `.find` on loaded associations, fall back to `.find_by`
- [ ] Translations (if any) follow Mobility conventions: only on `_translations` table, `original_locale` stored on parent
- [ ] All method names are domain language, not technical jargon
- [ ] No ActiveRecord callbacks orchestrating write flows (Operations own that)
- [ ] Heavy file operations (image analysis, file size checks) are in Custom Validators
