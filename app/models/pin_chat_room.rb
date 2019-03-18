class PinChatRoom < ActiveRecord::Base
  validates :chat_room_id, presence: true
  validates :user_id, presence: true

  belongs_to :chat_room
  belongs_to :user

  default_scope { joins(:user)}

  # Update redis cache after create, update and delete
  # after save hooks will called both when Creating or Updating an Object
  after_save :update_redis_cache
  after_destroy :update_redis_cache

  # Delete and update redis cache for conversation list to make all data sync after update
  def update_redis_cache
    user_ids = [user_id]
    ChatRoomHelper.reset_chat_room_cache_for_users(user_ids)
  end

end