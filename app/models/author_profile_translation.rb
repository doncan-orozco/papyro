class AuthorProfileTranslation < ApplicationRecord
  belongs_to :author_profile, inverse_of: :author_profile_translations

  validates :locale, presence: true
  validates :locale, uniqueness: { scope: :author_profile_id }
end
