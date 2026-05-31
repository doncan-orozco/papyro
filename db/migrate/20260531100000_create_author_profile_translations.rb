class CreateAuthorProfileTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :author_profile_translations do |t|
      t.references :author_profile, null: false, foreign_key: true, index: false
      t.string :locale, null: false
      t.text :bio

      t.timestamps
    end

    add_index :author_profile_translations, [ :author_profile_id, :locale ],
      unique: true,
      name: "index_author_profile_translations_on_profile_and_locale"
  end
end
