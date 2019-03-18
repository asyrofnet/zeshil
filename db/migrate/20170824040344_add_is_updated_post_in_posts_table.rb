class AddIsUpdatedPostInPostsTable < ActiveRecord::Migration[5.1]
  def change
    add_column :posts, :is_updated_post, :boolean, null: false, default: false
  end
end
