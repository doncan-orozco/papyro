class ArticleTranslation < ApplicationRecord
  self.ignored_columns += %w[published is_approved]

  STATUS_VALUES = { draft: 0, in_review: 1, published: 2 }.freeze

  belongs_to :article, inverse_of: :article_translations

  # Translation publication workflow: draft → in_review → published
  enum :status, STATUS_VALUES, prefix: true, scopes: false

  validates :excerpt, length: { maximum: 500 }, allow_nil: true
  validates :cover_image_caption, length: { maximum: Article::COVER_IMAGE_CAPTION_MAX_LENGTH }, allow_nil: true
end
