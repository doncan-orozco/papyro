class AuthorProfile < ApplicationRecord
  belongs_to :user, inverse_of: :profile

  validates :display_name, presence: true, length: { maximum: 100 }
  validates :user_id, uniqueness: true
end
