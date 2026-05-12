class RemoveTranslatedColumnsFromArticles < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_index  :articles, :slug, if_exists: true
      remove_column :articles, :title, :string
      remove_column :articles, :slug, :string
      remove_column :articles, :excerpt, :text
      remove_column :articles, :cover_image_caption, :string
    end
  end
end
