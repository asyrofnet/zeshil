class Api::V1::Chat::ConversationsController < ProtectedController
  before_action :authorize_user
  before_action :ensure_raw_file, only: [:change_group_avatar]

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/chat/conversations Get Conversation List
  # @apiName ChatList
  # @apiGroup Chat
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} [page=1] Pagination. Per page is 10 conversation.
  # @apiParam {Boolean} [get_all=false] Show all conversation. Get_all = 'true' or 'false'
  # =end
  def index
    begin
      # get current time, to measure calling time each process
      start_time_pluck_room_id = Time.now
      qiscus_room_ids = @current_user.chat_rooms.pluck(:qiscus_room_id)
      end_time_pluck_room_id = Time.now

      chat_room_sdk_info = []

      # if not empty qiscus room id, then call sdk to avoid error
      start_time_sdk = Time.now
      if qiscus_room_ids.empty? == false
        qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
        sdk_status, chat_room_sdk_info = qiscus_sdk.get_rooms_info(@current_user.qiscus_email, qiscus_room_ids)

        if sdk_status != 200
          room_ids = []
          splitted_string = chat_room_sdk_info['error']['errors']['room_id'][0].gsub(/\s+/m, ' ').strip.split(" ")
          if !splitted_string.empty?
            splitted_string = splitted_string.first
            room_ids = splitted_string.strip.split(",").map(&:to_i)
            room_ids = room_ids.uniq
          end

          # now we now array of room id where user has no access to it
          # so delete it from chat user
          # first, get chat room id from backend
          local_room_id = ChatRoom.where("chat_rooms.qiscus_room_id IN (?)", room_ids).where(application_id: @current_user.application.id).pluck(:id)

          # using destroy all will invoke callback after destroy
          # http://guides.rubyonrails.org/active_record_callbacks.html
          ChatUser.where(user_id: @current_user.id).where("chat_users.chat_room_id IN (?)", local_room_id).destroy_all

          # after that, try to call SDK again, this to minimize user show an error while call this API due to SDK not found error
          # first, load new chat room again, using new call to ensure that data will be retrieved is a new data
          qiscus_room_ids = User.find(@current_user.id).chat_rooms.pluck(:qiscus_room_id)

          chat_room_sdk_info = []
          if qiscus_room_ids.empty? == false
            qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)

            if qiscus_room_ids.count > 100
              array_of_ids = qiscus_room_ids.each_slice(100).to_a
              merged_info = Hash.new
              array_of_ids.each do | ids |
                sdk_status, chat_room_sdk_info = qiscus_sdk.get_rooms_info(@current_user.qiscus_email, ids)

                # if after second call the error from SDK still occured, then throw an error instead trying a new call.
                if sdk_status != 200
                  raise StandardError.new(chat_room_sdk_info['error']['detailed_messages'].to_a.join(", ").capitalize)
                end

                merged_info.merge!(chat_room_sdk_info)
              end

              chat_room_sdk_info = merged_info
            else
              sdk_status, chat_room_sdk_info = qiscus_sdk.get_rooms_info(@current_user.qiscus_email, qiscus_room_ids)

              # if after second call the error from SDK still occured, then throw an error instead trying a new call.
              if sdk_status != 200
                raise StandardError.new(chat_room_sdk_info['error']['detailed_messages'].to_a.join(", ").capitalize)
              end
            end
          end

        end
      end
      end_time_sdk = Time.now

      page = params[:page]
      if !page.present? || page.to_i <= 0
        page = 1
      end

      per_page = 10

      # If params page not present then show all conversations
      if !params[:page].present? || params[:page].to_i <= 0
        per_page = 100
      end

			# Overwrite per_page to show all data
			if params[:get_all] == true || params[:get_all] == 1 || params[:get_all] == "1"
				if qiscus_room_ids.size > 0
					per_page = qiscus_room_ids.size
				end
			end

      start_chat_room_load = Time.now
      chat_rooms_total, chat_rooms = ChatRoomHelper.load_for(@current_user, chat_room_sdk_info, page, per_page)
      end_chat_room_load = Time.now

      pluck_room_id_time = (end_time_pluck_room_id - start_time_pluck_room_id) * 1000
      sdk_call_time = (end_time_sdk - start_time_sdk) * 1000
      chat_room_load = (end_chat_room_load - start_chat_room_load) * 1000

      # roundup total_page
      total_page = (chat_rooms_total/per_page.to_f).ceil

      render json: {
        meta: {
          total: chat_rooms_total,
          per_page: per_page,
          total_page: ((chat_rooms_total / per_page) <= 0) ? 1 : (total_page),
          current_page: (params[:page].to_i <= 0) ? 1 : params[:page].to_i,
          debug: {
            pluck_room_id: "#{pluck_room_id_time} ms",
            sdk_call: "#{sdk_call_time} ms",
            chat_room_load: "#{chat_room_load} ms",
            total_time: "#{pluck_room_id_time + sdk_call_time + chat_room_load} ms"
          }
        },
        data: chat_rooms
      } and return
    rescue => e
      render json: {
        error: {
          message: e.message,
          backtrace: e.backtrace
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/chat/conversations/:id Show single chat
  # @apiDescription show chat room detail
  # @apiName ChatShow
  # @apiGroup Chat
  #
  # @apiParam {Number} id Qisme chat room id
  # @apiParam {String} access_token User access token
  # =end
  def show
    begin
      chat_room = ChatRoom.includes({
            users: [:roles, :application],
            # user: [:roles, :application],
          })
      chat_room = chat_room.find_by(id: params[:id], application_id: @current_user.application.id)
      if chat_room.users.pluck(:id).to_a.include?(@current_user.id)

        qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
        sdk_status, chat_room_sdk_info = qiscus_sdk.get_rooms_info(@current_user.qiscus_email, [chat_room.qiscus_room_id])

        if sdk_status != 200
          raise StandardError.new(chat_room_sdk_info['error']['detailed_messages'].to_a.join(", ").capitalize)
        end

        chat_room = chat_room.as_json({:me => @current_user, :chat_room_sdk_info => chat_room_sdk_info})

        # get user current contact
        contact_ids = @current_user.contacts.pluck(:contact_id)
        current_user_contacts = User.where("id IN (?)", contact_ids).pluck(:id)

        # for mapping is favorite status
        favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)

        chat_room['users'].map do |user|
          # if user id included in contact id list, then return true, otherwise return false
          is_contact = current_user_contacts.include?(user['id'])
          user.merge!('is_contact' => is_contact)

          is_favored = (favored_status.to_h[ user["id"] ] == nil) ? false : favored_status.to_h[ user["id"] ]
          user.merge!('is_favored' => is_favored)
        end

        render json: {
          data: chat_room
        } and return

      else
        raise StandardError.new("You are not member of this group.")
      end
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
  # @api {post} /api/v1/chat/conversations Get or create room with target
  # @apiDescription Get or create single chat
  # @apiName CreateSingleChat
  # @apiGroup Chat
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} target_user_id User id in Qisme database
  # @apiParam {Number} qiscus_room_id Qiscus room id from SDK get_or_create_room_with_target. If client doesn't send this params, it's mean backend will create room in sdk
  # =end
  def create
    begin
      chat_room = nil
      ActiveRecord::Base.transaction do
        qiscus_token = @current_user.qiscus_token
        application = @current_user.application

        target_user_id = params[:target_user_id]

        if target_user_id.nil? || target_user_id == ""
          raise StandardError.new("Target user id can not be blank.")
        else
          if target_user_id.to_s == @current_user.id.to_s
            raise StandardError.new("You can not chat only with yourself.")
          end
        end

        target_user = User.find(target_user_id)
        email_sdk = target_user.qiscus_email

        emails = [@current_user.qiscus_email, target_user.qiscus_email]

        # If client doesn't qiscus_room_id params, it's mean backend will create room in sdk
        if params[:qiscus_room_id].nil? || params[:qiscus_room_id] == ""
          qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
          room = qiscus_sdk.get_or_create_room_with_target(qiscus_token, [email_sdk])
          qiscus_room_id = room.id
        else
          qiscus_room_id = params[:qiscus_room_id]
        end

        # Backend need to get chat room from to sdk to ensure single chat room contain valid participants
        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        room = qiscus_sdk.get_or_create_room_with_target_rest(emails)

        if qiscus_room_id.to_i != room.id
          raise StandardError.new("Invalid qiscus_room_id.")
        end

        chat_room = ChatRoom.find_by(qiscus_room_id: qiscus_room_id, application_id: @current_user.application.id)

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
            qiscus_room_name: chat_name,
            qiscus_room_id: qiscus_room_id,
            is_group_chat: false,
            user_id: @current_user.id,
            target_user_id: target_user.id,
            application_id: @current_user.application.id
          )

          chat_room.save!

          ChatUser.create(chat_room_id: chat_room.id, user_id: @current_user.id) unless ChatUser.exists?(chat_room_id: chat_room.id, user_id: @current_user.id)
          ChatUser.create(chat_room_id: chat_room.id, user_id: target_user.id) unless ChatUser.exists?(chat_room_id: chat_room.id, user_id: target_user.id)

					# if chat with official then post comment 'get started'
					if target_user.is_official
						message = "Get started"

						qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
						qiscus_sdk.post_comment(@current_user.qiscus_token, qiscus_room_id, message)
					end
        else
          # if exist then return error with warning that qiscus room id has been inserted before
          # raise StandardError.new("Qiscus room id has been inserted before, it must be unique.")
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

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/chat/conversations/group_chat Create group chat with participants
  # @apiDescription Create group chat with participants
  # Please note that if initiator (your access token id) is official, it will be logged as target user id.
  #
  # @apiName CreateGroupChat
  # @apiGroup Chat
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Array} target_user_id[] Array of user id in Qisme database
  # @apiParam {Number} qiscus_room_id Qiscus room id from SDK create_room. If client doesn't send this params, it's mean backend will create room in sdk
  # @apiParam {String} [chat_name="Group Chat Name"] Group chat name
  # @apiParam {String} [group_avatar_url=https://d1edrlpyc25xu0.cloudfront.net/kiwari-prod/image/upload/1yahAVOqLy/1510804279-default_group_avatar.png] URL of picture for group avatar
  # @apiParam {Boolean} [is_official_chat=false] It is official group chat or not
  # =end
  def group_chat
    begin
      chat_room = nil
      ActiveRecord::Base.transaction do
        qiscus_token = @current_user.qiscus_token
        application = @current_user.application

        target_user_id = params[:target_user_id]

        if !target_user_id.is_a?(Array)
          raise StandardError.new("Target user id must be an array of user id.")
        end

        if target_user_id.count > 100
          raise StandardError.new("Maximum group participants is 100. Please use the channel instead for more than 100 participants")
        end

        # need to convert array of target_user_id (string) into integer
        target_user_id = target_user_id.collect{|i| i.to_i}

        chat_name = ""
        if !params[:chat_name].nil? && params[:chat_name] != ""
          chat_name = params[:chat_name]
        else
          chat_name = "Group Chat Name"
        end


        is_official_chat = params[:is_official_chat]
        if is_official_chat == "true" || params[:is_official_chat] == true
          is_official_chat = true
        else
          is_official_chat = false
        end

        if is_official_chat
          chat_name = @current_user.fullname
        end

        target_user = User.where("id IN (?)", target_user_id.to_a)
        target_user = target_user.sort_by { |u| target_user_id.index(u.id) } # sort by index of target_user_id
        email_sdk = target_user.pluck(:qiscus_email)
        email_sdk = email_sdk + [@current_user.qiscus_email]

        # prevent error if target user is not found
        if target_user.empty?
          raise StandardError.new("No one target user found.")
        end

        # default group avatar
        group_avatar_placeholder = "https://d1edrlpyc25xu0.cloudfront.net/kiwari-prod/image/upload/1yahAVOqLy/1510804279-default_group_avatar.png"
        if params[:group_avatar_url].present? && !params[:group_avatar_url].nil? && params[:group_avatar_url] != ""
          group_avatar_placeholder = params[:group_avatar_url]
        end

        # If client doesn't qiscus_room_id params, it's mean backend will create room in sdk
        if params[:qiscus_room_id].nil? || params[:qiscus_room_id] == ""
          qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
          room = qiscus_sdk.create_room(chat_name, email_sdk, @current_user.qiscus_email, group_avatar_placeholder)
          qiscus_room_id = room.id
        else
          qiscus_room_id = params[:qiscus_room_id]
        end

        chat_room = ChatRoom.find_by(qiscus_room_id: qiscus_room_id, application_id: @current_user.application.id)

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
          chat_user.is_group_admin = true # group creator assign as group admin
          chat_user.save!

          # save each participant
          target_user.each do |target_user_id|
            chat_user = ChatUser.new
            chat_user.chat_room_id = chat_room.id
            chat_user.user_id = target_user_id.id
            chat_user.is_group_admin = false # group participant assign as group member
            chat_user.save!
          end

          if is_official_chat == false
            # Backend need to post system event message after create new group with participants
            # Post system event message with system_event_type = create_room
            system_event_type = "create_room"
            qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
            qiscus_sdk.post_system_event_message(system_event_type, qiscus_room_id, @current_user.qiscus_email, [], chat_name)
          end
        else
          # if exist then return error with warning that qiscus room id has been inserted before
          raise StandardError.new("Qiscus room id has been inserted before, it must be unique.")
        end
      end

      chat_room = chat_room.as_json({:me => @current_user})

      # add group_admins payload in chat_room json
      chat_room.merge!('group_admins' => [@current_user.id])

      render json: {
        data: chat_room
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
  # @api {post} /api/v1/chat/conversations/channel Create Channel
  # @apiDescription Create group chat with participants. Channel is a type of room that allows you to have participants with a maximum 5000 participants. The difference between channel and group chat is users or participants cannot get typing, read, and delivered indicators.
  # Please note that if initiator (your access token id) is official, it will be logged as target user id.
  #
  # @apiName CreateChannel
  # @apiGroup Chat
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Array} target_user_id[] Array of user id in Qisme database
  # @apiParam {Number} qiscus_room_id Qiscus room id from SDK create_room. If client doesn't send this params, it's mean backend will create room in sdk
  # @apiParam {String} [chat_name="Group Chat Name"] Channel name
  # @apiParam {String} [unique_id="Channel Unique Id"] Channel unique id
  # @apiParam {Boolean} [is_official_chat=false] It is official group chat or not
  # =end
  def channel
    begin
      chat_room = nil
      ActiveRecord::Base.transaction do
        qiscus_token = @current_user.qiscus_token
        application = @current_user.application

        target_user_id = params[:target_user_id]

        if !target_user_id.is_a?(Array)
          raise StandardError.new("Target user id must be an array of user id.")
        end

        # need to convert array of target_user_id (string) into integer
        target_user_id = target_user_id.collect{|i| i.to_i}

        chat_name = ""
        if !params[:chat_name].nil? && params[:chat_name] != ""
          chat_name = params[:chat_name]
        else
          chat_name = "Channel Name"
        end

        # unique id created using pattern: :app_id-"channel"-:random_string
        random = SecureRandom.hex
        unique_id = "app-#{@current_user.application.app_id}-channel-#{random}"


        is_official_chat = params[:is_official_chat]
        if is_official_chat == "true" || params[:is_official_chat] == true
          is_official_chat = true
        else
          is_official_chat = false
        end

        if is_official_chat
          chat_name = @current_user.fullname
        end

        target_user = User.where("id IN (?)", target_user_id.to_a)
        target_user = target_user.sort_by { |u| target_user_id.index(u.id) } # sort by index of target_user_id
        email_sdk = target_user.pluck(:qiscus_email)
        email_sdk = email_sdk + [@current_user.qiscus_email]

        # prevent error if target user is not found
        if target_user.empty?
          raise StandardError.new("No one target user found.")
        end

        # default group avatar
        channel_avatar_placeholder = "https://d1edrlpyc25xu0.cloudfront.net/kiwari-prod/image/upload/1yahAVOqLy/1510804279-default_group_avatar.png"
        if params[:channel_avatar_url].present? && !params[:channel_avatar_url].nil? && params[:group_avatar_url] != ""
          group_avatar_placeholder = params[:channel_avatar_url]
        end

        # If client doesn't qiscus_room_id params, it's mean backend will create room in sdk
        if params[:qiscus_room_id].nil? || params[:qiscus_room_id] == ""
          qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
          room = qiscus_sdk.get_or_create_channel(chat_name, unique_id, email_sdk, channel_avatar_placeholder)
          qiscus_room_id = room.id
        else
          qiscus_room_id = params[:qiscus_room_id]
        end

        chat_room = ChatRoom.find_by(qiscus_room_id: qiscus_room_id, application_id: @current_user.application.id)

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
            is_channel: true,
            user_id: initiator.id,
            target_user_id: target_user_id,
            application_id: @current_user.application.id,
            group_avatar_url: group_avatar_placeholder,
            is_official_chat: is_official_chat
          )

          chat_room.save!
          #create is channel true info for user
          UserAdditionalInfo.create_or_update_user_additional_info([target_user_id], UserAdditionalInfo::IS_CHANNEL_KEY, "true")
          chat_user = ChatUser.new
          chat_user.chat_room_id = chat_room.id
          chat_user.user_id = @current_user.id
          chat_user.is_group_admin = true # group creator assign as group admin
          chat_user.save!

          # save each participant
          target_user.each do |target_user_id|
            chat_user = ChatUser.new
            chat_user.chat_room_id = chat_room.id
            chat_user.user_id = target_user_id.id
            chat_user.is_group_admin = false # group participant assign as group member
            chat_user.save!
          end

          if is_official_chat == false
            # Backend need to post system event message after create new group with participants
            # Post system event message with system_event_type = create_room
            system_event_type = "create_room"
            qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
            qiscus_sdk.post_system_event_message(system_event_type, qiscus_room_id, @current_user.qiscus_email, [], chat_name)

          end
        else
          # if exist then return error with warning that qiscus room id has been inserted before
          raise StandardError.new("Qiscus room id has been inserted before, it must be unique.")
        end
      end

      chat_room = chat_room.as_json({:me => @current_user})

      # add group_admins payload in chat_room json
      chat_room.merge!('group_admins' => [@current_user.id])

      render json: {
        data: chat_room
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
  # @api {post} /api/v1/chat/conversations/change_group_name Change Group Name
  # @apiDescription Change Group Name, this will not change group name in SDK, so please change it manually
  # @apiName ChangeGroupName
  # @apiGroup Chat
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} chat_room_id Chat room id which will be renamed, this is qiscus room id
  # @apiParam {String} group_chat_name New group chat name
  # =end
  def change_group_name
    begin
      chat_room = nil
      ActiveRecord::Base.transaction do
        id = params[:chat_room_id]
        group_chat_name = params[:group_chat_name]

        chat_room = ChatRoom.includes({
            users: [:roles, :application],
            # user: [:roles, :application],
          }).find_by(qiscus_room_id: id, application_id: @current_user.application.id)

        # if current user has access or is a participant of this chat room, then change the chat room group name
        if chat_room.users.pluck(:id).to_a.include?(@current_user.id)

          # # no need to activate, this handled by client
          # # update group name in sdk info from back-end
          # qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
          # qiscus_sdk.update_room(@current_user.qiscus_token, chat_room.qiscus_room_id, group_chat_name, chat_room.group_avatar_url)

          chat_room.update_attribute(:group_chat_name, group_chat_name)
          # also update qiscus_room_name, because Android client have update qiscus room name from their SDK API
          chat_room.update_attribute(:qiscus_room_name, group_chat_name)

          # Backend need to post system event message after change room name
          system_event_type = "change_room_name"

          qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
          qiscus_sdk.post_system_event_message(system_event_type, id, @current_user.qiscus_email, [], group_chat_name)

          render json: {
            data: chat_room.as_json({:me => @current_user})
          } and return

        else
          raise StandardError.new("You are not member of this group.")
        end
      end

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
  # @api {post} /api/v1/chat/conversations/change_group_avatar Change Group Avatar
  # @apiDescription Change Group Avatar, this will not change group avatar in SDK, so please change it manually
  # @apiName ChangeGroupAvatar
  # @apiGroup Chat
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} chat_room_id Chat room id which will be changed, this is qiscus room id
  # @apiParam {File} group_avatar Image file
  # =end
  def change_group_avatar
    begin
      chat_room = nil
      ActiveRecord::Base.transaction do
        id = params[:chat_room_id]
        chat_room = ChatRoom.includes({
            users: [:roles, :application],
            # user: [:roles, :application],
          }).find_by(qiscus_room_id: id, application_id: @current_user.application.id)

        # if current user has access or is a participant of this chat room, then change the chat room group name
        if chat_room.users.pluck(:id).to_a.include?(@current_user.id)
          qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
          group_chat_avatar = qiscus_sdk.upload_file(@current_user.qiscus_token, @group_avatar)

          # change group avatar
          chat_room.update_attribute(:group_avatar_url, group_chat_avatar)

          # # no need to activate, this handled by client
          # # update group avatar in sdk info from back-end
          # qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
          # qiscus_sdk.update_room(@current_user.qiscus_token, chat_room.qiscus_room_id, chat_room.group_chat_name, group_chat_avatar)

          # Backend need to post system event message after change room avatar
          system_event_type = "change_room_avatar"

          qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
          qiscus_sdk.post_system_event_message(system_event_type, id, @current_user.qiscus_email, [], group_chat_avatar)
          render json: {
            data: chat_room.as_json({:me => @current_user})
          } and return

        else
          raise StandardError.new("You are not member of this group.")
        end
      end

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
  # @api {post} /api/v1/chat/conversations/post_comment Post Comment
  # @apiDescription Send message to SDK through Qisme engine.
  # @apiName PostComment
  # @apiGroup Chat
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} topic_id Chat room id which will be post
  # @apiParam {String} comment Message comment to send
  # @apiParam {String} type Message type `text`, `buttons`, `card`, `carousel`, or `account_linking`
  # @apiParam {String} payload JSON string for payload, example: {
  #     "url": "http://google.com",
  #     "redirect_url": "http://google.com/redirect",
  #     "params": {
  #         "user_id": 1,
  #         "topic_id": 1,
  #         "button_text": "ini button",
  #         "view_title": "title"
  #     }
  # }. For more payload example, please refer to this documentation,
  # https://www.qiscus.com/documentation/rest/latest/comment#post-comment.
  # =end
  def post_comment
    comments = Array.new
    begin
      ActiveRecord::Base.transaction do
        qiscus_token = @current_user.qiscus_token
        application = @current_user.application

        topic_id = params[:topic_id]
        comment = params[:comment]
        type = params[:type]
        payload = params[:payload]

        if type.nil? || type == ""
          type = "text"
        end

        if payload.nil? || payload == ""
          payload = ""
        end

        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        comments = qiscus_sdk.post_comment(qiscus_token, topic_id, comment, type, payload)
      end

      render json: {
        data: comments
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

  # load comment by topic id
  def load_comments
    comments = Array.new
    begin
      ActiveRecord::Base.transaction do
        qiscus_token = @current_user.qiscus_token
        application = @current_user.application

        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        comments = qiscus_sdk.load_comments(qiscus_token, params[:topic_id])
      end

      render json: {
        data: comments
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
      }, status: 500 and return
    end
  end

  def get_room_by_id
    rooms = Array.new
    begin
      ActiveRecord::Base.transaction do
        qiscus_token = @current_user.qiscus_token
        application = @current_user.application

        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        rooms = qiscus_sdk.get_room_by_id(qiscus_token, params[:room_id])
      end

      render json: {
        data: rooms
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

  # Sync conversation
  # if return empty then there is no comment after given last comment id (no new comment)
  def sync
    comments = Array.new
    begin
      ActiveRecord::Base.transaction do
        qiscus_token = @current_user.qiscus_token
        application = @current_user.application

        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        comments = qiscus_sdk.sync(qiscus_token, params[:last_comment_id])
      end

      render json: {
        data: comments
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
  # @api {get} /api/v1/chat/conversations/filter Filter Conversation List
  # @apiName FilterChat
  # @apiGroup Chat
  #
  # @apiParam {String} access_token User access token
  # @apiParam {String} chat_room_type Chat room type : 'single' or 'group'
  # =end
  def filter
    begin
      if params[:chat_room_type].nil? || !params[:chat_room_type].present? || params[:chat_room_type] == ""
        raise StandardError.new("Please specify your chat_room_type.")
      else
        if params[:chat_room_type].downcase.delete(' ') != "single" && params[:chat_room_type].downcase.delete(' ') != "group"
          raise StandardError.new("Permitted chat_room_type is 'single' or 'group'.")
        end
      end
      #
      if params[:chat_room_type] == "single"
        is_group_chat = false
      elsif params[:chat_room_type] == "group"
        is_group_chat = true
      end

      # get current time, to measure calling time each process
      start_time_pluck_room_id = Time.now
      qiscus_room_ids = @current_user.chat_rooms.where(is_group_chat: is_group_chat).pluck(:qiscus_room_id)
      end_time_pluck_room_id = Time.now

      chat_room_sdk_info = []

      # if not empty qiscus room id, then call sdk to avoid error
      start_time_sdk = Time.now
      if qiscus_room_ids.empty? == false
        qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
        sdk_status, chat_room_sdk_info = qiscus_sdk.get_rooms_info(@current_user.qiscus_email, qiscus_room_ids)

        # throw an error
        if sdk_status != 200
          raise StandardError.new(chat_room_sdk_info['error']['detailed_messages'].to_a.join(", ").capitalize)
        end
      end
      end_time_sdk = Time.now

      page = 1
      per_page = 100

      start_chat_room_load = Time.now
      _, chat_rooms = ChatRoomHelper.load_for(@current_user, chat_room_sdk_info, page, per_page)
      end_chat_room_load = Time.now

      pluck_room_id_time = (end_time_pluck_room_id - start_time_pluck_room_id) * 1000
      sdk_call_time = (end_time_sdk - start_time_sdk) * 1000
      chat_room_load = (end_chat_room_load - start_chat_room_load) * 1000

      # filter chat_room
      filtered_chat_rooms = []
      qiscus_room_ids.each do |id|
        chat_rooms.each do |hash|
          filtered_chat_rooms << hash if hash["qiscus_room_id"] == id
        end
      end

      render json: {
        meta: {
          debug: {
            pluck_room_id: "#{pluck_room_id_time} ms",
            sdk_call: "#{sdk_call_time} ms",
            chat_room_load: "#{chat_room_load} ms",
            total_time: "#{pluck_room_id_time + sdk_call_time + chat_room_load} ms"
          }
        },
        data: filtered_chat_rooms
      } and return
    rescue => e
      render json: {
        error: {
          message: e.message,
          backtrace: e.backtrace
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/chat/conversations/join_room_with_unique_id Join room with unique id
  # @apiDescription Join room with unique id.
  # @apiName JoinRoomWithUniqueId
  # @apiGroup Chat
  #
  # @apiParam {String} access_token User access token.
  # @apiParam {Number} creator_user_id It's official user_id.
  # @apiParam {String} unique_id Unique_id is combination of app_id, creator (official) qiscus_email, app_id using # as separator. For example unique_id = "kiwari-prod#userid_001_62812345678987@kiwari-prod.com#kiwari-prod"
  # =end
  def join_room_with_unique_id
    begin
      chat_room = nil
      ActiveRecord::Base.transaction do
        application = @current_user.application
        qiscus_token = @current_user.qiscus_token

        creator_user_id = params[:creator_user_id]

        if !creator_user_id.present?
          raise StandardError.new("Creator user id must be present.")
        end

        unique_id = params[:unique_id]

        if !unique_id.present?
          raise StandardError.new("Unique id must be present.")
        end

        creator = User.find(creator_user_id)

        # Ensure that unique_id format is valid
        # Unique id is combination of app_id, creator (official) qiscus_email, app_id using # as separator. For example unique_id = "kiwari-prod#userid_001_62812345678987@kiwari-prod.com#kiwari-prod
        split_unique_id = unique_id.split("#")
        if split_unique_id[0] != application.app_id || split_unique_id[1] != creator.qiscus_email || split_unique_id[2] != application.app_id
          raise StandardError.new("Invalid unique id format.")
        end

        # Ensure that public chat room is exist
        chat_room = ChatRoom.find_by(user_id: creator.id, is_public_chat: true, application_id: application.id)
        if chat_room.nil?
          raise StandardError.new("Chat room is not exist.")
        end

        chat_name = creator.fullname
        chat_avatar_url = creator.avatar_url
        qiscus_room_id = chat_room.qiscus_room_id

        # Backend need to get chat room with unique id in SDK
        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        room = qiscus_sdk.get_or_create_room_with_unique_id(qiscus_token, unique_id, chat_name, chat_avatar_url)

        if !chat_room.qiscus_room_id == room.id
          raise StandardError.new("Chat room is not exist.")
        end

        # Ensure that chat_user is not exist
        chat_user = ChatUser.find_by(chat_room_id: chat_room.id, user_id: @current_user.id)

        if chat_user.nil?
          chat_user = ChatUser.new
          chat_user.chat_room_id = chat_room.id
          chat_user.user_id = @current_user.id
          chat_user.is_group_admin = false
          chat_user.save!

          # Backend need to post system event message after participant joined chat room
          # Post system event message with system_event_type = join_room
          system_event_type = "join_room"
          qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
          qiscus_sdk.post_system_event_message(system_event_type, qiscus_room_id, @current_user.qiscus_email, [], chat_name)

        end
      end

      chat_room = chat_room.as_json({:me => @current_user})

      # add group_admins payload in chat_room json
      chat_room.merge!('group_admins' => [@current_user.id])

      render json: {
        data: chat_room
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
  # @api {get} /api/v1/chat/conversations/rooms Get Conversation List
  # @apiName ChatList
  # @apiGroup Chat
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} [page=1] Pagination. Per page is 10 conversation.
  # =end
  def rooms
    begin
      page = params[:page]
      if !page.present? || page.to_i <= 0
        page = 1
      end

      per_page = 10

      # If params page not present then show all conversations
      if !params[:page].present? || params[:page].to_i <= 0
        per_page = 100
      end

      chat_room_sdk_info = []

      # if current_user have chat room in qisme database then call sdk
      start_time_sdk = Time.now
      if @current_user.chat_rooms.count > 0
        qiscus_sdk = QiscusSdk.new(@current_user.application.app_id, @current_user.application.qiscus_sdk_secret)
        sdk_status, chat_room_sdk_info = qiscus_sdk.get_user_rooms(@current_user.qiscus_email, page, per_page)
      end
      end_time_sdk = Time.now

      start_chat_room_load = Time.now
      chat_rooms_total, chat_rooms = ChatRoomHelper.load_for(@current_user, chat_room_sdk_info, page, per_page)
      end_chat_room_load = Time.now

      sdk_call_time = (end_time_sdk - start_time_sdk) * 1000
      chat_room_load = (end_chat_room_load - start_chat_room_load) * 1000

      # roundup total_page
      total_page = (chat_rooms_total/per_page.to_f).ceil

      render json: {
        meta: {
          total: chat_rooms_total,
          per_page: per_page,
          total_page: ((chat_rooms_total / per_page) <= 0) ? 1 : (total_page),
          current_page: (params[:page].to_i <= 0) ? 1 : params[:page].to_i,
          debug: {
            sdk_call: "#{sdk_call_time} ms",
            chat_room_load: "#{chat_room_load} ms",
            total_time: "#{sdk_call_time + chat_room_load} ms"
          }
        },
        data: chat_rooms
      } and return
    rescue => e
      render json: {
        error: {
          message: e.message,
          backtrace: e.backtrace
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/chat/conversations/post_system_event_message Post system event message
  # @apiDescription Post system event message type "custom"
  # @apiName PostSystemEventMessage
  # @apiGroup System Event Message
  #
  # @apiParam {String} access_token User access token
  # @apiParam {String} target_email It's using qiscus_email
  # @apiParam {String} message Message will be sent
  # @apiParam {String} payload Payload must be json object string
  # @apiParam {String} extras Extras must be json object string
  # =end
  def post_system_event_message
    begin
      target_email = params[:target_email]
      if target_email.nil? || target_email == ""
        raise StandardError.new("target_email cannot be empty.")
      end

      current_user = @current_user

      target_user = User.find_by(qiscus_email: target_email, application_id: current_user.application.id)
      if target_user.nil?
        raise StandardError.new("User is not found.")
      end

      message = params[:message]
      if message.nil? || message == ""
        raise StandardError.new("message cannot be empty.")
      end

      payload = params[:payload]
      if payload.nil? || payload == ""
        raise StandardError.new("payload cannot be empty.")
      end

      extras = params[:extras]

      # Looking for a single chat between current_user and target_user
      chat_room = ChatRoom.where(is_group_chat: false, user_id: [current_user.id, target_user.id], target_user_id: [current_user.id, target_user.id]).first

      qiscus_sdk = QiscusSdk.new(current_user.application.app_id, current_user.application.qiscus_sdk_secret)

      if chat_room.nil?
        # If single chat is nil then create single chat between current user and target user
        emails = [current_user.qiscus_email, target_user.qiscus_email]
        room = qiscus_sdk.get_or_create_room_with_target_rest(emails) # call sdk to create single room

        # Then get room_id from sdk
        qiscus_room_id = room.id

        # Insert data into qisme database
        chat_room = ChatRoom.find_by(qiscus_room_id: qiscus_room_id, application_id: current_user.application.id)

        # if chat room with room id and room topic id not exist then create it
        if chat_room.nil?
          chat_name = "Group Chat Name"

          chat_room = ChatRoom.new(
            group_chat_name: chat_name,
            qiscus_room_name: chat_name,
            qiscus_room_id: qiscus_room_id,
            is_group_chat: false,
            user_id: current_user.id,
            target_user_id: target_user.id,
            application_id: current_user.application.id
          )

          chat_room.save!

          ChatUser.create(chat_room_id: chat_room.id, user_id: current_user.id) unless ChatUser.exists?(chat_room_id: chat_room.id, user_id: current_user.id)
          ChatUser.create(chat_room_id: chat_room.id, user_id: target_user.id) unless ChatUser.exists?(chat_room_id: chat_room.id, user_id: target_user.id)

        else
          # if exist then return error with warning that qiscus room id has been inserted before
          # raise StandardError.new("Qiscus room id has been inserted before, it must be unique.")
        end
      else
        # If single chat already exist then get qiscus_room_id
        qiscus_room_id = chat_room.qiscus_room_id
      end

      type = "custom"
      room_id = chat_room.qiscus_room_id

      # post system event message for incoming call_event
			system_event_message = qiscus_sdk.post_system_event_message(type, room_id, "", [], "", payload, message, extras)

      render json: {
        data: system_event_message
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

  def ensure_raw_file
    @group_avatar = params[:group_avatar]

    render json: {
      status: 'fail',
      message: 'invalid avatar file'
    }, status: 422 unless @group_avatar
  end

end
