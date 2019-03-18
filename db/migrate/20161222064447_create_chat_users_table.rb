class CreateChatUsersTable < ActiveRecord::Migration[5.0]
  def change
    # one chat to many user (interlocutors)
    create_table :chat_users do |t|
      t.integer :user_id
      t.integer :chat_room_id
      t.timestamps
    end

    add_foreign_key :chat_users, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :chat_users, :chat_rooms, column: :chat_room_id, primary_key: :id, on_delete: :cascade, on_update: :cascade

    add_index :chat_users, [:user_id, :chat_room_id], unique: true
  end
end
