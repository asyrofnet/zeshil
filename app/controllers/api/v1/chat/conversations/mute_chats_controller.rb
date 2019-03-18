class Api::V1::Chat::Conversations::MuteChatsController < ProtectedController
  before_action :authorize_user

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/chat/conversations/mute_chats Add Mute Chat Rooms
  # @apiDescription Add Mute Chat Rooms
  #
  # @apiName AddMuteChatRooms
  # @apiGroup Mute Chat Rooms
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Array} qiscus_room_id[] Array of qiscus_room_id, e.g: `qiscus_room_id[]=1&qiscus_room_id[]=2`
  # =end
  def create
    begin
      qiscus_room_id = params[:qiscus_room_id]

      if !qiscus_room_id.is_a?(Array)
        raise Exception.new("Qiscus room id must be an array of qiscus room id.")
      end

      qiscus_room_ids = qiscus_room_id.to_a

      # anticipate empty index of qiscus room id
      qiscus_room_ids.each do |id|
        if id.nil? || id == ""
          raise Exception.new("Qiscus room id must be present.")
        end
      end

      # get current mute chat rooms
      current_mute_chat_rooms = MuteChatRoom.where(user_id: @current_user.id).order(created_at: :desc)

      chat_rooms = nil
      ActiveRecord::Base.transaction do
        # ensure that qiscus_room_id exist in chat_rooms
        candidate_mute_chat_rooms = ChatRoom.where("chat_rooms.qiscus_room_id IN (?)", qiscus_room_ids)
        candidate_mute_chat_rooms_ids = candidate_mute_chat_rooms.pluck(:id)

        qiscus_room_id_in_database = candidate_mute_chat_rooms.pluck(:qiscus_room_id)

        # chat room not found
        if qiscus_room_ids.size != qiscus_room_id_in_database.size
          qiscus_room_ids_not_found = qiscus_room_ids.map(&:to_i) - qiscus_room_id_in_database
          raise Exception.new("Chat room with qiscus_room_id #{qiscus_room_ids_not_found} not found.")
        end 

        # chat_room_id already in mute chat rooms
        already_been_in_mute_chat_rooms = current_mute_chat_rooms.pluck(:chat_room_id)

        # chat rooms to be muted is only chat rooms where not in mute chat rooms
        duplicat_chat_rooms = candidate_mute_chat_rooms_ids & already_been_in_mute_chat_rooms # duplicat chat rooms
        if !duplicat_chat_rooms.empty?
          qiscus_room_ids = ChatRoom.where("chat_rooms.id IN (?)", duplicat_chat_rooms).pluck(:qiscus_room_id)
          raise Exception.new("Chat room with qiscus_room_id #{qiscus_room_ids} already muted.")
        end


        # now add to mute chat rooms
        chat_rooms_to_be_muted = Array.new
        candidate_mute_chat_rooms_ids.each do |id|
          # double check ifchat_rooms_to_be_muted chat room already been in pin chat rooms.
          # maybe in race condition it throw error if chat room already been in muted chat and then breaks all
          # transaction
          if MuteChatRoom.find_by(user_id: @current_user.id, chat_room_id: id).nil?
            chat_rooms_to_be_muted.push({:user_id => @current_user.id, :chat_room_id => id})
          end
        end

        # add pin chat rooms
        MuteChatRoom.create(chat_rooms_to_be_muted)
      end

      # last, load chat room that successfully to be mute
      qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
      sdk_status, chat_room_sdk_info = qiscus_sdk.get_rooms_info(@current_user.qiscus_email, qiscus_room_ids)

      page = 1
      per_page = 100

      _, chat_rooms = ChatRoomHelper.load_for(@current_user, chat_room_sdk_info, page, per_page)

      mute_chat_rooms = []

      chat_rooms.each do |cr|
        mute_chat_rooms << cr if qiscus_room_ids.include? cr["qiscus_room_id"].to_s
      end

      render json: {
        data: mute_chat_rooms
      }

    rescue ActiveRecord::RecordInvalid => e
      msg = ""
      e.record.errors.map do |k, v|
        key = k.to_s.humanize
        msg = msg + "#{key} #{v}, "
      end

      msg = msg.chomp(", ") + "."
      render json: {
        error: {
          message: msg
        }
      }, status: 422 and return

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {delete} /api/v1/chat/conversations/mute_chats Delete Mute Chat Rooms
  # @apiDescription Delete Mute Chat Rooms
  #
  # @apiName DeleteMuteChatRooms
  # @apiGroup Mute Chat Rooms
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Array} qiscus_room_id[] Array of qiscus_room_id, e.g: `qiscus_room_id[]=1&qiscus_room_id[]=2`
  # =end
  def destroy_mute_chats
    begin 
      qiscus_room_id = params[:qiscus_room_id]
      qiscus_room_ids = qiscus_room_id.to_a

      if !qiscus_room_id.is_a?(Array)
        raise Exception.new("Qiscus room id must be an array of qiscus room id.")
      end

      # anticipate empty index of qiscus room id
      qiscus_room_ids.each do |id|
        if id.nil? || id == ""
          raise Exception.new("Qiscus room id must be present.")
        end
      end

      mute_chat_rooms_ids = nil
      ActiveRecord::Base.transaction do
        chat_rooms = ChatRoom.where("chat_rooms.qiscus_room_id IN (?)", qiscus_room_ids)
        chat_room_ids = chat_rooms.pluck(:id)

        # anticipate invalid qiscus_room_id
        qiscus_room_id_in_database = chat_rooms.pluck(:qiscus_room_id)
        if qiscus_room_ids.size != qiscus_room_id_in_database.size
          invalid_qiscus_room_ids = qiscus_room_ids.map(&:to_i) - qiscus_room_id_in_database
          raise Exception.new("Invalid chat room with qiscus_room_id #{invalid_qiscus_room_ids}.")
        end

        # get all mute chat rooms
        mute_chat_rooms = MuteChatRoom.where(user_id: @current_user.id).where("mute_chat_rooms.chat_room_id IN (?)", chat_room_ids)
        mute_chat_rooms_ids = mute_chat_rooms.pluck(:chat_room_id)

        # anticipate qiscus_room_id that not in mute chat
        mute_chat_room_qiscus_room_ids = ChatRoom.where("chat_rooms.id IN (?)", mute_chat_rooms_ids).pluck(:qiscus_room_id)
        qiscus_room_ids_not_found = qiscus_room_ids.map(&:to_i) - mute_chat_room_qiscus_room_ids
        if !qiscus_room_ids_not_found.empty?
          raise Exception.new("Chat room with qiscus_room_id #{qiscus_room_ids_not_found} is not mute chats.")
        end

        mute_chat_rooms.destroy_all
      end

      # last, load chat room that successfully to be mute
      qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
      sdk_status, chat_room_sdk_info = qiscus_sdk.get_rooms_info(@current_user.qiscus_email, qiscus_room_ids)

      page = 1
      per_page = 100

      _, chat_rooms = ChatRoomHelper.load_for(@current_user, chat_room_sdk_info, page, per_page)

      # mute chat_room
      mute_chat_rooms = []
      chat_rooms.each do |cr|
        mute_chat_rooms << cr if qiscus_room_ids.include? cr["qiscus_room_id"].to_s
      end

      render json: {
        data: mute_chat_rooms
      } and return

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

end