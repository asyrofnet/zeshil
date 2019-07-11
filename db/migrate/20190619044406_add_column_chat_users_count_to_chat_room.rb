class AddColumnChatUsersCountToChatRoom < ActiveRecord::Migration[5.1]
  def change
    add_column :chat_rooms, :chat_users_count, :integer, :default => 0
  end
end
