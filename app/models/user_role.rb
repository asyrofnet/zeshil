class UserRole < ActiveRecord::Base
  belongs_to :user
  belongs_to :role

  # Hooks
  # Update redis cache after create, update and delete
  # after save hooks will called both when Creating or Updating an Object
  # This should update cache after user removed or added to a chat room
  after_save :update_redis_cache
  after_destroy :update_redis_cache

  # Delete and update redis cache for conversation list to make all data sync after update
  def update_redis_cache
    chat_room_ids = ChatUser.where(user_id: user_id).pluck(:chat_room_id)
    user_ids = ChatUser.where("chat_users.chat_room_id IN (?)", chat_room_ids).pluck(:user_id)
    user_ids = user_ids.uniq

    ChatRoomHelper.reset_chat_room_cache_for_users(user_ids)
  end
end