class CreateAuthorProfiles < ActiveRecord::Migration[8.1]
  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  class MigrationAuthorProfile < ApplicationRecord
    self.table_name = "author_profiles"
  end

  def up
    create_table :author_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :display_name, null: false
      t.text :bio

      t.timestamps
    end

    MigrationUser.find_each do |user|
      MigrationAuthorProfile.create!(
        user_id: user.id,
        display_name: inferred_display_name_for(user.email_address)
      )
    end
  end

  def down
    drop_table :author_profiles
  end

  private

  def inferred_display_name_for(email_address)
    email_address.to_s.split("@").first.to_s.tr("._-", " ").split.map(&:capitalize).join(" ")
  end
end
