# frozen_string_literal: true

class AddFieldsToAuthorProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :author_profiles, :username, :string
    add_index :author_profiles, :username, unique: true
    add_column :author_profiles, :website_url, :string
    add_column :author_profiles, :x_handle, :string
    add_column :author_profiles, :linkedin_handle, :string
    add_column :author_profiles, :location, :string
    add_column :author_profiles, :pinned_article_id, :integer
    add_foreign_key :author_profiles, :articles, column: :pinned_article_id, validate: false
  end
end
