class Api::V1::Chat::Conversations::GroupChatController < ProtectedController
  before_action :authorize_user

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/chat/conversations/group_chat Get Group Chat Info By Qiscus Room Id
  # @apiName GroupChatInfo
  # @apiGroup Chat
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} qiscus_room_id Qiscus room id
  # =end
  def index
    begin
      chat_room = ChatRoom.includes({
            users: [:roles, :application],
            user: [:roles, :application],
          }).find_by(qiscus_room_id: params[:qiscus_room_id], application_id: @current_user.application.id)
      if chat_room.nil?
        raise InputError.new("Chat room with qiscus room id #{params[:qiscus_room_id]} is not found.")
      end

      bot_id = User.find_bot_id
      user_ids = chat_room.users.pluck(:id)
      user_bot = User.find_user_bot(user_ids, bot_id)

      if chat_room.is_public_chat || chat_room.is_channel ||  user_ids.to_a.include?(@current_user.id)

        qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
        sdk_info, chat_room_sdk_info = qiscus_sdk.get_rooms_info(@current_user.qiscus_email, [chat_room.qiscus_room_id])

        if sdk_info != 200
          raise InputError.new(chat_room_sdk_info['error']['detailed_messages'].to_a.join(", ").capitalize)
        end

        chat_room = chat_room.as_json({:me => @current_user, :chat_room_sdk_info => chat_room_sdk_info})

        # get user current contact
        # for mapping is favorite status
        favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)

        chat_room['users'].map do |user|
          # if user id included in contact id list, then return true, otherwise return false
          is_contact = favored_status.flatten.include?(user['id'])
          user.merge!('is_contact' => is_contact)

          is_favored = (favored_status.to_h[ user["id"] ] == nil) ? false : favored_status.to_h[ user["id"] ]
          user.merge!('is_favored' => is_favored)

          is_bot = user_bot - [user['id']] != user_bot
          user.merge!('is_bot' => is_bot)
        end

        # for mapping is_pin_chat
        pin_chat_room = @current_user.pin_chat_rooms.find_by(chat_room_id: chat_room['id'])
        is_pin_chat = !pin_chat_room.nil?
        chat_room.merge!('is_pin_chat' => is_pin_chat)

        # for mapping pin_chat_room_id
        if !pin_chat_room.nil?
          chat_room.merge!('pin_chat_room_id' => pin_chat_room.id)
        else
          chat_room.merge!('pin_chat_room_id' => nil)
        end

        # show user_id that assigned as group_admin
        if chat_room['is_group_chat'] == TRUE && chat_room['is_official_chat'] == FALSE
          group_admin_ids = ChatUser.where(chat_room_id: chat_room['id']).where(is_group_admin: TRUE).pluck(:user_id)
          group_admins = User.where("id IN (?)", group_admin_ids).pluck(:id)

          chat_room.merge!('group_admins' => group_admins)
        else
          chat_room.merge!('group_admins' => nil)
        end

        render json: {
          data: chat_room
        } and return

      else
        raise InputError.new("You are not member of this group.")
      end
    rescue => e
      render json: {
        error: {
          message: e.message,
          code: 105
        }
      }, status: 422
    end
  end

end