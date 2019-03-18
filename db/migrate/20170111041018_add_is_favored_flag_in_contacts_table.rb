class AddIsFavoredFlagInContactsTable < ActiveRecord::Migration[5.0]
  def change
    add_column :contacts, :is_favored, :boolean, null: false, default: false
  end
end
