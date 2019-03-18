class ChangeIsPublicColumnToNotNull < ActiveRecord::Migration[5.0]
  def change
    change_column :users, :is_public, :boolean, :null => false, default: false
  end
end
