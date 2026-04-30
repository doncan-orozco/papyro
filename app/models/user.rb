class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :articles, dependent: :destroy
  has_one :profile, class_name: "AuthorProfile", dependent: :destroy, inverse_of: :user, autosave: true
  delegate :display_name, to: :profile, prefix: :author

  enum :role, { member: 0, admin: 1 }

  # SQLite doesn't support case-insensitive UNIQUE indexes
  # So we normalize email before validation to ensure uniqueness
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Safety-net validations (paranoid mode, apply in all environments)
  validates :email_address, presence: true, uniqueness: true
  validates :password_digest, presence: true

  generates_token_for :password_reset, expires_in: 24.hours do
    password_salt&.last(10)
  end
end
