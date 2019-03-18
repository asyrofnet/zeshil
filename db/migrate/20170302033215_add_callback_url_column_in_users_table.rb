class AddCallbackUrlColumnInUsersTable < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :callback_url, :string, null: true, default: ""
  end
end
