class AddIsPublicChatInChatRoomsTable < ActiveRecord::Migration[5.1]
  def change
    add_column :chat_rooms, :is_public_chat, :boolean, null: false, default: false
  end
end
