class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :role, :integer
    change_column_default :users, :role, 0
    add_index :users, :role
  end

  def down
    remove_index :users, :role
    remove_column :users, :role
  end
end
