class AddUniqueIndexToChatRoomsTable < ActiveRecord::Migration[5.0]
  def change
    # pair of room id and topic id must be unique to avoid duplicate chat with same id
    add_index :chat_rooms, [:qiscus_room_id, :qiscus_topic_id], unique: true
  end
end
