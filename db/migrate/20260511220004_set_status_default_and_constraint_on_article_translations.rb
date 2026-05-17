class SetStatusDefaultAndConstraintOnArticleTranslations < ActiveRecord::Migration[8.1]
  def change
    change_column_default :article_translations, :status, from: nil, to: 0
    add_check_constraint :article_translations, "status IN (0, 1, 2)", name: "valid_translation_status"
  end
end
