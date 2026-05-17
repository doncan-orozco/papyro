class ArticleTranslation < ApplicationRecord
  STATUS_VALUES = { draft: 0, in_review: 1, published: 2 }.freeze

  belongs_to :article, inverse_of: :article_translations

  enum :status, STATUS_VALUES

  validates :locale, presence: true
  validates :locale, uniqueness: { scope: :article_id }
  validates :slug, uniqueness: { scope: :locale }, allow_nil: true
  validates :excerpt, length: { maximum: 500 }, allow_nil: true
  validates :cover_image_caption, length: { maximum: Article::COVER_IMAGE_CAPTION_MAX_LENGTH }, allow_nil: true

  # A helper to know if this translation is visible to the public
  def is_public?
    published? && published_at.present? && published_at <= Time.current
  end
end
