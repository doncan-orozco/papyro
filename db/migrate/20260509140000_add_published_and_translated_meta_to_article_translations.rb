# frozen_string_literal: true

class AddPublishedAndTranslatedMetaToArticleTranslations < ActiveRecord::Migration[8.1]
  def up
    add_column :article_translations, :excerpt, :text
    add_column :article_translations, :cover_image_caption, :string
    add_column :article_translations, :published, :boolean
    change_column_default :article_translations, :published, false
  end

  def down
    remove_column :article_translations, :excerpt
    remove_column :article_translations, :cover_image_caption
    remove_column :article_translations, :published
  end
end
