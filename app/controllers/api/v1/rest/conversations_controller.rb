require 'jwt'

class Api::V1::Rest::ConversationsController < ApplicationController

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/rest/conversations/create_room_with_unique_id Create room with unique id
  # @apiDescription Create room with unique id. It's for buddygo support. This room called public chat room
  # @apiName CreateRoomWithUniqueId
  # @apiGroup Rest API
  #
  # @apiParam {String} server_key Valid server key
  # @apiParam {String} user_id Valid user_id to be create room with unique id
  # =end
  def create_room_with_unique_id
    begin
      chat_room = nil
      application = nil
      ActiveRecord::Base.transaction do
        # find application using server_key
        application = Application.find_by(server_key: params[:server_key])

        if application.nil?
          render json: {
            error: {
              message: "Invalid Server Key."
            }
          }, status: 404 and return
        end

        user_id = params[:user_id]
        if user_id.nil? || user_id == ""
          raise Exception.new('User id is empty.')
        end

        user = User.find_by(id: user_id, application_id: application.id)
        qiscus_token = user.qiscus_token

        # Genereate unique_id
        # Unique id is combination of app_id, creator (official) qiscus_email, app_id using # as separator. For example unique_id = "kiwari-prod#userid_001_62812345678987@kiwari-prod.com#kiwari-prod
        unique_id = "#{application.app_id}##{user.qiscus_email}##{application.app_id}"

        # Ensure that public chat room is not exist
        chat_room = ChatRoom.find_by(user_id: user.id, is_public_chat: true, application_id: application.id)
        if !chat_room.nil?
          raise Exception.new('Public chat room already exist.')
        end

        chat_name = user.fullname
        chat_avatar_url = user.avatar_url

        # Backend need to create chat room with unique id in SDK
        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        room = qiscus_sdk.get_or_create_room_with_unique_id(qiscus_token, unique_id, chat_name, chat_avatar_url)

        qiscus_room_id = room.id

        chat_room = ChatRoom.find_by(qiscus_room_id: qiscus_room_id, application_id: application.id)

        if chat_room.nil?
          chat_room = ChatRoom.new(
            group_chat_name: chat_name,
            qiscus_room_name: chat_name,
            qiscus_room_id: qiscus_room_id,
            is_group_chat: true,
            user_id: user.id,
            target_user_id: user.id,
            application_id: user.application.id,
            group_avatar_url: chat_avatar_url,
            is_official_chat: false,
            is_public_chat: true
          )

          chat_room.save!

          chat_user = ChatUser.new
          chat_user.chat_room_id = chat_room.id
          chat_user.user_id = user.id
          chat_user.is_group_admin = true # group creator assign as group admin
          chat_user.save!

          # Backend need to post system event message after room created
          # Post system event message with system_event_type = create_room
          system_event_type = "create_room"
          qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
          qiscus_sdk.post_system_event_message(system_event_type, qiscus_room_id, user.qiscus_email, [], chat_name)
        end
      end


      render json: {
        data: chat_room
      } and return

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
  # @api {post} /api/v1/rest/conversations/create_or_join_room_with_unique_id Create or join room with unique id
  # @apiDescription If room with predefined unique id is not exist then it will create a new one.
  # Otherwise, if room with predefined unique id is already exist, it will return that room and add user_id as a participant.
  # Room created using unique_id will have flag is_public_chat = true.
  # @apiName CreateOrJoinRoomWithUniqueId
  # @apiGroup Rest API
  #
  # @apiParam {String} app_id Application id, 'qisme', 'kiwari-stag', etc
  # @apiParam {String} server_key Application server key
  # @apiParam {Array} user_id[] Array of user id in Qisme database
  # @apiParam {String} unique_id Unique id. You can define unique_id by yourself
  # @apiParam {String} [chat_name="Group Chat Name"] Group chat name
  # @apiParam {String} [group_avatar_url=https://d1edrlpyc25xu0.cloudfront.net/kiwari-prod/image/upload/1yahAVOqLy/1510804279-default_group_avatar.png] URL of picture for group avatar
  # =end
  def create_or_join_room_with_unique_id
    begin
      chat_room = nil
      ActiveRecord::Base.transaction do
        # app_id
        app_id = params[:app_id]
        if app_id.nil? || app_id == ""
          raise Exception.new("App_id can't be empty.")
        end

        # server_key
        server_key = params[:server_key]
        if server_key.nil? || server_key == ""
          raise Exception.new("Server key can't be empty.")
        end

        # find application using app_id and server_key
        application = Application.find_by(app_id: app_id, server_key: server_key)

        if application.nil?
          render json: {
            error: {
              message: "Application id not found or invalid server key."
            }
          }, status: 404 and return
        end

        user_ids = params[:user_id]

        if !user_ids.is_a?(Array)
          raise Exception.new("User id must be an array of user id.")
        end

        # need to convert array of user_id (string) into integer
        user_ids = user_ids.collect{|i| i.to_i}

        unique_id = params[:unique_id]
        if unique_id.nil? || unique_id == ""
          raise Exception.new("Unique id can't be empty.")
        end

        chat_name = ""
        if !params[:chat_name].nil? && params[:chat_name] != ""
          chat_name = params[:chat_name]
        else
          chat_name = "Group Chat Name"
        end

        # default group avatar
        group_avatar_url = "https://d1edrlpyc25xu0.cloudfront.net/kiwari-prod/image/upload/1yahAVOqLy/1510804279-default_group_avatar.png"
        if params[:group_avatar_url].present? && !params[:group_avatar_url].nil? && params[:group_avatar_url] != ""
          group_avatar_url = params[:group_avatar_url]
        end

        # Execute create or join room using background job
        CreateOrJoinRoomWithUniqueIdJob.perform_later(application.id, user_ids, chat_name, group_avatar_url, unique_id)
      end

      render json: {
        data: {
          message: "Create or join room with target unique id is on progress."
        }
      } and return

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
  # @api {post} /api/v1/rest/conversations/post_system_event_message Post system event message
  # @apiDescription Post system event message without using access_token. This event message type is custom.
  # @apiName PostSystemEventMessage
  # @apiGroup Rest API
  #
	# @apiParam {String} server_key Valid server key
	# @apiParam {String} qiscus_room_id Valid qiscus room id
	# @apiParam {String} message Message will be sent
	# @apiParam {String} payload JSON string for payload, example: { "url": "http://google.com", "redirect_url": "http://google.com/redirect", "params": { "user_id": 1, "topic_id": 1, "button_text": "ini button", "view_title": "title" } }
	# @apiParam {String} [extras] Optional JSON string
  # =end
	def post_system_event_message
		begin
			system_event_message = nil
			ActiveRecord::Base.transaction do
				# server_key
        server_key = params[:server_key]
        if server_key.nil? || server_key == ""
          raise Exception.new("Server key can't be empty.")
        end

        # find application using server_key
        application = Application.find_by(server_key: server_key)

        if application.nil?
          render json: {
            error: {
              message: "Invalid server key."
            }
          }, status: 404 and return
        end

				qiscus_room_id = params[:qiscus_room_id]
				if qiscus_room_id.nil? || qiscus_room_id == ""
					raise Exception.new("qiscus_room_id cannot be empty.")
				end

				message = params[:message]
				if message.nil? || message == ""
					raise Exception.new("message cannot be empty.")
				end

				payload = params[:payload]
				if payload.nil? || payload == ""
					raise Exception.new("payload cannot be empty.")
				end

				extras = params[:extras]

				# looking for room with qiscus_room_id in qisme
				chat_room = ChatRoom.find_by(qiscus_room_id: qiscus_room_id)
				if chat_room.nil?
					raise Exception.new("chat_room not found")
				end

				type = "custom"

				qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)

				# post system event message
				system_event_message = qiscus_sdk.post_system_event_message(type, chat_room.qiscus_room_id, "", [], "", payload, message, extras)
			end

			render json: {
        data: system_event_message
      } and return

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

end
