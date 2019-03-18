class AddDescriptionInUsersTable < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :description, :text, null: true, default: ''
  end
end
