# Article Model: Annotated Walkthrough

This document annotates the production `Article` model (`app/models/article.rb`) as a reference implementation of the model archetype. Every section maps back to the SKILL.md layout rules.

## Section 1: Constants

```ruby
COVER_IMAGE_CAPTION_MAX_LENGTH = 255
SLUG_FORMAT = /\A[a-z0-9-]+\z/
UUID_FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/
```

**Why here?**
- Constants are the first thing readers encounter
- They define domain constraints and are referenced in validations
- They are immutable and configuration-like

---

## Section 2: Mixins

```ruby
extend Mobility
extend FriendlyId
include TranslationMetadata
```

**Why here?**
- Mixins set up the class's behavior before anything else
- They affect how other macros and associations work
- They must be loaded before the translations macro

---

## Section 3: Third-Party Macros

```ruby
translates :title, :slug, :excerpt, :cover_image_caption, backend: :table
friendly_id :title, use: [ :slugged, :mobility ]
has_markdown :body
has_one_attached :cover_image
```

**Why here?**
- These are gem-level declarations that affect the schema and behavior
- `translates` must come before associations that reference translations
- They are "declarative" in nature—not imperative logic

---

## Section 4: Associations

```ruby
belongs_to :user
has_many :article_translations, inverse_of: :article, dependent: :destroy
has_one :pinned_author_profile,
  class_name: "AuthorProfile",
  foreign_key: :pinned_article_id,
  inverse_of: :pinned_article,
  dependent: :nullify
has_markdown :body
has_one_attached :cover_image
```

**Why here?**
- Associations define the core relationships this model has
- They are declarative and easy to scan
- They set up inverse relationships and dependency cleanup

---

## Section 5: Callbacks

```ruby
before_validation :ensure_uuid, on: :create
before_validation :assign_original_locale, on: :create
before_validation :normalize_translated_attributes
```

**Why here?**
- Callbacks are few and lightweight (not orchestrating complex flows)
- They prepare data for validation
- They are scoped to `:create` when possible to prevent side effects

**Important:** Complex state mutations do NOT go in callbacks. Those belong in Operations.

---

## Section 6: Validations

```ruby
validates :user, presence: true
validates :uuid, presence: true, uniqueness: true, length: { is: 36 }, format: { with: UUID_FORMAT }
validates :title, presence: true, length: { maximum: 255 }
validates :slug, presence: true, uniqueness: true, length: { maximum: 255 }, format: { with: SLUG_FORMAT }
validates :original_locale, presence: true, inclusion: { in: ->(_record) { I18n.available_locales.map(&:to_s) } }
validates :excerpt, length: { maximum: 500 }, allow_nil: true
validates :cover_image_caption, length: { maximum: COVER_IMAGE_CAPTION_MAX_LENGTH }, allow_nil: true
validates_with CoverImageValidator, if: ->(record) { record.cover_image.attached? }
validates_with ArticleBodyValidator
validates_with ArticlePublishingValidator
```

**Why here?**
- Simple declarative validations are grouped
- Custom validators are extracted (they reference complex logic)
- Validations are ordered from most common to most complex

**What's NOT here?**
- No `validates :status` — status is derived, not stored
- No complex if/else — those are in Custom Validators

---

## Section 7: Public Instance Methods

### State Predicates

```ruby
def published?
  return false if trashed? || archived?
  original_translation_published? && published_at.present?
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
```

**Pattern:**
- One predicate per state
- Reads as a question: `article.published?` → "Is this article published?"
- Consolidates related checks (publication requires both translation state AND `published_at`)

### Derived State Getter

```ruby
def status
  return "archived" if archived?
  return "published" if published?
  "draft"
end
```

**Important:**
- `status` is derived, not stored
- It is read-only — no `status=` setter exists
- It computes state from multiple database fields and predicates
- If callers need to set publication state, they use operations: `Articles::Operation::Publish`

---

## Section 8: Private Methods

### Callback Helpers

```ruby
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
```

**Why private?**
- These are implementation details for callbacks
- They normalize input before validation
- They should never be called directly from outside the model

### N+1-Safe Association Lookup

```ruby
def original_translation_published?
  translation = if association(:article_translations).loaded?
    article_translations.find { |item| item.locale == original_locale }
  else
    article_translations.find_by(locale: original_locale)
  end
  translation&.published? || false
end
```

**Why this pattern?**
- When `article_translations` is pre-loaded (via `.includes(:article_translations)` in a query), use in-memory `.find` to avoid a database query
- If not pre-loaded, fall back to `.find_by` for a single query
- This is transparent and performant whether the association was pre-loaded or not

**Lesson from refactor:**
- The original code used `.find_by` unconditionally, causing N+1 queries even when translations were eager-loaded
- This pattern was added to fix that performance trap

---

## What This Model Does NOT Have

- ❌ No named scopes (`scope :published, ...`) — all queries go to Query Objects
- ❌ No complex validation logic in the model — extracted to `ArticleBodyValidator`, `ArticlePublishingValidator`, `CoverImageValidator`
- ❌ No `status=` setter — status is derived, not assigned
- ❌ No `requested_status` attribute — publish intent is handled in operations, not stored
- ❌ No bloated callback orchestration — only lightweight normalization
- ❌ No display helpers like `display_title` — Mobility handles locale-aware title access natively

---

## Integration Points

### How Query Objects Use This Model

```ruby
# app/queries/articles/published_query.rb
module Articles
  class PublishedQuery < ApplicationQuery
    base_scope { Article.all }
    pipeline :filter_by_status, :apply_ordering
    
    private
    
    def filter_by_status(current_scope)
      current_scope.includes(:article_translations).where(article_translations: { status: :published })
    end
  end
end

# Usage:
articles = Articles::PublishedQuery.call
articles.each { |a| a.published? }  # No N+1 because translations are pre-loaded
```

### How Operations Use This Model

```ruby
# app/concepts/articles/operation/create.rb
module Articles
  module Operation
    class Create < ApplicationOperation
      def call(params:, user:)
        # Extract intent before model mass-assignment
        publish_requested = params[:status].to_s == "published"
        
        # Validate intent early
        if publish_requested && params[:published_at].blank?
          model = Article.new(params.except(:status))
          model.errors.add(:published_at, "is required for published articles")
          return fail_with_model!(model)
        end

        # Build and persist without the intent param
        article = user.articles.build(params.except(:status))
        return Success(article) if article.save
        fail_with_model!(article)
      end
    end
  end
end
```

---

## Key Takeaways

1. **Layout is predictable** — Any reader can scan the model in order and understand its structure
2. **State is derived** — `status` computes from database fields; no stored status attribute or shim setter
3. **Queries are external** — No scopes; all read logic is in Query Objects
4. **Validation is layered** — Simple checks in the model; complex checks in Custom Validators
5. **Performance is safe** — N+1 prevention is built into association lookups
6. **Translations are clean** — Mobility handles the complexity; the model just configures it
7. **Operations own intent** — Publish/unpublish logic and state mutation are in operations, not the model
