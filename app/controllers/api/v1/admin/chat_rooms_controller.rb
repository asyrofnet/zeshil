require 'csv'

class Api::V1::Admin::ChatRoomsController < ProtectedController
  before_action :authorize_admin
  before_action :ensure_raw_file, only: [:import_group_chat]

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/admin/chat_rooms Index All Chat Room
  # @apiName AdminAllChatRoom
  # @apiDescription Index all chat room. Admin will only see chat room in their scope (same application id)
  # and can not see chat room in other application scope
  #
  # @apiGroup Admin - Chat Rooms
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {String} qiscus_room_name Filter by qiscus room name
  # @apiParam {String} group_chat_name Filter by group chat name
  # @apiParam {Number} [page=1] Page number
  # =end
  def index
    chat_rooms = nil
    total = 0
    begin
      ActiveRecord::Base.transaction do
        application = @current_user.application
        users_id = User.where(application_id: application.id).pluck(:id)
        chat_rooms = ChatRoom.where("chat_rooms.user_id IN (?)", users_id).order(created_at: :desc)

        chat_rooms = chat_rooms.where("LOWER(chat_rooms.qiscus_room_name) LIKE ?", "%#{params[:qiscus_room_name]}%") if params[:qiscus_room_name].present? && params[:qiscus_room_name] != ""
        chat_rooms = chat_rooms.where("LOWER(chat_rooms.group_chat_name) LIKE ?", "%#{params[:group_chat_name]}%") if params[:group_chat_name].present? && params[:group_chat_name] != ""

        total = chat_rooms.count
        chat_rooms = chat_rooms.page(params[:page]).per(25)
      end

      render json: {
        per_page: 25,
        total_data: total,
        data: chat_rooms
      }
    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # create new chat room
  # currently only one to one chat room, only admin AND target user since SDK not yet support it
  def create
    begin
      chat_room = nil
      ActiveRecord::Base.transaction do
        qiscus_token = @current_user.qiscus_token
        application = @current_user.application

        target_user_id = params[:target_user_id]

        if target_user_id.nil? || target_user_id == ""
          raise StandardError.new("Target user id can not be blank.")
        end

        target_user = User.find(target_user_id)
        email_sdk = target_user.qiscus_email

        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        room = qiscus_sdk.get_or_create_room_with_target(qiscus_token, [email_sdk])

        chat_room = ChatRoom.where(qiscus_room_id: room.id, is_group_chat: false).first

        # if chat room with room id and room topic id not exist then create it
        if chat_room.nil?
          chat_name = ""
          if !params[:chat_name].nil? && params[:chat_name] != ""
            chat_name = params[:chat_name]
          else
            chat_name = "Group Chat Name"
          end

          chat_room = ChatRoom.new(
            group_chat_name: chat_name,
            qiscus_room_name: room.name,
            qiscus_room_id: room.id,
            is_group_chat: room.is_group_chat,
            user_id: @current_user.id
          )

          chat_room.save!

          ChatUser.create([
            {chat_room_id: chat_room.id, user_id: @current_user.id},
            {chat_room_id: chat_room.id, user_id: target_user.id}
          ])
        end

        # if exist then return the first one
      end # commit or rollback

      render json: {
        data: chat_room
      }
    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # Get or create room with target for group chat
  def group_chat
    begin
      chat_room = nil
      ActiveRecord::Base.transaction do
        qiscus_token = @current_user.qiscus_token
        application = @current_user.application

        chat_name = ""
        if !params[:chat_name].nil? && params[:chat_name] != ""
          chat_name = params[:chat_name]
        else
          chat_name = "Group Chat Name"
        end

        target_user_id = params[:target_user_id]

        if !target_user_id.is_a?(Array)
          raise StandardError.new("Target user id must be an array of user id.")
        end

        target_user = User.where("id IN (?)", target_user_id.to_a)
        target_user_id = target_user.pluck(:id)
        email_sdk = target_user.pluck(:qiscus_email)

        if email_sdk.empty?
          raise StandardError.new("Target user is not match in any record.")
        end

        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        # if qiscus SDK support group chat, then change this code block
        room = qiscus_sdk.create_room(chat_name, email_sdk, @current_user.qiscus_email)
        # until this block

        chat_room = ChatRoom.where(qiscus_room_id: room.id, is_group_chat: true).first

        # if chat room with room id and room topic id not exist then create it
        if chat_room.nil?
          chat_room = ChatRoom.new(
            group_chat_name: chat_name,
            qiscus_room_name: room.name,
            qiscus_room_id: room.id,
            is_group_chat: true,
            user_id: @current_user.id
          )

          chat_room.save!

          chat_user = ChatUser.new
          chat_user.chat_room_id = chat_room.id
          chat_user.user_id = @current_user.id
          chat_user.save!

          # save each participant
          target_user_id.to_a.each do |target_user_id|
            chat_user = ChatUser.new
            chat_user.chat_room_id = chat_room.id
            chat_user.user_id = target_user_id
            chat_user.save!
          end
        end

        # if exist then return the first one
      end

      render json: {
        data: chat_room
      }
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
  # @api {get} /api/v1/admin/chat_rooms/:id Show Chat Room
  # @apiName AdminShowChatRoom
  #
  # @apiGroup Admin - Chat Rooms
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {Number} id Chat room id in qisme engine
  # =end
  def show
    begin
      chat_room = ChatRoom.find(params[:id])
      render json: {
        data: chat_room.as_json()
      }
    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/admin/chat_rooms/:id/change_group_name Change Chat Room Name
  # @apiName AdminChangeChatRoomName
  #
  # @apiGroup Admin - Chat Rooms
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {Number} id Chat room id in qisme engine
  # @apiParam {String} group_chat_name New group name
  # =end
  def change_group_name
    begin
      chat_room = nil
      ActiveRecord::Base.transaction do
        id = params[:id]
        group_chat_name = params[:group_chat_name]

        chat_room = ChatRoom.find(id)

        chat_room.update_attribute(:group_chat_name, group_chat_name)

        chat_room = chat_room.as_json()
      end

      render json: {
        data: chat_room
      } and return

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
  # @api {POST} /api/v1/admin/chat_rooms/delete_all_participants Delete All Group Participants
  # @apiDescription Delete all group participants. Then set is_official_chat false when
  # group chat have no participants.
  # Because deleted chat rooms will not be used.
  #
  # @apiName DeleteAllParticipants
  # @apiGroup Admin - Chat Rooms
  # @apiPermission Admin
  #
  # @apiParam {Array} qiscus_room_id[] Array of integer of qiscus_room_id,
  # e.g: `qiscus_room_id[]=1&qiscus_room_id[]=2`
  # @apiParam {String} access_token User access token
  # =end
  def delete_all_participants
    begin
      qiscus_room_ids = nil
      ActiveRecord::Base.transaction do
        application= @current_user.application

        qiscus_room_ids = params[:qiscus_room_id]
        if !qiscus_room_ids.is_a?(Array)
          raise StandardError.new("Qiscus room id must be an array of qiscus room id.")
        end
        qiscus_room_ids = qiscus_room_ids.to_a

        # anticipate empty index array of qiscus room id
        qiscus_room_ids.each do |id|
          if id.nil? || id == ""
            raise StandardError.new("Qiscus room id must be present.")
          end
        end

        # ensure that qiscus_room_id exist in chat_rooms
        chat_rooms = ChatRoom.where("chat_rooms.qiscus_room_id IN (?)", qiscus_room_ids)
        chat_room_ids = chat_rooms.pluck(:id)

        qiscus_room_id_in_database = chat_rooms.pluck(:qiscus_room_id)

        # chat room not found
        if qiscus_room_ids.size != qiscus_room_id_in_database.size
          qiscus_room_ids_not_found = qiscus_room_ids.map(&:to_i) - qiscus_room_id_in_database
          raise StandardError.new("Chat room with qiscus_room_id #{qiscus_room_ids_not_found} not found.")
        end

        # remove participants from group
        user_ids = Array.new
        qiscus_room_ids.each do |qiscus_room_id|
          chat_room = ChatRoom.find_by(qiscus_room_id: qiscus_room_id, is_group_chat: true)
          if !chat_room.nil?
            chat_room_participants = chat_room.chat_users.pluck(:user_id)
            user_ids.push(chat_room_participants)

            chat_room.chat_users.delete_all
          end

          # make is_official_chat flag false when room have no participants
          if chat_room.chat_users.count == 0
            chat_room.update_attribute(:is_official_chat, false)
          end

          ChatRoomHelper.reset_chat_room_cache_for_users(chat_room_participants)
        end

        # remove group participants in Qiscus SDK using background job
        RemoveGroupParticipantsJob.perform_later(application.id, qiscus_room_ids, user_ids)

      end

      # return deleted chat rooms
      chat_rooms = ChatRoom.where("chat_rooms.qiscus_room_id IN (?)", qiscus_room_ids)
      chat_rooms = chat_rooms.as_json

      render json: {
        data: chat_rooms
      } and return

    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422
    end
  end

  def import_group_chat
    uploaded_io = @raw_file

    begin
      chat_room = nil
      target_user_id = Array.new

      ActiveRecord::Base.transaction do
        qiscus_token = @current_user.qiscus_token
        application = @current_user.application

        # Start read csv to get target_user_id
        file_path = uploaded_io.read
        csv = CSV.new(file_path, :headers => true, :encoding => 'iso-8859-1:utf-8')
        i = 0
        csv.each do |row|
          data = row.to_hash
          phone_number = data["phone_number"]

          user = User.find_by(phone_number: phone_number)
          target_user_id[i] = user.id
          i+=1
        end
        # End read csv to get target_user_id


        if !target_user_id.is_a?(Array)
          raise StandardError.new("Target user id must be an array of user id.")
        end

        chat_name = ""
        if !params[:chat_name].nil? && params[:chat_name] != ""
          chat_name = params[:chat_name]
        else
          chat_name = "Group Chat Name"
        end

        target_user = User.where("id IN (?)", target_user_id.to_a)
        email_sdk = target_user.pluck(:qiscus_email)
        email_sdk = email_sdk + [@current_user.qiscus_email]

        # prevent error if target user is not found
        if target_user.empty?
          raise StandardError.new("No one target user found.")
        end

        # Backend need to create chat room in SDK
        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        # if qiscus SDK support group chat, then change this code block
        room = qiscus_sdk.create_room(chat_name, email_sdk, @current_user.qiscus_email)
        qiscus_room_id = room.id

        # qiscus_room_id = params[:qiscus_room_id]
        if qiscus_room_id.nil? || qiscus_room_id == ""
          raise StandardError.new("Qiscus room id can not be blank.")
        end

        chat_room = ChatRoom.find_by(qiscus_room_id: qiscus_room_id, application_id: @current_user.application.id)

        # if chat room with room id and room topic id not exist then create it
        group_avatar_placeholder = "https://d1edrlpyc25xu0.cloudfront.net/kiwari-prod/image/upload/1yahAVOqLy/1510804279-default_group_avatar.png"

        if params[:group_avatar_url].present? && !params[:group_avatar_url].nil? && params[:group_avatar_url] != ""
          group_avatar_placeholder = params[:group_avatar_url]
        end


        is_official_chat = params[:is_official_chat]
        if is_official_chat == "true" || params[:is_official_chat] == true
          is_official_chat = true
        else
          is_official_chat = false
        end

        target_user_id = target_user.first.id
        initiator = @current_user
        if initiator.is_official
          initiator = target_user.first # initiator must be member
          target_user_id = @current_user.id # target user must be official
        end

        if chat_room.nil?
          chat_room = ChatRoom.new(
            group_chat_name: chat_name,
            qiscus_room_name: chat_name,
            qiscus_room_id: qiscus_room_id,
            is_group_chat: true,
            user_id: initiator.id,
            target_user_id: target_user_id,
            application_id: @current_user.application.id,
            group_avatar_url: group_avatar_placeholder,
            is_official_chat: is_official_chat
          )

          chat_room.save!

          chat_user = ChatUser.new
          chat_user.chat_room_id = chat_room.id
          chat_user.user_id = @current_user.id
          chat_user.save!

          # save each participant
          target_user.each do |target_user_id|
            chat_user = ChatUser.new
            chat_user.chat_room_id = chat_room.id
            chat_user.user_id = target_user_id.id
            chat_user.save!
          end
        else
          # if exist then return error with warning that qiscus room id has been inserted before
          raise StandardError.new("Qiscus room id has been inserted before, it must be unique.")
        end
      end

      render json: {
        data: chat_room.as_json({:me => @current_user})
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

  private
    def ensure_raw_file
      @raw_file = params[:raw_file]

      render json: {
        error: {
            message: 'invalid raw file'
          }
        }, status: 422 unless @raw_file
    end

end