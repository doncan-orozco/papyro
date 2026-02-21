class CreateActionTextMarkdowns < ActiveRecord::Migration[8.1]
  def change
    create_table :action_text_markdowns do |t|
      t.string :record_type, null: false
      t.bigint :record_id, null: false
      t.string :name, null: false
      t.text :content, default: "", null: false
      t.timestamps

      t.index [ :record_type, :record_id ], name: "index_action_text_markdowns_on_record"
    end

    # Add slug column to active_storage_attachments for friendly URLs
    add_column :active_storage_attachments, :slug, :string
    add_index :active_storage_attachments, :slug, unique: true
  end
end
