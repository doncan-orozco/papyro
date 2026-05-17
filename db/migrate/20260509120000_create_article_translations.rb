class CreateArticleTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :article_translations do |t|
      t.references :article, null: false, foreign_key: true
      t.string :locale, null: false
      t.string :title
      t.text :content
      t.string :slug
      t.boolean :is_original, default: false, null: false
      t.boolean :is_approved, default: false, null: false
      t.timestamps
    end
    add_index :article_translations, [ :article_id, :locale ], unique: true
  end
end
