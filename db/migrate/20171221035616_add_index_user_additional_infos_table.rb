class AddIndexUserAdditionalInfosTable < ActiveRecord::Migration[5.1]
  def change
    add_index :user_additional_infos, [:user_id, :key], unique: true
  end
end
