class AuthorProfile < ApplicationRecord
  belongs_to :user, inverse_of: :profile
  belongs_to :pinned_article, class_name: "Article", optional: true

  before_validation :downcase_username

  validates :display_name, presence: true, length: { maximum: 100 }
  validates :user_id, uniqueness: true
  validates :pinned_article_id, uniqueness: true, allow_nil: true
  validates :username,
    presence: true,
    length: { in: 3..30 },
    format: { with: /\A[a-z0-9_]+\z/, message: :invalid_username },
    uniqueness: { case_sensitive: false }

  private

  def downcase_username
    self.username = username&.downcase&.strip
  end
end
