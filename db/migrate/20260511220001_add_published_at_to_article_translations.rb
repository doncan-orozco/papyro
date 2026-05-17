class AddPublishedAtToArticleTranslations < ActiveRecord::Migration[8.1]
  def change
    add_column :article_translations, :published_at, :datetime
    add_index :article_translations, :published_at
  end
end
