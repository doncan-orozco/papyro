class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  # Papyro associations
  has_many :articles, dependent: :destroy

  # Normalize email for consistency
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Password reset tokens (Rails 8+ generates_token_for)
  generates_token_for :password_reset, expires_in: 24.hours do
    password_salt&.last(10)
  end

  # Scopes
  scope :active, -> { where(suspended_at: nil) }

  # For MVP: all users are admins
  # Later: add role enum or admin boolean column
  def admin?
    true
  end

  # Password reset token methods for backward compatibility
  def password_reset_token
    generate_token_for(:password_reset)
  end

  def password_reset_token_expires_in
    24.hours
  end

  def self.find_by_password_reset_token!(token)
    find_by_token_for!(:password_reset, token)
  end
end
