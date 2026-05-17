class RemoveRedundantArticleTranslationsArticleIdIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :article_translations, name: "index_article_translations_on_article_id", if_exists: true
  end
end
