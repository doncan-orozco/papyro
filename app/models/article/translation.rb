# frozen_string_literal: true

# Pre-defined translation class for Article.
# Mobility's translates :title, backend: :table normally creates this class
# dynamically, but by pre-defining it we can add our custom validations,
# enums, and methods. Mobility's const_defined? check will find this class
# and use it instead of creating a new anonymous one.
class Article::Translation < Mobility::Backends::ActiveRecord::Table::Translation
  STATUS_VALUES = { draft: 0, in_review: 1, published: 2 }.freeze

  enum :status, STATUS_VALUES

  # Mobility adds `belongs_to :translated_model` pointing to Article.
  # Alias for backward compatibility with code that expects `.article`.
  # We define this as a method body (not alias_method) because
  # translated_model is added later by Mobility's setup block.
  def article
    translated_model
  end

  validates :locale, presence: true
  validates :locale, uniqueness: { scope: :article_id }
  validates :slug, uniqueness: { scope: :locale }, allow_nil: true
  validates :excerpt, length: { maximum: 500 }, allow_nil: true
  validates :cover_image_caption, length: { maximum: Article::COVER_IMAGE_CAPTION_MAX_LENGTH }, allow_nil: true

  def is_public?
    published? && published_at.present? && published_at <= Time.current
  end
end
