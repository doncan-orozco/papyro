class Article < ApplicationRecord
  WORDS_PER_MINUTE = 200

  belongs_to :user
  has_markdown :body
  has_one_attached :cover_image

  normalizes :title, with: ->(value) { value.strip }
  normalizes :slug, with: ->(value) { value.strip.downcase }

  enum :status, { draft: 0, published: 1, archived: 2 }, prefix: true

  SLUG_FORMAT = /\A[a-z0-9-]+\z/

  # Safety-net validations (paranoid mode, apply in all environments)
  validates :user, presence: true
  validates :title, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 255 }, format: { with: SLUG_FORMAT }
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :excerpt, length: { maximum: 500 }, allow_nil: true
  validate :body_length_within_limit
  validate :published_at_required_for_published
  validate :published_at_cannot_be_in_future, if: :published_at?

  def published?
    status_published? && published_at.present?
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

  # Use slug in URLs instead of ID
  def to_param
    slug
  end

  private

  def body_length_within_limit
    return unless body.present?

    if body.content.to_s.length > 100_000
      errors.add(:body, I18n.t("dry_schema.errors.max_size?", num: 100_000))
    end
  end

  def published_at_required_for_published
    return unless status_published? && published_at.blank?

    errors.add(:published_at, I18n.t("errors.messages.published_at_required_for_published"))
  end

  def published_at_cannot_be_in_future
    return unless published_at > Time.current

    errors.add(:published_at, I18n.t("errors.messages.published_at_future"))
  end
end
