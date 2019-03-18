class AddIsAutoFriendToApplicationsTable < ActiveRecord::Migration[5.1]
  def change
    add_column :applications, :is_auto_friend, :boolean, default: true
  end
end
