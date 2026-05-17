# frozen_string_literal: true

class RemoveLegacyStatusFromArticles < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_check_constraint :articles, name: "valid_status", if_exists: true
      remove_index :articles, :status, if_exists: true
      remove_index :articles, name: "index_articles_on_user_id_and_status", if_exists: true
      remove_column :articles, :status, :integer if column_exists?(:articles, :status)
    end

    add_index :articles, :user_id, if_not_exists: true
  end
end
