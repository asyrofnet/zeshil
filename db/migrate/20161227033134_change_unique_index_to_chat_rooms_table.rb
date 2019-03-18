class ChangeUniqueIndexToChatRoomsTable < ActiveRecord::Migration[5.0]
  def change
    
    # remove pair of index before creating new index of such column
    remove_index :chat_rooms, [:qiscus_room_id, :qiscus_topic_id]

    # pair of room id and topic id and group chat status must be unique to avoid duplicate chat with same id
    add_index :chat_rooms, [:qiscus_room_id, :qiscus_topic_id, :is_group_chat], unique: true, name: 'index_chat_rooms_on_room_id_and_topic_id_and_is_group'
  end
end
