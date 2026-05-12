class Article < ApplicationRecord
  self.ignored_columns += %w[status]

  extend Mobility
  include TranslationMetadata

  translates :title, :slug, :excerpt, :cover_image_caption, backend: :table

  extend FriendlyId
  friendly_id :title, use: [ :slugged, :mobility ]
  WORDS_PER_MINUTE = 200
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
  after_save :sync_original_translation_status

  STATUS_VALUES = { "draft" => 0, "published" => 1, "archived" => 2 }.freeze

  SLUG_FORMAT = /\A[a-z0-9-]+\z/
  UUID_FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/

  # Safety-net validations (paranoid mode, apply in all environments)
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

    case normalized
    when "archived"
      self.archived_at ||= Time.current
    when "published"
      self.archived_at = nil
      @pending_original_translation_status = :published
    else
      self.archived_at = nil
      self.published_at = nil if normalized == "draft"
      @pending_original_translation_status = :draft
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
    update!(status: "published")
  end

  def status_draft!
    update!(status: "draft")
  end

  def trashed?
    deleted_at.present?
  end

  def archived?
    archived_at.present?
  end

  # Render markdown to HTML
  def html_body
    body.to_html
  end

  # Extract plain text for search/preview
  def searchable_content
    html_content = body.to_html
    ActionText::Content.new(html_content).to_plain_text
  end

  def plain_text_body
    ActionText::Content.new(html_body).to_plain_text.squish
  end

  def content_word_count
    plain_text_body.scan(/\b[\p{L}\p{N}]+(?:['’\-][\p{L}\p{N}]+)*\b/u).size
  end

  def estimated_reading_time_minutes
    return 0 if content_word_count.zero?

    [ (content_word_count / WORDS_PER_MINUTE.to_f).ceil, 1 ].max
  end

  private

  def ensure_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def assign_original_locale
    self.original_locale ||= I18n.locale.to_s
  end

  def normalize_translated_attributes
    # Rails `normalizes` doesn't apply to Mobility-backed attributes; normalize explicitly.
    self.title = title.strip if title.present?
    self.slug  = slug.strip.downcase if slug.present?
  end

  def body_length_within_limit
    return unless body.present?

    if body.content.to_s.length > 100_000
      errors.add(:body, I18n.t("dry_schema.errors.max_size?", num: 100_000))
    end
  end

  def published_at_required_for_published
    intends_published = (@pending_original_translation_status == :published) || status_published?
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

  def find_or_build_original_translation
    locale = original_locale.presence || I18n.locale.to_s

    article_translations.find_by(locale: locale) ||
      article_translations.detect { |translation| translation.locale.to_s == locale } ||
      article_translations.build(locale: locale)
  end

  def sync_original_translation_status
    return if @pending_original_translation_status.nil?

    translation = article_translations.find_by(locale: original_locale)
    return if translation.blank?

    target_status = ArticleTranslation.statuses[@pending_original_translation_status]
    return if target_status.nil? || translation[:status] == target_status

    translation.update_column(:status, target_status)
  ensure
    @pending_original_translation_status = nil
  end

  def cover_image_is_valid
    return unless cover_image.attached?

    unless ALLOWED_COVER_IMAGE_CONTENT_TYPES.include?(cover_image.blob.content_type)
      errors.add(:cover_image, I18n.t("articles.errors.invalid_cover_image_content_type"))
      return
    end

    if cover_image.blob.byte_size > MAX_COVER_IMAGE_SIZE
      errors.add(:cover_image, I18n.t("articles.errors.invalid_cover_image_size", max_size_mb: MAX_COVER_IMAGE_SIZE / 1.megabyte))
    end

    width, height = cover_image_dimensions

    if width.blank? || height.blank?
      errors.add(:cover_image, I18n.t("articles.errors.invalid_cover_image_dimensions"))
      return
    end

    return if width >= MIN_COVER_IMAGE_WIDTH && height >= MIN_COVER_IMAGE_HEIGHT

    errors.add(
      :cover_image,
      I18n.t(
        "articles.errors.cover_image_too_small",
        min_width: MIN_COVER_IMAGE_WIDTH,
        min_height: MIN_COVER_IMAGE_HEIGHT
      )
    )
  end

  def cover_image_dimensions
    pending_change = attachment_changes["cover_image"]
    pending_attachable = pending_change&.attachable

    if pending_attachable.present?
      dimensions = dimensions_from_attachable(pending_attachable)
      return dimensions if dimensions.compact.size == 2
    end

    cover_image.blob.analyze unless cover_image.blob.analyzed?

    width = cover_image.blob.metadata[:width] || cover_image.blob.metadata["width"]
    height = cover_image.blob.metadata[:height] || cover_image.blob.metadata["height"]

    return [ width, height ] if width.present? && height.present?

    cover_image.blob.open do |file|
      image = MiniMagick::Image.read(File.binread(file.path))
      return image.dimensions
    end
  rescue MiniMagick::Error, ActiveStorage::FileNotFoundError
    [ nil, nil ]
  end

  def dimensions_from_io(io)
    bytes = io.read
    io.rewind if io.respond_to?(:rewind)

    MiniMagick::Image.read(bytes).dimensions
  rescue MiniMagick::Error
    [ nil, nil ]
  end

  def dimensions_from_attachable(attachable)
    if attachable.is_a?(Hash)
      return dimensions_from_io(attachable[:io]) if attachable[:io].present?

      return [ nil, nil ]
    end

    return dimensions_from_io(attachable.tempfile) if attachable.respond_to?(:tempfile)
    return dimensions_from_io(attachable) if attachable.respond_to?(:read)

    [ nil, nil ]
  end
end
