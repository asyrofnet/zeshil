class BroadcastMessageJobV2 < ActiveJob::Base
    queue_as :broadcast_starter
  
    def perform(sender, target_user_emails, message,type,payload, broadcast_message_id)
      application = sender.application
      i = 0
      target_user_emails.each do |target_email|
        sleep(1.0/30.0)
        target_user = User.find_by(qiscus_email: target_email)
        if !target_user.nil?
          begin
            if BroadcastReceiptHistory.where(user:target_user,broadcast_message_id:broadcast_message_id).where.not(sent_at:nil).empty?
              broadcastUnitSender(sender, target_user, message, type, payload, broadcast_message_id, application, target_user.phone_number)
              i += 1
            end
          rescue
          end
        end
      end
    end
  
    private
      def broadcastUnitSender(sender_user, target_user, message, type, payload, broadcast_message_id, application, phone_number)
        is_sent = false
        retry_counter = 0
        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        extras = {"is_broadcast": true}.to_json   
        qiscus_room_id = get_qiscus_room_id(sender_user,target_user)
        comment = nil
        
        if (qiscus_room_id.present?)
          begin
            comment = qiscus_sdk.post_comment(sender_user.qiscus_token, qiscus_room_id, message, type, payload)
          rescue => e
          end
          is_sent = true if comment.present?
          sent_at = nil
          if is_sent == true
            sent_at = Time.now
          end
          BroadcastReceiptHistory.create_history(target_user.id, broadcast_message_id, sent_at, phone_number)
          retry_counter += 1
        end  
      end

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
          chat_name = sender_user.fullname.to_s+" and "+target_user.fullname.to_s
          chat_room = ChatRoom.find_or_initialize_by(application_id: application.id, qiscus_room_id: room.id)
          chat_room.update!(
            group_chat_name: chat_name,
            qiscus_room_name: room.name,
            is_group_chat: room.is_group_chat,
            user_id: sender_user.id,
            target_user_id: target_user.id
          )

          ChatUser.find_or_create_by(chat_room_id: chat_room.id, user_id: sender_user.id )
          ChatUser.find_or_create_by( chat_room_id: chat_room.id, user_id: target_user.id )
          qiscus_room_id = chat_room.qiscus_room_id
        else 
          qiscus_room_id = common_single.last    
        end
        return qiscus_room_id
      end
  end