class ChatUser < ActiveRecord::Base
  validates :user_id, presence: true
  validates :chat_room_id, presence: true

  # Relation info
  belongs_to :user
  belongs_to :chat_room

  default_scope { joins(:user)}

  # Hooks
  # Update redis cache after create, update and delete
  # after save hooks will called both when Creating or Updating an Object
  # This should update cache after user removed or added to a chat room
  after_save :update_redis_cache
  after_destroy :update_redis_cache
  after_destroy :delete_customized_chat_rooms

  # Delete and update redis cache for conversation list to make all data sync after update
  def update_redis_cache
    user_ids = ChatUser.where(chat_room_id: chat_room_id).pluck(:user_id)
    # Add user_id to handle removed user_id in delete participants and leave group 
    user_ids = user_ids << user_id 

    ChatRoomHelper.reset_chat_room_cache_for_users(user_ids)
  end

  # For initialization, assign all group participants as group admin
  def self.assign_all_group_participants_as_group_admin
    # get all group chat room
    chat_room_ids = ChatRoom.where(is_group_chat: TRUE).where(is_official_chat: FALSE).pluck(:id)
    chat_users = ChatUser.where("chat_users.chat_room_id IN (?)", chat_room_ids)
    chat_users.each do | c | 
      c.update_attribute(:is_group_admin, TRUE)
    end
  end

  def delete_customized_chat_rooms
    pin_chat = PinChatRoom.find_by(user_id: user_id, chat_room_id: chat_room_id)
    if !pin_chat.nil?
      pin_chat.destroy
    end

    mute_chat = MuteChatRoom.find_by(user_id: user_id, chat_room_id: chat_room_id)
    if !mute_chat.nil?
      mute_chat.destroy
    end
  end
end