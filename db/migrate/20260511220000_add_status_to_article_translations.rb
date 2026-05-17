class AddStatusToArticleTranslations < ActiveRecord::Migration[8.1]
  def change
    add_column :article_translations, :status, :integer
    add_index :article_translations, :status
  end
end
