---
name: models
description: Golden archetype for ActiveRecord models. Enforces the "Skinny Model" pattern with strict file layout, delegates complex logic to Query Objects and Custom Validators. Apply to all files in `app/models/`.
---

# Application Active Record Model Pattern

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

### Example: Article Model Layout

```ruby
class Article < ApplicationRecord
  # 1. ignored_columns (if needed)
  # (only during active migration safety window)

  # 2. Constants
  COVER_IMAGE_CAPTION_MAX_LENGTH = 255
  SLUG_FORMAT = /\A[a-z0-9-]+\z/
  UUID_FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/

  # 3. Mixins
  extend Mobility
  extend FriendlyId
  include TranslationMetadata

  # 4. Third-Party Macros
  translates :title, :slug, :excerpt, :cover_image_caption, backend: :table
  friendly_id :title, use: [ :slugged, :mobility ]
  has_markdown :body
  has_one_attached :cover_image

  # 5. Associations
  belongs_to :user
  has_many :article_translations, inverse_of: :article, dependent: :destroy
  has_one :pinned_author_profile,
    class_name: "AuthorProfile",
    foreign_key: :pinned_article_id,
    inverse_of: :pinned_article,
    dependent: :nullify

  # 6. Callbacks
  before_validation :ensure_uuid, on: :create
  before_validation :assign_original_locale, on: :create
  before_validation :normalize_translated_attributes

  # 7. Validations
  validates :user, presence: true
  validates :uuid, presence: true, uniqueness: true, length: { is: 36 }, format: { with: UUID_FORMAT }
  validates :title, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 255 }, format: { with: SLUG_FORMAT }
  validates :excerpt, length: { maximum: 500 }, allow_nil: true
  validates_with CoverImageValidator, if: ->(record) { record.cover_image.attached? }
  validates_with ArticleBodyValidator
  validates_with ArticlePublishingValidator

  # 8. Attributes (rare - only for truly derived state)
  # (none in this example)

  # 9. Public Instance Methods
  def published?
    return false if trashed? || archived?
    original_translation_published? && published_at.present?
  end

  def status
    return "archived" if archived?
    return "published" if published?
    "draft"
  end

  def draft?
    !trashed? && !archived? && !published?
  end

  def trashed?
    deleted_at.present?
  end

  def archived?
    archived_at.present?
  end

  # 10. Private Methods
  private

  def ensure_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def assign_original_locale
    self.original_locale ||= I18n.locale.to_s
  end

  def normalize_translated_attributes
    self.title = title.strip if title.present?
    self.slug = slug.strip.downcase if slug.present?
  end

  def original_translation_published?
    translation = if association(:article_translations).loaded?
      article_translations.find { |item| item.locale == original_locale }
    else
      article_translations.find_by(locale: original_locale)
    end
    translation&.status_published? || false
  end
end
```

---

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
def status_published?; published_at.present?; end
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

## MANDATORY RULE: ORM Performance & Memory (N+1 Prevention)

### In-Memory Finding Pattern

When querying a `has_many` association **from within an instance method**, assume the association might already be eager-loaded in memory (via `.includes` in a Query Object or controller).

**Do NOT use `.find_by` or `.where` inside instance methods if evaluating a loaded association. It will trigger an N+1 database query directly to the database even if the association was already eager-loaded.**

**Use the Ruby enumerable `.find` to search the loaded array in memory. Only fall back to `.find_by` if you know the association was not pre-loaded.**

### Forbidden — Hidden N+1 Query

```ruby
# FORBIDDEN — Triggers an N+1 database query for every article
# even if article_translations were already eager-loaded
def original_translation_published?
  article_translations.find_by(locale: original_locale)&.status_published?
end

# Usage in controller:
# articles = Articles::PublishedQuery.call.includes(:article_translations)
# articles.each { |a| a.original_translation_published? }  # N+1 queries!
```

### Correct — Searches Memory First, Falls Back

```ruby
# CORRECT — Searches the loaded memory array; zero N+1s
def original_translation_published?
  translation = if association(:article_translations).loaded?
    article_translations.find { |item| item.locale == original_locale }
  else
    article_translations.find_by(locale: original_locale)
  end
  translation&.status_published? || false
end
```

The pattern:
1. Check if the association is already loaded: `association(:article_translations).loaded?`
2. If loaded, search the in-memory array with `.find { ... }`
3. If not loaded, fall back to `.find_by` for a single query

This pattern is safe and performant whether or not the association was pre-loaded.

---

## MANDATORY RULE: Never Create Setter Shims

**Do not create `attr_writer` or setter methods for attributes that are not stored in the model.**

If an attribute is not a real database column or derived state that you own, do not create a setter. The model will naturally reject unknown attributes, which is the correct behavior.

### Forbidden — The Setter Shim Anti-Pattern

