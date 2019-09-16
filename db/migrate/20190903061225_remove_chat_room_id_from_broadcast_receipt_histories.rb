class RemoveChatRoomIdFromBroadcastReceiptHistories < ActiveRecord::Migration[5.1]
  def change
    remove_column :broadcast_receipt_histories, :chat_room_id
  end
end
