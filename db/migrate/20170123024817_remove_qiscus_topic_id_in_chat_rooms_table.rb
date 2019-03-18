class RemoveQiscusTopicIdInChatRoomsTable < ActiveRecord::Migration[5.0]
  def change
    remove_index :chat_rooms, name: 'index_chat_rooms_on_room_id_and_topic_id_and_is_group'
    remove_column :chat_rooms, :qiscus_topic_id
  end
end
