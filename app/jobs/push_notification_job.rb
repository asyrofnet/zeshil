class PushNotificationJob < ActiveJob::Base
  queue_as :push_notifications

  def perform(user_id, alert, ios_payload, sound, android_payload)
    user = User.find(user_id)
    application = user.application
    fcm_key = application.fcm_key

    userdevicetokens = user.user_device_tokens # get user device token

    registration_ids = Array.new

    userdevicetokens.each do | u |
      # send push notification to ios using apnotic
      if u.user_type == "ios"
        # ApnoticClient.send(alert, u.devicetoken, ios_payload, sound)
        SendApnsJob.perform_later(application, alert, u.devicetoken, ios_payload, sound)
      end

      # collect android devicetoken into array
      if u.user_type == "android"
        registration_ids.push(u.devicetoken)
      end
    end

    # send push notification to android using fcm
    FcmClient.send(fcm_key, registration_ids, android_payload)
  end
end