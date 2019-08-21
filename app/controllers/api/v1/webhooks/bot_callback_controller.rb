require 'uri'

class Api::V1::Webhooks::BotCallbackController < ApplicationController
  SessionLength = 1.minute.to_i
  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/webhooks/bot-callback/:app_id General Callback
  # @apiSampleRequest off
  # @apiName BotCallbackController
  # @apiGroup Webhooks
  # @apiDescription Akan mengembalikan payload yang kemudian dikirim ke `callback_url`, kembalian dari callback url akan diproses/langsung dikirim sebagai post comment,
  # lihat kelas `CallbackBotPostcommentWorker`
  # @apiHeader {String} Content-Type Content type, must be `application/json`
  # @apiHeaderExample {json} Request-Example:
  # { "Content-Type": "application/json" }
  #
  # @apiParam {json} payload Callback message type, must be sent in request body
  #
  # @apiParamExample {json} Request-Example:
  #   {
  #     "type": "post_comment",
  #     "payload": {
  #         "from": {
  #             "id": 1,
  #             "email": "userid_14_6281328777777@qisme.com",
  #             "name": "User1"
  #         },
  #         "room": {
  #             "id": 536,
  #             "topic_id": 536,
  #             "type": "group",
  #             "name": "ini grup",
  #             "participants": [
  #                 {
  #                     "id": 1,
  #                     "email": "userid_14_6281328777777@qisme.com",
  #                     "username": "User1",
  #                     "avatar_url": "http://avatar1.jpg"
  #                 },
  #                 {
  #                     "id": 2,
  #                     "email": "userid_12_6281328123455@qisme.com",
  #                     "username": "User2",
  #                     "avatar_url": "http://avatar2.jpg"
  #                 }
  #             ]
  #         },
  #         "message": {
  #               "type": "text",
  #               "payload": {},
  #               "text": "isi pesan"
  #           }
  #      }
  # }
  # @apiParam {String} app_id Application id where this callback should be processed
  #
  # @apiSuccessExample {json} Success-Response:
  #     {"success":true,"data":[{"callback_url":"http://localhost:3000/api/v1/listeners/telkom_news_bot_production","token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxMiwidGltZXN0YW1wIjoiMjAxNy0wMy0yMSAxMTozNDo1NSArMDcwMCJ9.VKktM_aNHhLFk9OhB7FUsdagYlPE1e_FX5_Urf9cEb4","api_base_url":"http://localhost:3000","type":"post_comment","application":{"id":1,"app_id":"qisme","app_name":"Qisme Default Application","description":null,"qiscus_sdk_url":"http://dragonfly.qiscus.com","created_at":"2017-01-22T07:36:06.116Z","updated_at":"2017-01-24T04:35:33.627Z","qiscus_sdk_secret":"qisme-123"},"from":{"id":14,"phone_number":"+6281328777777","fullname":null,"email":null,"gender":null,"date_of_birth":null,"avatar_url":null,"is_public":false,"verification_attempts":0,"created_at":"2017-03-15T09:32:33.748Z","updated_at":"2017-03-16T03:38:33.975Z","qiscus_email":"userid_14_6281328777777@qisme.com","description":"","callback_url":"","is_admin":false,"is_official":false,"roles":[{"id":2,"name":"Member"}],"application":{"app_name":"Qisme Default Application"},"qiscus_id":1},"my_account":{"id":12,"phone_number":"+6281328123455","fullname":"Telkom News Bot","email":null,"gender":null,"date_of_birth":null,"avatar_url":null,"is_public":false,"verification_attempts":0,"created_at":"2017-03-15T04:46:12.981Z","updated_at":"2017-03-21T04:34:47.797Z","qiscus_email":"userid_12_6281328123455@qisme.com","description":"","callback_url":"http://localhost:3000/api/v1/listeners/telkom_news_bot_production","is_admin":false,"is_official":true,"roles":[{"id":2,"name":"Member"},{"id":3,"name":"Official Account"}],"application":{"app_name":"Qisme Default Application"}},"chat_room":{"id":9,"qiscus_room_name":"CHat name","qiscus_room_id":536,"is_group_chat":true,"created_at":"2017-03-15T05:30:47.931Z","updated_at":"2017-03-15T05:30:47.931Z","application_id":1,"group_avatar_url":"http://res.cloudinary.com/qiscus/image/upload/v1485166071/group_avatar_qisme_user_id_4/komqez5xtyjwsjrbaz7z.png","is_official_chat":true,"users":[{"id":12,"phone_number":"+6281328123455","fullname":"Telkom News Bot","email":null,"gender":null,"date_of_birth":null,"avatar_url":null,"is_public":false,"verification_attempts":0,"created_at":"2017-03-15T04:46:12.981Z","updated_at":"2017-03-21T04:34:47.797Z","qiscus_email":"userid_12_6281328123455@qisme.com","description":"","callback_url":"http://localhost:3000/api/v1/listeners/telkom_news_bot_production","is_admin":false,"is_official":true,"roles":[{"id":2,"name":"Member"},{"id":3,"name":"Official Account"}],"application":{"app_name":"Qisme Default Application"},"qiscus_id":2},{"id":11,"phone_number":"+6281328123456","fullname":"Yusuf","email":null,"gender":null,"date_of_birth":null,"avatar_url":null,"is_public":false,"verification_attempts":1,"created_at":"2017-03-15T04:45:36.367Z","updated_at":"2017-03-15T04:45:47.539Z","qiscus_email":"userid_11_6281328123456@qisme.com","description":"","callback_url":"","is_admin":false,"is_official":false,"roles":[{"id":2,"name":"Member"}],"application":{"app_name":"Qisme Default Application"}},{"id":13,"phone_number":"+6281328123459","fullname":"Helpdesk","email":null,"gender":null,"date_of_birth":null,"avatar_url":null,"is_public":false,"verification_attempts":1,"created_at":"2017-03-15T05:47:41.093Z","updated_at":"2017-03-15T05:49:05.981Z","qiscus_email":"userid_13_6281328123459@qisme.com","description":"","callback_url":"","is_admin":false,"is_official":false,"roles":[{"id":2,"name":"Member"},{"id":5,"name":"Helpdesk"}],"application":{"app_name":"Qisme Default Application"}}],"creator":{"id":11,"phone_number":"+6281328123456","fullname":"Yusuf","email":null,"gender":null,"date_of_birth":null,"avatar_url":null,"is_public":false,"verification_attempts":1,"created_at":"2017-03-15T04:45:36.367Z","updated_at":"2017-03-15T04:45:47.539Z","qiscus_email":"userid_11_6281328123456@qisme.com","description":"","callback_url":"","is_admin":false,"is_official":false,"roles":[{"id":2,"name":"Member"}],"application":{"app_name":"Qisme Default Application"}},"chat_name":"CHat name","chat_avatar_url":"http://res.cloudinary.com/qiscus/image/upload/v1485166071/group_avatar_qisme_user_id_4/komqez5xtyjwsjrbaz7z.png"},"message":{"payload":"JSON string payload","text":"message content","type":"menu or post comment or something"}}]}
  # =end
  def create
    begin
      # from payload
      type = params[:type]
      user = params[:payload][:from]
      room = params[:payload][:room]
      room_participants = room[:participants]
      message = params[:payload][:message]
      room_type = room[:type]

      # first, match all data from SDK using qisme database,
      # this ensure the data still relevant in qisme
      app = Application.find_by(app_id: params[:app_id])
      if app.nil?
        raise InputError.new("Application id #{params[:app_id]} is not found.")
      end

      from = User.find_by(qiscus_email: user[:email], application_id: app.id)

      participant_emails = Array.new
      participant_email_id_pair = Array.new
      room_participants.to_a.each do | participant |
        participant_emails.push(participant[:email])
      end

      participants = User.where("LOWER(qiscus_email) IN (?)", participant_emails).where(application_id: app.id)

      
      chat_room = ChatRoom.find_by(qiscus_room_id: room[:id], application_id: app.id)

      # if required payload is not present, then return error
      if from.nil?
        raise InputError.new("Sender is not found in database.")
      end

      if participants.empty?
        raise InputError.new("Participant is empty.")
      end

      if chat_room.nil?
        target = participants.where.not(id: from.id).first
        if target.nil?
          raise InputError.new("Target participant is not found in database.")
        end
        chat_name = "Group Chat Name"

        is_group_chat = !(room_type == "single".downcase)
        chat_room = ChatRoom.new(
            group_chat_name: chat_name,
            qiscus_room_name: chat_name,
            qiscus_room_id: room[:id],
            is_group_chat: is_group_chat,
            user_id: from.id,
            target_user_id: target.id,
            application_id: from.application.id
          )
          redis_key = "callback"+room[:id].to_s+"application="+app.id.to_s

          if !$redis.get(redis_key).present?
            $redis.set(redis_key, true)
            $redis.expire(redis_key, SessionLength)
            chat_room.save!
            participants.each do |roompeople|
              ChatUser.create(chat_room_id: chat_room.id, user_id: roompeople.id) unless ChatUser.exists?(chat_room_id: chat_room.id, user_id: roompeople.id)
            end
          else
            chat_room = ChatRoom.find_by(qiscus_room_id: room[:id], application_id: app.id)
            if !chat_room.present?
              raise InputError.new("Duplicate request")
            end
          end

      end

      chat_room = chat_room.as_json(:webhook => true) # convert to hash to merge more property/field such as qiscus_id
      chat_room['users'].map do |user|
        # include qiscus user id for sending to bot
        match_participant = room_participants.find {|x| x['email'] == user['qiscus_email'] }
        if !match_participant.nil?
          user.merge!('qiscus_id' => match_participant['id'])
        end
      end

      # Later it will be use for Worker to process in background.
      # This ensure that response of the request below 30 seconds -> avoid 30 seconds timeout limit in Heroku

      # if post comment, then pass to worker, and sender is not from telkom news bot
      # otherwise just leave it as is it
      payloads = Array.new
      
      if type.start_with? "post_comment" # handle if type is "post_comment_mobile" and "post_comment_rest"
        participants.each do | participant |
          # only send callback webhook to all participant who is official account
          # AND the participant is not a sender
          # for example: in Telegram group chat there are 2 BOT ACCOUNT (let say A and B) and 3 ORDINARY USER (let say user 1, 2 and 3)
          # when user 1, 2 or 3 send message to the chat room, both of bot account A and B receive a callback and send a response message to this chat room
          # but when bot A reply, only bot B will receive the callback -> this prevent bot A processing their own message from message they sent
          # so, it wise to using different keyword each bot, for example keyword /startgame or /join in Werewolf game bot in Telegram

          valid_callback_url = participant.callback_url =~ URI::regexp

          # send callback to user except sender (from) and if callback url is valid
          # in previous logic it checks whether participant is official or not (participant.is_official && ...)
          # but in latest requirement, all user can have its own callback (to accomodate bot account but not official)
          if participant.qiscus_email != from.qiscus_email && valid_callback_url
            # build up the payload into hash
            payload = {
              callback_url: participant.callback_url,
              token: ApplicationHelper.create_jwt_token(participant.id), # access token for accessing qisme application
              api_base_url: request.base_url,
              type: type,
              # application: app.as_json,
              from: from.as_json(:webhook => true).merge!('qiscus_id' => user[:id]), # add qiscus sdk id for bot
              my_account: participant.as_json(:webhook => true),
              # participants: participants.as_json, # participant in database only, no need to send since it already exist in chat_room.users
              chat_room: chat_room,
              message: {
                payload: message["payload"],
                text: message["text"],
                type: message["type"]
              }
            }

            # send to worker to avoid 30 seconds timeout limit
            CallbackBotPostcommentWorker.perform_later(payload.to_json)
            payloads.push(payload)
          end

          # Read send message pn confugration
          # It's mean only send message pn when this configuration is enabled
          if app.is_send_message_pn == true
            # get user device token
            userdevicetokens = UserDeviceToken.where(user_id: participant.id)
            # for now push notificaton only handle if user_type 'ios'
            userdevicetokens = userdevicetokens.where(user_type: 'ios')

            # send push notification to user expept sender (from) and user must have devicetoken
            if participant.qiscus_email != from.qiscus_email and !userdevicetokens.empty?
              participant = User.find(participant.id)
              chat_room = ChatRoom.find_by(qiscus_room_id: room[:id], application_id: app.id)
              chat_room = chat_room.as_json({:webhook => true, :me => participant})

              # remove created_at and updated_at (chat_room and userdevicetoken) payload because rails job not supported argument time
              chat_room.delete("created_at")
              chat_room.delete("updated_at")

              userdevicetokens.delete("created_at")
              userdevicetokens.delete("updated_at")

              message = message.as_json
              app_id = params[:app_id]

              MessagePushNotificationJob.perform_later(app_id, chat_room, from, participant, type, message)
            end
          end
        end
      end

      render json: {
        success: true,
        data: payloads
      }
    rescue ActiveRecord::RecordNotUnique => e
      render json: {
        error: {
          message: e.message,
          payload: params,
          trace: e.backtrace,
          class: InputError.name
        }
    }, status: 422 and return
    rescue => e
      render json: {
        error: {
          message: e.message,
          payload: params,
          trace: e.backtrace,
          class: e.class.name
        }
      }, status: 422 and return
    end
  end

end