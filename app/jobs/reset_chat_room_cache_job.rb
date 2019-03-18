class ResetChatRoomCacheJob < ActiveJob::Base
  queue_as :default

  PREFIX_KEY = "chat_room_user_"
  TTL = 3.hour.to_i

  # 
  def perform(user_ids)
    users = User.where("id IN (?)", user_ids)
    users.each do |user|
      chat_rooms =  ChatRoomHelper.get_chat_room_for_user(user)

      k = "#{PREFIX_KEY}#{user.id}"
      # set to redis and expire every 3 hours
      $redis.set(k, chat_rooms.to_json)
      $redis.expire(k, TTL)
    end
  end

end