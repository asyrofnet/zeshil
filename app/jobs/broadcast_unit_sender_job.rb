class BroadcastUnitSenderJob < ActiveJob::Base
    queue_as :broadcast_unit
    
    def perform(sender_user, target_user, message,type,payload, broadcast_message_id)
      application = sender_user.application
      is_sent = false
      retry_counter = 0
      qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
      extras = {"is_broadcast": true}.to_json

      qiscus_room_id = get_qiscus_room_id(sender_user,target_user)
      comment = nil
      while ( (is_sent == false) && (retry_counter < 5) && qiscus_room_id.present? ) do
        
        begin
          comment = qiscus_sdk.post_comment( sender_user.qiscus_token, qiscus_room_id, message,type,payload)
        rescue Exception => e
        end
        is_sent = true if comment.present?
        retry_counter += 1
      end
    end
      

  
    private
      def get_qiscus_room_id(sender_user,target_user)
        application = sender_user.application
        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        qiscus_room_id = nil
        sender_single = sender_user.chat_rooms.where(is_group_chat:false).pluck(:qiscus_room_id)
        target_single = target_user.chat_rooms.where(is_group_chat:false).pluck(:qiscus_room_id)
        common_single = target_single & sender_single
        if common_single.empty?
          emails = [sender_user.qiscus_email, target_user.qiscus_email]
          room = qiscus_sdk.get_or_create_room_with_target_rest(emails)


          chat_name = sender_user.fullname+" and "+target_user.fullname
          
          chat_room = ChatRoom.new(
            application_id: application.id,
            group_chat_name: chat_name,
            qiscus_room_name: room.name,
            qiscus_room_id: room.id,
            is_group_chat: room.is_group_chat,
            user_id: sender_user.id,
            target_user_id: target_user.id
          )

          chat_room.save!

          ChatUser.create([
            {chat_room_id: chat_room.id, user_id: sender_user.id},
            {chat_room_id: chat_room.id, user_id: target_user.id}
          ])
          qiscus_room_id = chat_room.qiscus_room_id
        else 
          qiscus_room_id = common_single.last    
        end
        return qiscus_room_id
      end

      def send_broadcast_to_sdk(application, sender_user_email, target_user_emails, message,type,payload)
        type = type
        payload = payload
        
        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        comments = qiscus_sdk.broadcast_v21(sender_user_email, target_user_emails, message, type, payload, extras.to_json)
        
        qiscus_room_ids = Array.new
        comments.each do |comment|
          qiscus_room_ids.push(comment["room_id"])
        end
  
        return comments, qiscus_room_ids
      end
  
      def create_single_chat_rooms(application, sender_user, comments, qiscus_room_ids, broadcast_message_id)
        chat_name = "Group Chat Name" # default room name
        i = 0
  
        qiscus_room_ids.each do |id|
          chat_room = ChatRoom.find_by(qiscus_room_id: id, application_id: application.id)
  
          participant_emails = comments[i]["participant_emails"]
          participant_emails.delete(sender_user.qiscus_email)
          target_user = User.find_by(qiscus_email: participant_emails[0])
  
          if chat_room.nil?
            chat_room = ChatRoom.new(
              group_chat_name: chat_name,
              qiscus_room_name: chat_name,
              qiscus_room_id: id,
              is_group_chat: false,
              user_id: sender_user.id,
              target_user_id: target_user.id,
              application_id: application.id
            )
  
            chat_room.save
  
            ChatUser.create(chat_room_id: chat_room.id, user_id: sender_user.id) unless ChatUser.exists?(chat_room_id: chat_room.id, user_id: sender_user.id)
            ChatUser.create(chat_room_id: chat_room.id, user_id: target_user.id) unless ChatUser.exists?(chat_room_id: chat_room.id, user_id: target_user.id)
          end
  
         
  
          i = i + 1
        end
  
      end
  end