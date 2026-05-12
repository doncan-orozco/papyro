class ArticleTranslation < ApplicationRecord
  self.ignored_columns += %w[published is_approved]

  belongs_to :article, inverse_of: :article_translations

  # Translation publication workflow: draft → in_review → published
  enum :status, { draft: 0, in_review: 1, published: 2 }, prefix: true

  # Legacy scopes (deprecated, use status enum instead)
  scope :published_translations, -> { status_published }

  # Status-based scopes
  scope :published, -> { status_published }
  scope :drafted, -> { status_draft }
  scope :in_review, -> { status_in_review }

  validates :excerpt, length: { maximum: 500 }, allow_nil: true
  validates :cover_image_caption, length: { maximum: Article::COVER_IMAGE_CAPTION_MAX_LENGTH }, allow_nil: true
end
