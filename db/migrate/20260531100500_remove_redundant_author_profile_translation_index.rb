class RemoveRedundantAuthorProfileTranslationIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :author_profile_translations,
      name: "index_author_profile_translations_on_author_profile_id",
      if_exists: true
  end
end
