class AddUniqueSlugIndexToArticleTranslations < ActiveRecord::Migration[8.1]
  def change
    add_index :article_translations, [ :locale, :slug ], unique: true, name: "index_article_translations_on_locale_and_slug"
  end
end
