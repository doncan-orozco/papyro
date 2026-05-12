class Article < ApplicationRecord
  self.ignored_columns += %w[status]

  extend Mobility
  include TranslationMetadata

  translates :title, :slug, :excerpt, :cover_image_caption, backend: :table

  extend FriendlyId
  friendly_id :title, use: [ :slugged, :mobility ]

  COVER_IMAGE_CAPTION_MAX_LENGTH = 255
  MAX_COVER_IMAGE_SIZE = 5.megabytes
  MIN_COVER_IMAGE_WIDTH = 400
  MIN_COVER_IMAGE_HEIGHT = 400
  ALLOWED_COVER_IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze

  scope :kept, -> { where(deleted_at: nil) }
  scope :trashed, -> { where.not(deleted_at: nil) }
  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :with_original_translation, lambda {
    joins("LEFT JOIN article_translations AS original_translations ON original_translations.article_id = articles.id AND original_translations.locale = articles.original_locale")
  }
  scope :status_published, lambda {
    with_original_translation
      .where(original_translations: { status: ArticleTranslation.statuses[:published] })
      .where.not(published_at: nil)
      .distinct
  }
  scope :status_draft, lambda {
    with_original_translation
      .where("original_translations.status IS NULL OR original_translations.status != ?", ArticleTranslation.statuses[:published])
      .distinct
  }

  belongs_to :user
  has_many :article_translations, inverse_of: :article, dependent: :destroy
  has_one :pinned_author_profile,
    class_name: "AuthorProfile",
    foreign_key: :pinned_article_id,
    inverse_of: :pinned_article,
    dependent: :nullify
  has_markdown :body
  has_one_attached :cover_image

  before_validation :ensure_uuid, on: :create
  before_validation :assign_original_locale, on: :create
  before_validation :normalize_translated_attributes

  STATUS_VALUES = { "draft" => 0, "published" => 1, "archived" => 2 }.freeze

  SLUG_FORMAT = /\A[a-z0-9-]+\z/
  UUID_FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/

  validates :user, presence: true
  validates :uuid, presence: true, uniqueness: true, length: { is: 36 }, format: { with: UUID_FORMAT }
  validates :title, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 255 }, format: { with: SLUG_FORMAT }
  validates :original_locale, presence: true, inclusion: { in: ->(_record) { I18n.available_locales.map(&:to_s) } }
  validates :excerpt, length: { maximum: 500 }, allow_nil: true
  validates :cover_image_caption, length: { maximum: COVER_IMAGE_CAPTION_MAX_LENGTH }, allow_nil: true
  validate :cover_image_is_valid
  validate :body_length_within_limit
  validate :published_at_required_for_published
  validate :published_at_cannot_be_in_future, if: :published_at?

  def published?
    return false if trashed? || archived?

    original_translation_published? && published_at.present?
  end

  def self.statuses
    STATUS_VALUES
  end

  def status
    return "archived" if archived?
    return "published" if status_published?

    "draft"
  end

  def status=(value)
    normalized = value.to_s
    return if normalized.blank?

    @requested_status = normalized if new_record?

    case normalized
    when "archived"
      self.archived_at ||= Time.current
    when "published"
      self.archived_at = nil
    else
      self.archived_at = nil
      self.published_at = nil if normalized == "draft"
    end
  end

  def status_published?
    !archived? && original_translation_published? && published_at.present?
  end

  def status_draft?
    !archived? && !status_published?
  end

  def status_archived?
    archived?
  end

  def status_published!
    transition_status_with!(Articles::Operation::Publish.new)
  end

  def status_draft!
    transition_status_with!(Articles::Operation::Unpublish.new)
  end

  def trashed?
    deleted_at.present?
  end

  def archived?
    archived_at.present?
  end

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

  def body_length_within_limit
    return unless body.present?
    return unless body.content.to_s.length > 100_000

    errors.add(:body, I18n.t("dry_schema.errors.max_size?", num: 100_000))
  end

  def published_at_required_for_published
    intends_published = (new_record? && @requested_status == "published") || status_published?
    return unless intends_published && published_at.blank?

    errors.add(:published_at, I18n.t("errors.messages.published_at_required_for_published"))
  end

  def published_at_cannot_be_in_future
    return unless published_at > Time.current

    errors.add(:published_at, I18n.t("errors.messages.published_at_future"))
  end

  def original_translation_published?
    article_translations.find_by(locale: original_locale)&.status_published? || false
  end

  def cover_image_is_valid
    Articles::CoverImageValidation.new(self).validate
  end

  def transition_status_with!(operation)
    result = operation.call(model: self)
    return result.value![:model] if result.success?

    raise ActiveRecord::RecordInvalid, result.failure[:model] || self
  end
end
