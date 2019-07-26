class DeleteEmptyChatroomJob < ActiveJob::Base
  queue_as :default

  def perform()
    users = User.all.pluck(:id)

    users.each do |uid|

      ActiveRecord::Base.transaction do
        qiscus_room_ids = ChatRoom.where(user_id: uid).pluck(:qiscus_room_id)
        user = User.find(uid)
        
        if !qiscus_room_ids.empty?
          begin
            qiscus_sdk = QiscusSdk.new(user.application.app_id, user.application.qiscus_sdk_secret)
            sdk_status, chat_room_sdk_info = qiscus_sdk.get_rooms_info(user.qiscus_email, qiscus_room_ids)

            if sdk_status == 200
              qiscus_room_ids.each do |qri|
                last_comment_message = chat_room_sdk_info[qri].last_comment_message
                if last_comment_message == "" || last_comment_message.nil?

                  puts "Deleting qiscus room id: #{qri}"
                  # delete all room in qisme if last comment is empty
                  ChatRoom.where(qiscus_room_id: qri).destroy_all
                end
              end
            end
          rescue => e
            puts "Error processing qiscus_room_ids: #{qiscus_room_ids} (#{e.message})"
          end

        end
      end
    end

  end

end