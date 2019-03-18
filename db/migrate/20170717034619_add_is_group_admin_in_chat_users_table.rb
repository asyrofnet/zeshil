class AddIsGroupAdminInChatUsersTable < ActiveRecord::Migration[5.1]
  def change
    add_column :chat_users, :is_group_admin, :boolean, null: false, default: false
  end
end
