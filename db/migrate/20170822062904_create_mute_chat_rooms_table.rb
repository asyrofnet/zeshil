class CreateMuteChatRoomsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :mute_chat_rooms do |t|
      t.integer :chat_room_id
      t.integer :user_id
      t.timestamps
    end

    add_index :mute_chat_rooms, [:chat_room_id, :user_id], unique: true
    
    add_foreign_key :mute_chat_rooms, :chat_rooms, column: :chat_room_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :mute_chat_rooms, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
