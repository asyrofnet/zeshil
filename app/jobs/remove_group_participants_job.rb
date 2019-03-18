class RemoveGroupParticipantsJob < ActiveJob::Base
  queue_as :default

  def perform(application_id, qiscus_room_ids, user_ids)
    ActiveRecord::Base.transaction do
      application = Application.find(application_id)

      # call SDK to remove participants
      qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)

      # remove participants in qiscus sdk
      i = 0
      qiscus_room_ids.each do |qiscus_room_id|
        chat_room_participant_ids = user_ids[i]
        chat_room_participants = User.where("id IN (?)", chat_room_participant_ids)
        deleted_participant_emails = chat_room_participants.pluck(:qiscus_email)

        if deleted_participant_emails.count > 0
          qiscus_sdk.remove_room_participants(deleted_participant_emails, qiscus_room_id.to_i)
        end

        i = i + 1
      end


    end
  end
end