class Article < ApplicationRecord
  WORDS_PER_MINUTE = 200

  belongs_to :user
  has_markdown :body
  has_one_attached :cover_image

  normalizes :title, with: ->(value) { value.strip }
  normalizes :slug, with: ->(value) { value.strip.downcase }

  enum :status, { draft: 0, published: 1, archived: 2 }, prefix: true

  # Safety-net validations (paranoid mode, apply in all environments)
  # Business validations happen in Contracts
  validates :title, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :excerpt, length: { maximum: 500 }, allow_nil: true

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
end