```ruby
# FORBIDDEN — This looks like the model owns "status", but it doesn't
def status=(value)
  # Absorbs the assignment silently; caller has no idea it's ignored
  @status = value
end

# Later, when callers try to mass-assign:
article.assign_attributes(status: "draft")  # Silently ignored; no error
```

This creates a **leaky abstraction**:
- The model claims to accept `status:`, but doesn't persist it
- Callers have no feedback that their input was discarded
- Tests pass because the assignment doesn't raise an error
- Later refactors break silently

### Correct — Let the Model Reject Unknown Attributes

```ruby
# CORRECT — No setter
class Article < ApplicationRecord
  def status
    return "archived" if archived?
    return "published" if published?
    "draft"
  end

  # No status= method
end

# If code tries to mass-assign status, it fails loudly:
article.assign_attributes(status: "draft")
# => ActiveModel::UnknownAttributeError: unknown attribute 'status' for Article.

# This error is the correct signal: handle intent in the Operation layer
```

**The right place to handle `status:` input:** In the operation, extract it **before** mass-assigning to the model.

```ruby
# app/concepts/articles/operation/create.rb
module Articles
  module Operation
    class Create < ApplicationOperation
      def call(params:, user:)
        # Extract intent BEFORE model mass-assignment
        publish_requested = params[:status].to_s == "published"
        
        # Validate that if publishing, published_at is present
        if publish_requested && params[:published_at].blank?
          model = Article.new(params.except(:status))
          model.errors.add(:published_at, I18n.t("errors.messages.published_at_required_for_published"))
          return fail_with_model!(model)
        end

        # Strip status before persistence
        article = user.articles.build(params.except(:status))
        
        return Success(article) if article.save
        fail_with_model!(article)
      end
    end
  end
end
```

---

## Multi-Language / Mobility Conventions

If the model is translated using the `Mobility` gem, follow these rules:

### 1. No Translation Columns on Parent
**Do not store translated fields (title, excerpt) on the parent table.** They belong exclusively in the `_translations` table.

```ruby
# FORBIDDEN — Never do this
create_table :articles do |t|
  t.string :title          # ← NO! Title should be in article_translations
  t.string :slug           # ← NO! Slug should be in article_translations
  t.references :user
  t.timestamps
end

# CORRECT — Only locale-agnostic fields on parent
create_table :articles do |t|
  t.string :uuid, null: false
  t.references :user, null: false
  t.datetime :published_at
  t.datetime :archived_at
  t.datetime :deleted_at
  t.string :original_locale, null: false
  t.timestamps
end

create_table :article_translations do |t|
  t.references :article, null: false
  t.string :locale, null: false
  t.string :title, null: false
  t.string :slug, null: false
  t.string :excerpt
  t.string :cover_image_caption
  t.text :body_content
  t.string :status, null: false
  t.datetime :published_at
  t.timestamps
end
```

### 2. Store Original Locale
**Always store `original_locale` as a string on the parent table.** This allows for SEO fallbacks without querying the translation table on every request.

```ruby
class Article < ApplicationRecord
  validates :original_locale, presence: true, inclusion: { 
    in: ->(_record) { I18n.available_locales.map(&:to_s) } 
  }
  
  def original_translation_published?
    translation = if association(:article_translations).loaded?
      article_translations.find { |t| t.locale == original_locale }
    else
      article_translations.find_by(locale: original_locale)
    end
    translation&.status_published? || false
  end
end
```

### 3. No Display Helpers
**Do not write wrapper methods like `display_title`.** Use Mobility's native overriding: calling `model.title` automatically handles locale routing and fallbacks.

```ruby
# FORBIDDEN — Redundant and confusing
def display_title
  I18n.with_locale(current_locale) { title }
end

# CORRECT — Mobility handles it
article.title  # Automatically uses current I18n.locale and falls back per Mobility config
```

---

## Related Skills & Boundaries

**Apply these companion skills in order:**

1. **[`query-object-pattern` Skill](../query-object-pattern/SKILL.md)** — When you need to find or filter collections. Models have NO scopes; all queries go here.

2. **[`layered-validation-operation-pattern` Skill](../layered-validation-operation-pattern/SKILL.md)** — When you need to create/update/delete. Models are simple; Complex validation logic and state mutation go into Contracts and Operations.

3. **[`naming-conventions` Skill](../naming-conventions/SKILL.md)** — When naming model attributes, methods, and classes. Use domain language.

4. **[`i18n` Skill](../i18n/SKILL.md)** — When using `Mobility` for translations. Translation keys, locale switching, and fallback handling.

5. **[`backend-anti-patterns` Skill](../backend-anti-patterns/SKILL.md)** — When reviewing model code. Fast rejection list for common mistakes.

6. **[`error-handling` Skill](../error-handling/SKILL.md)** — When models interact with operations and controllers. Understand failure payloads and error injection.

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
