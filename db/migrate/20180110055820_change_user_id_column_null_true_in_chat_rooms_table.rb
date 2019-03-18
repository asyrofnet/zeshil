class ChangeUserIdColumnNullTrueInChatRoomsTable < ActiveRecord::Migration[5.1]
  def change
    change_column :chat_rooms, :user_id, :integer, null: true
  end
end
