class Article < ApplicationRecord
  # Per VERIFICATION_CHECKLIST.md §2.3: Associations only
  belongs_to :user
  has_rich_text :content  # ActionText - creates action_text_rich_texts table
  has_one_attached :cover_image  # Active Storage - for future use

  # Rails 8 normalizations (data cleanup before save)
  normalizes :title, with: ->(value) { value.strip }
  normalizes :slug, with: ->(value) { value.strip.downcase }

  # Enum for status - generates methods: draft?, published?, archived?
  enum :status, { draft: 0, published: 1, archived: 2 }, prefix: true

  # NO business validations here (use Contracts in Issue doncan-orozco/papyro#2)
  # Optional: Safety-net validations (paranoid mode, apply in all environments)
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  # Instance methods
  def published?
    status_published? && published_at.present?
  end

  def to_param
    slug  # Use slug in URLs instead of ID
  end
end
