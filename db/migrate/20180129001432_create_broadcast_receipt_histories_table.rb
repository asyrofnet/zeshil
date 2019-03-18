class CreateBroadcastReceiptHistoriesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :broadcast_receipt_histories do |t|
      t.integer :chat_room_id, null: false
      t.integer :user_id, null: false
      t.integer :broadcast_message_id, null: false
      t.timestamp :sent_at, null: true
      t.timestamp :delivered_at, null: true
      t.timestamp :read_at, null: true
      t.timestamps
    end

    add_foreign_key :broadcast_receipt_histories, :chat_rooms, column: :chat_room_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :broadcast_receipt_histories, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :broadcast_receipt_histories, :broadcast_messages, column: :broadcast_message_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
