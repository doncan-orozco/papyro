# frozen_string_literal: true

class RemoveLegacyPublicationColumnsFromArticleTranslations < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :article_translations, :published, :boolean if column_exists?(:article_translations, :published)
      remove_column :article_translations, :is_approved, :boolean if column_exists?(:article_translations, :is_approved)
    end
  end
end
