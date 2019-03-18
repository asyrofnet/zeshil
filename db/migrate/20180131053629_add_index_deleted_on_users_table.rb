class AddIndexDeletedOnUsersTable < ActiveRecord::Migration[5.1]
  def change
    add_index :users, :deleted
  end
end
