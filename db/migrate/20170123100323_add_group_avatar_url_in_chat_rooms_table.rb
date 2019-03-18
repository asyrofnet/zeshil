class AddGroupAvatarUrlInChatRoomsTable < ActiveRecord::Migration[5.0]
  def change
    add_column :chat_rooms, :group_avatar, :string, null: true, default: ""
  end
end
