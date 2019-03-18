class CreateChatRoomsTable < ActiveRecord::Migration[5.0]
  def change
    create_table :chat_rooms do |t|
      t.string :qiscus_room_name, null: false
      t.string :qiscus_room_id, null: false
      t.string :qiscus_topic_id, null: false
      t.boolean :is_group_chat, default: false
      t.integer :user_id, null: false # user who made this conversation
      t.timestamps
    end

    add_foreign_key :chat_rooms, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
