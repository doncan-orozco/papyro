class AuthorProfile < ApplicationRecord
  extend Mobility
  extend FriendlyId

  translates :bio, backend: :table

  accepts_nested_attributes_for :translations, allow_destroy: true

  friendly_id :username, use: %i[slugged history finders], slug_column: :username

  belongs_to :user, inverse_of: :profile
  belongs_to :pinned_article, class_name: "Article", optional: true
  has_one_attached :portrait

  before_validation :prepare_and_free_username, prepend: true, if: :will_save_change_to_username?

  validates :display_name, presence: true, length: { maximum: 100 }
  validates :user_id, uniqueness: true
  validates :pinned_article_id, uniqueness: true, allow_nil: true
  validates :username,
    presence: true,
    length: { in: 3..30 },
    format: { with: /\A[a-z0-9_]+\z/, message: :invalid_username },
    uniqueness: { case_sensitive: false }

  def should_generate_new_friendly_id?
    will_save_change_to_username?
  end

  private

  def prepare_and_free_username
    return if username.blank?

    self.username = username.downcase.strip

    # Implements the GitHub approach:
    # if the incoming username only exists as historical slug, free it so a new profile can claim it.
    FriendlyId::Slug.where(slug: username, sluggable_type: self.class.name).find_each do |slug|
      owner = self.class.find_by(id: slug.sluggable_id)
      slug.destroy if owner && owner.username != username
    end
  end
end
