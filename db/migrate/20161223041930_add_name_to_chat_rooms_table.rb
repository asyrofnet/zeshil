class AddNameToChatRoomsTable < ActiveRecord::Migration[5.0]
  def change
    add_column :chat_rooms, :group_chat_name, :string, null: false, default: "Chat Name"
  end
end
