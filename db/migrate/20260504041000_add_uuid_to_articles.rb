# frozen_string_literal: true

require "securerandom"

class AddUuidToArticles < ActiveRecord::Migration[8.1]
  class MigrationArticle < ApplicationRecord
    self.table_name = "articles"
  end

  def up
    add_column :articles, :uuid, :string, limit: 36

    MigrationArticle.reset_column_information
    MigrationArticle.where(uuid: nil).find_each do |article|
      article.update_columns(uuid: SecureRandom.uuid)
    end

    add_index :articles, :uuid, unique: true
    change_column_null :articles, :uuid, false
  end

  def down
    remove_index :articles, :uuid
    remove_column :articles, :uuid
  end
end
