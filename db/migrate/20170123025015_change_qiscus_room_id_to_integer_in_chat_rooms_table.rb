class ChangeQiscusRoomIdToIntegerInChatRoomsTable < ActiveRecord::Migration[5.0]
  def change
    change_column :chat_rooms, :qiscus_room_id, 'integer USING CAST(qiscus_room_id AS integer)', null: false
  end
end
