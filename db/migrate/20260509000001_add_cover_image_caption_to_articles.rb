# frozen_string_literal: true

class AddCoverImageCaptionToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :cover_image_caption, :string
  end
end
