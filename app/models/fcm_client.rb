require 'fcm'

class FcmClient

  def self.send(fcm_key, registration_ids, custom_payload)
    fcm = FCM.new(fcm_key)
    response = fcm.send(registration_ids, custom_payload)

    return response
  end

end