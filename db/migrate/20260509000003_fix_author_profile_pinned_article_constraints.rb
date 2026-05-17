# frozen_string_literal: true

class FixAuthorProfilePinnedArticleConstraints < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :author_profiles, column: :pinned_article_id
    add_foreign_key :author_profiles, :articles, column: :pinned_article_id, on_delete: :nullify, validate: false
    add_index :author_profiles, :pinned_article_id, unique: true
  end

  def down
    remove_index :author_profiles, :pinned_article_id
    remove_foreign_key :author_profiles, column: :pinned_article_id
    add_foreign_key :author_profiles, :articles, column: :pinned_article_id, validate: false
  end
end
