class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  # Papyro associations
  has_many :articles, dependent: :destroy

  # Validations per VERIFICATION_CHECKLIST.md §2.3
  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Scopes
  scope :active, -> { where(suspended_at: nil) }

  # For MVP: all users are admins
  # Later: add role enum or admin boolean column
  def admin?
    true
  end
end
