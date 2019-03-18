class AddUniqueIndexBetweenQiscusRoomIdAndApplicationIdInChatRoomsTable < ActiveRecord::Migration[5.0]
  def change
    add_index :chat_rooms, [:qiscus_room_id, :application_id], unique: true
  end
end
