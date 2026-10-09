# Model Layout Example

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
    translation&.published? || false
  end
end
```

---
