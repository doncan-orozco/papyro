class RemoveRedundantUserIdIndexFromArticles < ActiveRecord::Migration[8.1]
  def change
    # Remove redundant index - the composite index on [user_id, status] covers queries on user_id
    remove_index :articles, :user_id, if_exists: true
  end
end
