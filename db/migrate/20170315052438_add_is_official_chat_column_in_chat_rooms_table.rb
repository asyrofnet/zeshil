class AddIsOfficialChatColumnInChatRoomsTable < ActiveRecord::Migration[5.0]
  def change
    add_column :chat_rooms, :is_official_chat, :boolean, null: false, default: false
  end
end
