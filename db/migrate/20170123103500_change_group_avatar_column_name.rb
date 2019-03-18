class ChangeGroupAvatarColumnName < ActiveRecord::Migration[5.0]
  def change
    rename_column :chat_rooms, :group_avatar, :group_avatar_url
  end
end
