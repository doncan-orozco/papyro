class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :articles, dependent: :destroy

  # SQLite doesn't support case-insensitive UNIQUE indexes
  # So we normalize email before validation to ensure uniqueness
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  generates_token_for :password_reset, expires_in: 24.hours do
    password_salt&.last(10)
  end

  # For MVP: all users are admins
  # Later: add role enum or admin boolean column
  def admin?
    true
  end
end
