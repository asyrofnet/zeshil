class BroadcastMessageJob < ActiveJob::Base
  queue_as :default

  def perform(sender_user_id, target_user_ids, message, broadcast_message_id)
    sender_user = User.find(sender_user_id)
    application = sender_user.application

    target_users = User.where("id IN (?)", target_user_ids).where(application_id: application.id)
    target_user_emails = target_users.pluck(:qiscus_email)

    # Call Qiscus SDK for sending broadcast
    comments, qiscus_room_ids = send_broadcast_to_sdk(application, sender_user.qiscus_email, target_user_emails, message)

    # Create single chat room
    create_single_chat_rooms(application, sender_user, comments, qiscus_room_ids, broadcast_message_id)
  end

  private
    def send_broadcast_to_sdk(application, sender_user_email, target_user_emails, message)
      type = "text" # set comment type to text
      payload = nil
      extras = {"is_broadcast": true}
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
      new_broadcast_receipt_histories = Array.new
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

        # save broadcast receipt histories
        new_broadcast_receipt_histories.push(
          {
            :chat_room_id => chat_room.id,
            :user_id => target_user.id,
            :broadcast_message_id => broadcast_message_id,
            :sent_at => Time.now,
          }
        )

        i = i + 1
      end

      BroadcastReceiptHistory.create(new_broadcast_receipt_histories)
    end
end