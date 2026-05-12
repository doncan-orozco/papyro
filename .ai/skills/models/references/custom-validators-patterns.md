# Custom Validators: Extracted Validation Patterns

When a validation is too complex for simple `validates` declarations, extract it to a Custom Validator in `app/validators/`.

## When to Extract

Extract to a Custom Validator when:
- Validation requires `if` / `elsif` / `else` logic
- Validation checks multiple attributes or associations
- Validation needs to query the database (uniqueness beyond ActiveRecord's built-in)
- Validation involves file operations (size, dimensions, MIME type analysis)
- Validation is domain-complex and deserves its own class for clarity

## Pattern: Simple Custom Validator

### Example: ArticleBodyValidator

```ruby
# app/validators/article_body_validator.rb
class ArticleBodyValidator < ActiveModel::Validator
  def validate(record)
    # Early return if no body
    return if record.body.blank?
    
    # Validate based on domain state
    if record.published? && record.body.length < 100
      record.errors.add(:body, :too_short, 
        message: "must be at least 100 characters for published articles")
    end
  end
end

# app/models/article.rb
class Article < ApplicationRecord
  validates_with ArticleBodyValidator
end
```

**Why extract?**
- The rule is domain-complex: "Published articles must have substantial content"
- It requires calling another method (`record.published?`)
- It is self-contained and reusable

---

## Pattern: Conditional Custom Validator

### Example: ArticlePublishingValidator

```ruby
# app/validators/article_publishing_validator.rb
class ArticlePublishingValidator < ActiveModel::Validator
  def validate(record)
    return unless requires_future_date?(record)
    
    if record.published_at.present? && record.published_at <= Time.current
      record.errors.add(:published_at, :invalid, 
        message: "must be in the future")
    end
  end

  private

  def requires_future_date?(record)
    # Only applies if scheduling future publication
    record.published_at_changed? && record.published_at.present?
  end
end

# app/models/article.rb
class Article < ApplicationRecord
  validates_with ArticlePublishingValidator
end
```

**Why extract?**
- The logic checks a specific domain concern (scheduling)
- It has conditional logic that only applies in certain cases
- The private helper method makes the intent clear

---

## Pattern: File Analysis Validator

### Example: CoverImageValidator

```ruby
# app/validators/cover_image_validator.rb
class CoverImageValidator < ActiveModel::Validator
  MIN_COVER_IMAGE_WIDTH = 1920
  MIN_COVER_IMAGE_HEIGHT = 1080
  MAX_COVER_IMAGE_SIZE = 5.megabytes

  def validate(record)
    return unless record.cover_image.attached?
    
    validate_content_type(record)
    validate_file_size(record)
    validate_dimensions(record)
  end

  private

  def validate_content_type(record)
    allowed_types = %w[image/jpeg image/png image/webp]
    if record.cover_image.content_type.not_in?(allowed_types)
      record.errors.add(:cover_image, :invalid_content_type,
        message: "must be JPEG, PNG, or WebP")
    end
  end

  def validate_file_size(record)
    if record.cover_image.blob.byte_size > MAX_COVER_IMAGE_SIZE
      record.errors.add(:cover_image, :invalid_file_size,
        message: "must be smaller than 5MB")
    end
  end

  def validate_dimensions(record)
    image = MiniMagick::Image.read(record.cover_image.download)
    width = image.width.to_i
    height = image.height.to_i
    
    if width < MIN_COVER_IMAGE_WIDTH || height < MIN_COVER_IMAGE_HEIGHT
      record.errors.add(:cover_image, :invalid_dimensions,
        message: "must be at least #{MIN_COVER_IMAGE_WIDTH}x#{MIN_COVER_IMAGE_HEIGHT} pixels")
    end
  rescue => e
    record.errors.add(:cover_image, :invalid_file,
      message: "could not be analyzed: #{e.message}")
  end
end

# app/models/article.rb
class Article < ApplicationRecord
  validates_with CoverImageValidator, if: ->(record) { record.cover_image.attached? }
end
```

**Why extract?**
- File operations are complex and deserve their own class
- Multiple validations (type, size, dimensions) are grouped
- Error handling is centralized
- Easy to test independently

---

## Pattern: Cross-Model Validator

### Example: UserEmailValidator

When a validation needs to check across associations:

```ruby
# app/validators/user_email_validator.rb
class UserEmailValidator < ActiveModel::Validator
  def validate(record)
    # Check that the email is not already used by another account
    existing = User.where(email: record.email).where.not(id: record.id).first
    
    if existing.present?
      record.errors.add(:email, :taken,
        message: "is already registered")
    end
  end
end

# app/models/user.rb
class User < ApplicationRecord
  validates_with UserEmailValidator
end
```

**Why extract?**
- The rule checks the database (more than ActiveRecord's built-in uniqueness)
- It is conditional (exclude self from the check)
- It is clear and reusable

---

## How Custom Validators Are Called

### In the Model

```ruby
class Article < ApplicationRecord
  validates_with ArticleBodyValidator
  validates_with ArticlePublishingValidator, if: ->(record) { record.published_at_changed? }
  validates_with CoverImageValidator, if: ->(record) { record.cover_image.attached? }
end
```

### In Dry Validation Contracts (Layered Validation Pattern)

For mutation flows, contracts validate *input structure*, and models validate *state*:

```ruby
# app/concepts/articles/contract/create.rb
module Articles
  module Contract
    class Create < Dry::Validation::Contract
      params do
        required(:title).filled(:string, max_size?: 255)
        required(:body).filled(:string)
      end
    end
  end
end

# app/concepts/articles/operation/create.rb
module Articles
  module Operation
    class Create < ApplicationOperation
      def call(params:, user:)
        # Contract validates input structure
        contract_result = Articles::Contract::Create.new.call(params)
        return fail_with_contract_errors(contract_result) if contract_result.failure?

        # Model validates state (including custom validators)
        article = Article.new(contract_result.to_h)
        return Success(article) if article.save
        fail_with_model!(article)
      end
    end
  end
end
```

---

## Best Practices

1. **Name validators after what they validate**: `ArticleBodyValidator`, not `BodyChecker`
2. **Keep each validator focused**: One domain concern per validator
3. **Extract constants**: `MIN_SIZE`, `MAX_SIZE`, `ALLOWED_TYPES` at the top of the validator
4. **Use conditional `:if` clauses**: Only run validators when needed (`if: ->(r) { r.published? }`)
5. **Provide clear error messages**: Use i18n keys for consistency
6. **Test validators independently**: They are easy to unit test in isolation
7. **Don't query excessively**: If a validator needs complex queries, consider moving logic to an Operation

---

## Common Mistakes to Avoid

### ❌ Validator That Modifies State

```ruby
# FORBIDDEN — Validators should not mutate the record
class BadValidator < ActiveModel::Validator
  def validate(record)
    record.slug = record.title.parameterize  # DON'T DO THIS
  end
end
```

**Why?** Validators are for checking constraints, not transforming data. Use callbacks for normalization.

### ❌ Validator That Raises Exceptions

```ruby
# FORBIDDEN — Use errors.add, never raise
class BadValidator < ActiveModel::Validator
  def validate(record)
    raise "Invalid!" if bad_condition  # DON'T DO THIS
  end
end
```

**Why?** Exceptions are for unexpected errors, not validation failures. Return errors via `.errors.add`.

### ❌ Validator That Orchestrates Complex Logic

```ruby
# FORBIDDEN — Don't put business logic in validators
class BadValidator < ActiveModel::Validator
  def validate(record)
    # Publishing involves multiple steps; this belongs in an Operation
    if should_publish?(record)
      record.published_at = Time.current
      record.status = "published"
      record.save!
    end
  end
end
```

**Why?** State mutations belong in Operations, not validators. Validators check constraints only.

---

## See Also

- **[SKILL.md](../SKILL.md)** — Extract Heavy Validations rule
- **[../layered-validation-operation-pattern/SKILL.md](../../layered-validation-operation-pattern/SKILL.md)** — How validation layers work
- **Article Model Example** — `app/models/article.rb` uses `ArticleBodyValidator`, `ArticlePublishingValidator`, `CoverImageValidator`
