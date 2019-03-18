class AddTargetUserIdColumnInChatRoomsTable < ActiveRecord::Migration[5.0]
  def change
    # default = 0 to avoid error when migrate, since it must not null
    add_column :chat_rooms, :target_user_id, :integer, null: false, default: 0

    ChatRoom.unscoped.all.each do | chat_room |
      target_user = chat_room.users.where.not(id: chat_room.user_id)

      if !target_user.empty?
        official_participants = UserRole.where("user_roles.user_id IN (?)", target_user.pluck(:id))
        official_participants = official_participants.where(role_id: Role.official.id)
        official_participants = User.unscoped.where("id IN (?)", official_participants.pluck(:user_id))

        target_chat_user = target_user.first
        if !official_participants.empty?
          target_chat_user = official_participants.first
        end

        chat_room.update_attribute(:target_user_id, target_chat_user.id)
      else
        # in some case, somehow there is only one user in chat room (may be has been removed or when testing)
        # so, it must be handled when migrate
        chat_room.update_attribute(:target_user_id, chat_room.user_id)
      end

    end

    add_foreign_key :chat_rooms, :users, column: :target_user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
