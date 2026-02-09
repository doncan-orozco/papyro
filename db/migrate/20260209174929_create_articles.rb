class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      # Required fields with NOT NULL constraints
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false, limit: 255
      t.string :slug, null: false, limit: 255
      t.integer :status, default: 0, null: false

      # Optional metadata
      t.datetime :published_at
      t.text :excerpt, limit: 500

      t.timestamps
    end

    # Database-level constraints
    add_index :articles, :slug, unique: true
    add_index :articles, :status
    add_index :articles, :published_at
    add_index :articles, [ :user_id, :status ]

    # Check constraint for status enum values
    add_check_constraint :articles, "status IN (0, 1, 2)", name: "valid_status"
  end
end
