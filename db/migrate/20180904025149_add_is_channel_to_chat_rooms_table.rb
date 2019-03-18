class AddIsChannelToChatRoomsTable < ActiveRecord::Migration[5.1]
  def change
    add_column :chat_rooms, :is_channel, :boolean, default: false
  end
end
