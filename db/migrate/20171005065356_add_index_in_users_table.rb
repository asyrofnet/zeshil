class AddIndexInUsersTable < ActiveRecord::Migration[5.1]
  def change
    add_index :users, :secondary_phone_number, unique: false
  end
end
