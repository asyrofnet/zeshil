class MessagePushNotificationJob < ActiveJob::Base
  queue_as :push_notifications

  def perform(app_id, chat_room, from, participant, type, message)
    application = Application.find_by(app_id: app_id)

    # check chat_room is muted or not
    # push notification only send to unmuted chat room
    is_mute_chat = MuteChatRoom.find_by(user_id: participant.id, chat_room_id: chat_room["id"])

    if is_mute_chat.nil?
    	# get target user device token
      userdevicetokens = UserDeviceToken.where(user_id: participant.id)

      userdevicetokens.each do | u |
        room_avatar = ""
        sender = from.fullname
        message_text = message["text"]

        # handle if from fullname is nil
        if from.fullname.nil?
          sender = from.phone_number
        end

        # build up alert into hash
        if chat_room["is_group_chat"] == true # for group chat
          # handle if the last_comment_message is file attachment
          if message["text"].include?"[file]"
            message_text = "sent file attachment"
          end

          # handle if message type is card
          if message["type"] == "card"
            body = "#{sender} sent a card"
          else
            body = "#{sender}: #{message_text}"
          end

          # handle room_avatar
          if !chat_room["chat_avatar_url"].nil? or chat_room["chat_avatar_url"] != ""
            room_avatar = chat_room["chat_avatar_url"]
          end
        elsif chat_room["is_group_chat"] == false # for single chat
          # handle if the last_comment_message is file attachment
          if message["text"].include?"[file]"
            message_text = "Sent you file attachment"
          end

          # handle if message type is card
          if message["type"] == "card"
            body = "Sent you a card"
          else
            body = message_text
          end

          # handle room_avatar. room_avatar is interlocutors avatar
          if !participant.avatar_url.nil? or participant.avatar_url != ""
            room_avatar = participant.avatar_url
          end
        end

        alert = {
            title: chat_room["chat_name"],
            body: body
          }

        sound = "bells.wav"

        # build up custom_payload into hash
        custom_payload = {
          payload: {
            id:                   message["id"],
            type:                 type,
            message:              message["text"],
            payload:              message["payload"],
            comment_before_id:    message["comment_before_id"],
            unique_temp_id:       message["unique_temp_id"],
            disable_link_preview: message["disable_link_preview"],
            user_id:              from.id,
            email:                from.qiscus_email,
            username:             from.fullname,
            user_avatar:          from.avatar_url,
            chat_type:            chat_room["type"],
            room_id:              chat_room["qiscus_room_id"],
            topic_id:             chat_room["qiscus_room_id"],
            room_name:            chat_room["chat_name"],
            room_avatar:          room_avatar,
            is_group_chat:        chat_room["is_group_chat"],
            is_official_chat:     chat_room["is_official_chat"],
            title:                chat_room["chat_name"],
            target_user_id:       chat_room["target_user_id"],
            created_at:           message["timestamp"],
            pn_type:              'new_message'
          },
          sender:         from.qiscus_email,
          RecipientToken: u.devicetoken,
          Platform:       u.user_type,
          AppID:          app_id,
          RetryCount:     5
        }

        # send push notification to ios using apnotic
        if u.user_type == 'ios'
          SendApnsJob.perform_later(application, alert, u.devicetoken, custom_payload, sound)

          # send silent push notification
          # it's must remove alert, sound, badges, and content-available = 1
          custom_payload = {
            payload: {
              pn_type:	'new_silent_message'
            }
          }
          SendApnsJob.perform_later(application, alert, u.devicetoken, custom_payload)
        end
      end
    end
  end
end