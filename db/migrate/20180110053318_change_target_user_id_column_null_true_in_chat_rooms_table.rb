class ChangeTargetUserIdColumnNullTrueInChatRoomsTable < ActiveRecord::Migration[5.1]
  def change
    change_column :chat_rooms, :target_user_id, :integer, null: true, default: 0
  end
end
