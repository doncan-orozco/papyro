# frozen_string_literal: true

class FixAuthorProfileDatabaseConsistency < ActiveRecord::Migration[8.1]
  def up
    remove_index :author_profiles, name: "index_author_profiles_on_username"
    change_column_null :author_profiles, :username, false
    add_index :author_profiles, "lower(username)", unique: true, name: "index_author_profiles_on_lower_username"
  end

  def down
    remove_index :author_profiles, name: "index_author_profiles_on_lower_username"
    change_column_null :author_profiles, :username, true
    add_index :author_profiles, :username, unique: true
  end
end
