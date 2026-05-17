class UpdateArticleTranslationsStatusConstraint < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :article_translations, name: "valid_translation_status"
    add_check_constraint :article_translations, "status IN (0, 1, 2)", name: "valid_translation_status"
  end

  def down
    remove_check_constraint :article_translations, name: "valid_translation_status"
    # Optionally, add the previous constraint back here if needed
  end
end
