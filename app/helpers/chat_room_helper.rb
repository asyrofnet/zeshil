require 'kaminari'

module ChatRoomHelper

  PREFIX_KEY = "chat_room_user_"
  TTL = 3.hour.to_i

  # =begin
  # This is for loading user chat room, so if there are complex query
  # can be edited in single place without make controller dirty
  #
  # @params object user
  # @params array chat_room_sdk_info
  # @params int page_number
  # @params int per_page page number
  #
  # @return array
  # =end
  def self.load_for(current_user, chat_room_sdk_info = [], page = 1, per_page)
    chat_rooms = []

    is_redis_cache_active = ENV['REDIS_CACHE'] == "true" || ENV['REDIS_CACHE'] == true
    # is_redis_cache_active = true # for testing enable this
    if is_redis_cache_active
      chat_rooms = ChatRoomHelper.get_chat_room_cache_for_user(current_user)
    else
      chat_rooms =  ChatRoomHelper.get_chat_room_for_user(current_user)
    end

    chat_rooms =  ChatRoomHelper.merge_chat_room_sdk_info(chat_rooms, chat_room_sdk_info)

    # pagination using kaminari, because all data sorted by sdk info, so it can't be
    # cached to redis using pagination
    chat_count = chat_rooms.count
    chat_rooms = Kaminari.paginate_array(chat_rooms).page(page).per(per_page)
    return chat_count, chat_rooms
  end

  # =begin
  # @static @function get_chat_room_for_user
  # @description Get chat room (conversation) list for a user.
  #
  # @params current_user - A user to load
  #
  # @returns Array of hash of conversation
  # =end
  def self.get_chat_room_for_user(current_user)
    chat_rooms = current_user.chat_rooms.includes([
      :user => [],
      :chat_users => [],
      :users => [:roles, :application],
      :target => [:roles, :application]
    ])

    chat_rooms = chat_rooms.as_json({:me => current_user})

    chat_rooms = chat_rooms.sort { |a1, a2| a2["last_message_timestamps"] <=> a1["last_message_timestamps"] }

    # for mapping is favorite status
    favored_status = current_user.contacts.pluck(:contact_id, :is_favored)

    chat_rooms.map do |chat_room|
      chat_room['users'].map do |user|
        # if user id included in contact id list, then return true, otherwise return false
        is_contact = favored_status.flatten.include?(user['id'])
        user.merge!('is_contact' => is_contact)

        is_favored = (favored_status.to_h[ user["id"] ] == nil) ? false : favored_status.to_h[ user["id"] ]
        user.merge!('is_favored' => is_favored)

        # add is is_group_admin payload in user
        is_group_admin = ChatUser.where(chat_room_id: chat_room["id"], user_id: user["id"]).pluck(:is_group_admin).first
        user.merge!('is_group_admin' => is_group_admin)
      end

      # for mapping is_pin_chat
      pin_chat_room = current_user.pin_chat_rooms.find_by(chat_room_id: chat_room['id'])
      is_pin_chat = !pin_chat_room.nil?
      chat_room.merge!('is_pin_chat' => is_pin_chat)

      # for mapping pin_chat_room_id
      if !pin_chat_room.nil?
        chat_room.merge!('pin_chat_room_id' => pin_chat_room.id)
      else
        chat_room.merge!('pin_chat_room_id' => nil)
      end

      # show user_id that assigned as group_admin
      if chat_room['is_group_chat'] == true && chat_room['is_official_chat'] == false
        group_admin_ids = ChatUser.where(chat_room_id: chat_room['id']).where(is_group_admin: true).pluck(:user_id)
        group_admins = User.where("id IN (?)", group_admin_ids).pluck(:id)

        chat_room.merge!('group_admins' => group_admins)
      else
        chat_room.merge!('group_admins' => nil)
      end

      # for mapping is_mute_chat
      mute_chat_room = current_user.mute_chat_rooms.find_by(chat_room_id: chat_room['id'])
      is_mute_chat = !mute_chat_room.nil?
      chat_room.merge!('is_mute_chat' => is_mute_chat)
    end

    # don't show chat room where it is single chat and user is just one user
    chat_rooms = chat_rooms.select { |h| (h['users'].count > 1 && h['is_group_chat'] == false) || h['is_group_chat'] == true }
    return chat_rooms
  end

  # =begin
  # @static @function get_chat_rooms
  # @description Get chat room (conversation) list for a user.
  #
  # @params current_user - A user to load
  #
  # @returns Array of hash of conversation
  # =end
  def self.get_user_of_chat_rooms(chat_rooms)

    chat_rooms = chat_rooms.as_json

    chat_rooms = chat_rooms.sort { |a1, a2| a2["last_message_timestamps"] <=> a1["last_message_timestamps"] }

    chat_rooms.map do |chat_room|
      chat_room['users'].map do |user|
        # add is is_group_admin payload in user
        is_group_admin = ChatUser.where(chat_room_id: chat_room["id"], user_id: user["id"]).pluck(:is_group_admin).first
        user.merge!('is_group_admin' => is_group_admin)
      end

      # show user_id that assigned as group_admin
      if chat_room['is_group_chat'] == true && chat_room['is_official_chat'] == false
        group_admin_ids = ChatUser.where(chat_room_id: chat_room['id']).where(is_group_admin: true).pluck(:user_id)
        group_admins = User.where("id IN (?)", group_admin_ids).pluck(:id)

        chat_room.merge!('group_admins' => group_admins)
      else
        chat_room.merge!('group_admins' => nil)
      end
    end

    # don't show chat room where it is single chat and user is just one user
    chat_rooms = chat_rooms.select { |h| (h['users'].count > 1 && h['is_group_chat'] == false) || h['is_group_chat'] == true }
    return chat_rooms
  end

  # =begin
  # @static @function merge_chat_room_sdk_info
  # @description Will merge a chat list using info from SDK
  #
  # @params chat_room_hash - Chat room hash
  # @params chat_room_sdk_info - SDK info
  #
  # @returns Array of hash of conversation
  # =end
  def self.merge_chat_room_sdk_info(chat_room_hash, chat_room_sdk_info = [])
    chat_room_hash.map do | chat_room |
      qiscus_room_id = chat_room['qiscus_room_id'].to_i
      if chat_room_sdk_info[qiscus_room_id] != nil
        room_info = chat_room_sdk_info[qiscus_room_id]

        last_comment_message = room_info["last_comment_message"]

        # Handle if the last_comment_message is a reply comment
        split_last_comment_message = last_comment_message.split("` \n")
        if split_last_comment_message.size == 2
          last_comment_message = split_last_comment_message[1]
        end

        # Handle if the last_comment_message is file attachment
				if last_comment_message.start_with?"[file]" and last_comment_message.end_with?"[/file]"
          last_comment_message = "File attached."
        end

        chat_room["chat_name_sdk"] = room_info["room_name"]
        chat_room["unread_count"] = room_info["unread_count"]
        chat_room["last_message"] = last_comment_message

        if room_info["last_comment_timestamp"].include?("0001-01-01T00:00:00Z")
          timestamp = Time.parse(chat_room["created_at"].to_s)
          chat_room["last_message_timestamps"] = timestamp.strftime("%Y-%m-%dT%TZ")
        else
          chat_room["last_message_timestamps"] = room_info["last_comment_timestamp"]
        end

        chat_room["group_avatar_url_sdk"] = room_info["room_avatar_url"]

        chat_room["last_message_timestamps_int"] = Time.parse(chat_room["last_message_timestamps"]).to_i

        # use chat_avatar_url from sdk when chat_room_sdk_info assigned
        # only use avatar from SDK if it's a group chat (because latest group avatar is only in SDK [client only update group avatar in SDK])
        # if chat_room["is_group_chat"]
        #   chat_room["chat_avatar_url"] = room_info["room_avatar_url"]
        # end

      else
        # default value
        chat_room["chat_name_sdk"] = ""
        chat_room["unread_count"] = 0
        chat_room["last_message"] = ""
        chat_room["last_message_timestamps"] = "1960-01-01T01:01:01Z"
        chat_room["group_avatar_url_sdk"] = ""
        chat_room["last_message_timestamps_int"] = Time.parse(chat_room["last_message_timestamps"]).to_i

        # only use avatar from SDK if it's a group chat (because latest group avatar is only in SDK [client only update group avatar in SDK])
        if chat_room["is_group_chat"]
          chat_room["chat_avatar_url"] = ""
        end
      end
    end

    chat_room_hash = chat_room_hash.sort { |a1, a2| a2["last_message_timestamps"] <=> a1["last_message_timestamps"] }

    # is_pin_chat = true, is always in the top position.
    chat_room_hash = chat_room_hash.sort do |a1, a2|
      if a1["is_pin_chat"] == a2["is_pin_chat"]
        0
        # The order based on pin_chat_room_id in descending order. For example i have pin chat room with id 19, 30, 40. So the order is 40, 30, 19
        if a1["pin_chat_room_id"] == a2["pin_chat_room_id"]
          0
        elsif a1["pin_chat_room_id"] > a2["pin_chat_room_id"]
          -1
        elsif a1["pin_chat_room_id"] < a2["pin_chat_room_id"]
          1
        end
      elsif a1["is_pin_chat"] == true
        -1
      elsif a1["is_pin_chat"] == false
        1
      end
    end

    return chat_room_hash
  end

  # =begin
  # @static @function get_chat_room_cache_for_user
  # @description Get or set chat room for a user from redis
  #
  # @params current_user - A user to load
  #
  # @returns Array of hash of conversation
  # =end
  def self.get_chat_room_cache_for_user(current_user)
    keys = "#{PREFIX_KEY}#{current_user.id}"
    chat_rooms = $redis.get(keys)

    # cache is not exist
    if chat_rooms.nil?
      chat_rooms =  ChatRoomHelper.get_chat_room_for_user(current_user)

      # set to redis and expire every 3 hours
      $redis.set(keys, chat_rooms.to_json)
      $redis.expire(keys, TTL)

      return chat_rooms
    else
      chat_rooms = JSON.parse(chat_rooms)
      return chat_rooms
    end
  end

  # =begin
  # @static @function reset_chat_room_cache_for_users
  # @description Delete a redis cache if in that chat room contains this user
  # and set a new one record to redis.
  #
  # @params current_user - A user to look
  #
  # @returns void
  # =end
  def self.reset_chat_room_cache_for_users(user_ids)
    user_ids = user_ids.uniq

    keys = []
    user_ids.each do |uid|
      k = "#{PREFIX_KEY}#{uid}"
      keys.push(k)
    end

    # Redis SET, GET and DEL is atomic.
    if !keys.empty?
      $redis.del(keys)
    end

    # Now try to insert a new one cache for each user id
    # Since this is should be a long process (must get chat room for each user)
    # it must work in background to prevent user delays
    # ResetChatRoomCacheJob.perform_later(user_ids)

  end

end
