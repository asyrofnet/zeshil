class Api::V1::Chat::Conversations::PinChatsController < ProtectedController
  before_action :authorize_user

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/chat/conversations/pin_chats Get Pin Chat Rooms
  # @apiName ListPinChatRooms
  # @apiGroup Pin Chat Rooms
  #
  # @apiParam {String} access_token User access token
  # =end
  def index
    begin
			chat_room_ids = @current_user.pin_chat_rooms.pluck(:chat_room_id)
			pin_chat_rooms = ChatRoom.where("chat_rooms.id IN (?)", chat_room_ids).pluck(:qiscus_room_id)

			render json: {
				data: pin_chat_rooms
			}
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/chat/conversations/pin_chats Add Pin Chat Rooms
  # @apiDescription Add Pin Chat Rooms
  #
  # @apiName AddPinChatRooms
  # @apiGroup Pin Chat Rooms
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Array} qiscus_room_id[] Array of qiscus_room_id, e.g: `qiscus_room_id[]=1&qiscus_room_id[]=2`
  # =end
  def create
    begin
      qiscus_room_id = params[:qiscus_room_id]

      if !qiscus_room_id.is_a?(Array)
        raise StandardError.new("Qiscus room id must be an array of qiscus room id.")
      end

      qiscus_room_ids = qiscus_room_id.to_a

      # anticipate empty index of qiscus room id
      qiscus_room_ids.each do |id|
        if id.nil? || id == ""
          raise StandardError.new("Qiscus room id must be present.")
        end
      end

      # get current pin chat rooms
      current_pin_chat_rooms = PinChatRoom.where(user_id: @current_user.id).order(created_at: :desc)
      # count current pin chat rooms
      count_current_pin_chat_rooms = current_pin_chat_rooms.count

      max = 3 # user can only pin up (max) chats
      if count_current_pin_chat_rooms + qiscus_room_ids.size > max
        raise StandardError.new("You can only pin up #{max} chats.")
      end

      chat_rooms = nil
      ActiveRecord::Base.transaction do
        # ensure that qiscus_room_id exist in chat_rooms
        candidate_pin_chat_rooms = ChatRoom.where("chat_rooms.qiscus_room_id IN (?)", qiscus_room_ids)
        candidate_pin_chat_rooms_ids = candidate_pin_chat_rooms.pluck(:id)

        qiscus_room_id_in_database = candidate_pin_chat_rooms.pluck(:qiscus_room_id)

        # chat room not found
        if qiscus_room_ids.size != qiscus_room_id_in_database.size
          qiscus_room_ids_not_found = qiscus_room_ids.map(&:to_i) - qiscus_room_id_in_database
          raise StandardError.new("Chat room with qiscus_room_id #{qiscus_room_ids_not_found} not found.")
        end

        # chat_room_id already in pin chat rooms
        already_been_in_pin_chat_rooms = current_pin_chat_rooms.pluck(:chat_room_id)

        # chat rooms to be pinned is only chat rooms where not in pin chat rooms
        duplicat_chat_rooms = candidate_pin_chat_rooms_ids & already_been_in_pin_chat_rooms # duplicat chat rooms
        if !duplicat_chat_rooms.empty?
          qiscus_room_ids = ChatRoom.where("chat_rooms.id IN (?)", duplicat_chat_rooms).pluck(:qiscus_room_id)
          raise StandardError.new("Chat room with qiscus_room_id #{qiscus_room_ids} already pinned.")
        end


        # now add to pin chat rooms
        chat_rooms_to_be_pinned = Array.new
        candidate_pin_chat_rooms_ids.each do |id|
          # double check ifchat_rooms_to_be_pinned chat room already been in pin chat rooms.
          # maybe in race condition it throw error if chat room already been in pinned chat and then breaks all
          # transaction
          if PinChatRoom.find_by(user_id: @current_user.id, chat_room_id: id).nil?
            chat_rooms_to_be_pinned.push({:user_id => @current_user.id, :chat_room_id => id})
          end
        end

        # add pin chat rooms
        PinChatRoom.create(chat_rooms_to_be_pinned)
      end

      # last, load chat room that successfully to be pin
      qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
      sdk_status, chat_room_sdk_info = qiscus_sdk.get_rooms_info(@current_user.qiscus_email, qiscus_room_ids)

      page = 1
      per_page = qiscus_room_ids.size

      _, chat_rooms = ChatRoomHelper.load_for(@current_user, chat_room_sdk_info, page, per_page)

      render json: {
        data: chat_rooms
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

    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {delete} /api/v1/chat/conversations/pin_chats Delete Pin Chat Rooms
  # @apiDescription Delete Pin Chat Rooms
  #
  # @apiName DeletePinChatRooms
  # @apiGroup Pin Chat Rooms
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Array} qiscus_room_id[] Array of qiscus_room_id, e.g: `qiscus_room_id[]=1&qiscus_room_id[]=2`
  # =end
  def destroy_pin_chats
    begin
      qiscus_room_id = params[:qiscus_room_id]

      if !qiscus_room_id.is_a?(Array)
        raise StandardError.new("Qiscus room id must be an array of qiscus room id.")
      end

      qiscus_room_ids = qiscus_room_id.to_a

      # anticipate empty index of qiscus room id
      qiscus_room_ids.each do |id|
        if id.nil? || id == ""
          raise StandardError.new("Qiscus room id must be present.")
        end
      end

      pin_chat_rooms_ids = nil
      ActiveRecord::Base.transaction do
        chat_rooms = ChatRoom.where("chat_rooms.qiscus_room_id IN (?)", qiscus_room_ids)
        chat_room_ids = chat_rooms.pluck(:id)

        # anticipate invalid qiscus_room_id
        qiscus_room_id_in_database = chat_rooms.pluck(:qiscus_room_id)
        if qiscus_room_ids.size != qiscus_room_id_in_database.size
          invalid_qiscus_room_ids = qiscus_room_ids.map(&:to_i) - qiscus_room_id_in_database
          raise StandardError.new("Invalid chat room with qiscus_room_id #{invalid_qiscus_room_ids}.")
        end

        # get all pin chat rooms
        pin_chat_rooms = PinChatRoom.where(user_id: @current_user.id).where("pin_chat_rooms.chat_room_id IN (?)", chat_room_ids)
        pin_chat_rooms_ids = pin_chat_rooms.pluck(:chat_room_id)

        # anticipate qiscus_room_id that not in pin chat
        pin_chat_room_qiscus_room_ids = ChatRoom.where("chat_rooms.id IN (?)", pin_chat_rooms_ids).pluck(:qiscus_room_id)
        qiscus_room_ids_not_found = qiscus_room_ids.map(&:to_i) - pin_chat_room_qiscus_room_ids
        if !qiscus_room_ids_not_found.empty?
          raise StandardError.new("Chat room with qiscus_room_id #{qiscus_room_ids_not_found} is not pin chats.")
        end

        pin_chat_rooms.destroy_all
      end

      # last, load chat room that successfully to be unpin
      chat_rooms = ChatRoom.where("chat_rooms.id IN (?)", pin_chat_rooms_ids)
      chat_rooms = chat_rooms.as_json
      chat_rooms = chat_rooms.map do |e|
        e.merge!('is_pin_chat' => false )
        e.merge!('pin_chat_room_id' => nil)
      end

      render json: {
        data: chat_rooms
      } and return

    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

end