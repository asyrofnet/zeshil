class ChangeOndeleteCascadeInChatRoomsTable < ActiveRecord::Migration[5.1]
  def change
    remove_foreign_key :chat_rooms, :column => :user_id
    add_foreign_key :chat_rooms, :users, column: :user_id, primary_key: :id, on_delete: :nullify, on_update: :cascade
  end
end
