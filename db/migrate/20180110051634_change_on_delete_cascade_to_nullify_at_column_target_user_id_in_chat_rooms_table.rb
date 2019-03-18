class ChangeOnDeleteCascadeToNullifyAtColumnTargetUserIdInChatRoomsTable < ActiveRecord::Migration[5.1]
  def change
    remove_foreign_key :chat_rooms, :column => :target_user_id
    add_foreign_key :chat_rooms, :users, column: :target_user_id, primary_key: :id, on_delete: :nullify, on_update: :cascade
  end
end
