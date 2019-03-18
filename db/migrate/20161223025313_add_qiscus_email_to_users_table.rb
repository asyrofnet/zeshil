class AddQiscusEmailToUsersTable < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :qiscus_email, :string, null: false, default: "", :unique => true
  end
end
