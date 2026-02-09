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

  # Scopes for common queries
  scope :published, -> { status_published.where.not(published_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_slug, ->(slug) { find_by!(slug: slug) }

  # NO business validations here (use Contracts in Issue doncan-orozco/papyro#2)
  # Optional: Safety-net validations for production only
  validates :title, presence: true, if: -> { Rails.env.production? }
  validates :slug, presence: true, uniqueness: true, if: -> { Rails.env.production? }

  # Instance methods
  def published?
    status_published? && published_at.present?
  end

  def to_param
    slug  # Use slug in URLs instead of ID
  end
end
