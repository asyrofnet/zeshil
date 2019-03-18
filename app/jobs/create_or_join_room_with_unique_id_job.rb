class CreateOrJoinRoomWithUniqueIdJob < ActiveJob::Base
  queue_as :default

  def perform(application_id, user_ids, chat_name, group_avatar_url, unique_id)
    application = Application.find(application_id)

    users = User.where("id IN (?)", user_ids.to_a)
    users = users.sort_by { |u| user_ids.index(u.id) } # sort by index of user_ids

    qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
    new_chat_users = Array.new

    users.each do |user|
      # by default is_group_admin = false
      is_group_admin = false

      # Backend need to create chat room with unique id in SDK
      room = qiscus_sdk.get_or_create_room_with_unique_id(user.qiscus_token, unique_id, chat_name, group_avatar_url)

      qiscus_room_id = room.id

      chat_room = ChatRoom.find_by(qiscus_room_id: qiscus_room_id, application_id: application.id)

      if chat_room.nil?
        chat_room = ChatRoom.new(
          group_chat_name: chat_name,
          qiscus_room_name: chat_name,
          qiscus_room_id: qiscus_room_id,
          is_group_chat: true,
          user_id: user.id,
          target_user_id: user.id,
          application_id: user.application.id,
          group_avatar_url: group_avatar_url,
          is_official_chat: false,
          is_public_chat: true
        )

        chat_room.save!

        # make first user as group admin
        is_group_admin = true
      end

      # Add group participants
      chat_user = ChatUser.find_by(chat_room_id: chat_room.id, user_id: user.id)
      if chat_user.nil?
        new_chat_users.push({:user_id => user.id, :chat_room_id => chat_room.id, :is_group_admin => is_group_admin})
      end
    end

    ChatUser.create(new_chat_users)
  end
end