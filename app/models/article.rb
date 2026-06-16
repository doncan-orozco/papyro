class Article < ApplicationRecord
  COVER_IMAGE_CAPTION_MAX_LENGTH = 255
  SLUG_FORMAT = /\A[a-z0-9-]+\z/
  UUID_FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/

  extend Mobility
  extend FriendlyId
  include TranslationMetadata

  translates :title, :slug, :excerpt, :cover_image_caption, backend: :table
  friendly_id :title, use: [ :slugged, :mobility ]
  has_markdown :body

  belongs_to :user
  has_one :pinned_author_profile,
    class_name: "AuthorProfile",
    foreign_key: :pinned_article_id,
    inverse_of: :pinned_article,
    dependent: :nullify
  has_one_attached :cover_image
  has_many_attached :generated_og_images

  before_validation :ensure_uuid, on: :create
  before_validation :assign_original_locale, on: :create
  before_validation :normalize_translated_attributes

  validates :user, presence: true
  validates :uuid, presence: true, uniqueness: true, length: { is: 36 }, format: { with: UUID_FORMAT }
  validates :title, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 255 }, format: { with: SLUG_FORMAT }
  validates :original_locale, presence: true, inclusion: { in: ->(_record) { I18n.available_locales.map(&:to_s) } }
  validates :excerpt, length: { maximum: 500 }, allow_nil: true
  validates :cover_image_caption, length: { maximum: COVER_IMAGE_CAPTION_MAX_LENGTH }, allow_nil: true
  validates_with Articles::Validator::CoverImage, if: ->(record) { record.cover_image.attached? }
  validates_with Articles::Validator::Body
  validates_with Articles::Validator::Publishing

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
    translation = translations.find_by(locale: original_locale)
    translation&.published? || false
  end
end
