class RenamePinnedChatRoomsToPinChatRoomsTable < ActiveRecord::Migration[5.1]
  def change
  	rename_table :pinned_chat_rooms, :pin_chat_rooms
  end
end
