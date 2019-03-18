# For sending message to qiscus
class SendToQiscus

  QISCUS_APP_ID = "kiwari-prod"
  QISCUS_SDK_SECRET = "kiwari-prod-123"
  USER_QISCUS_TOKEN = "dmXZzfDusd09FA1n3JFw"

  # send message as Qisme Bot user
  def self.send_message(qiscus_room_id, message)
    begin
      qiscus_sdk = QiscusSdk.new(QISCUS_APP_ID, QISCUS_SDK_SECRET)
      qiscus_sdk.post_comment(USER_QISCUS_TOKEN, qiscus_room_id, message)

    rescue Exception => e
      Rails.logger.debug "Error while POST comment, #{e.message}"
      return false
    end

  end

end