# frozen_string_literal: true

# Pre-defined translation class for AuthorProfile.
# Mobility's translates :bio, backend: :table normally creates this class
# dynamically, but by pre-defining it we can add our custom validations.
# Mobility's const_defined? check will find this class and use it
# instead of creating a new anonymous one.
class AuthorProfile::Translation < Mobility::Backends::ActiveRecord::Table::Translation
  # Mobility adds `belongs_to :translated_model` pointing to AuthorProfile.
  # Provide #author_profile for backward compatibility with code that expects it.
  def author_profile
    translated_model
  end

  validates :locale, presence: true
  validates :locale, uniqueness: { scope: :author_profile_id }
end
