class AddDeletedAndDeletedAtToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :deleted, :boolean, default: false
    add_column :users, :deleted_at, :datetime, null: true, default: nil
  end
end
