class AddApplicationIdInChatRoomsTable < ActiveRecord::Migration[5.0]
  def change
    add_column :chat_rooms, :application_id, :integer, null: true

    add_foreign_key :chat_rooms, :applications, column: :application_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
