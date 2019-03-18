class ContactPushNotificationJob < ActiveJob::Base
  queue_as :push_notifications

  def perform(new_contacts)
    new_contacts.each do |c|
      from_user = User.find(c[0]) # get detail from_user
      to_user = User.find(c[1]) # get detail to_user
      application = from_user.application

      contact = Contact.find_by(user_id: c[0], contact_id: c[1])

      # find fcm_key that store in applications table
      fcm_key = from_user.application.fcm_key

      # avoid send push notification from/to official account
      if from_user.is_official == false and to_user.is_official == false
        # build up payload for ios push notification
        adder_user = from_user.fullname
        if adder_user.nil?
          adder_user = from_user.phone_number
        end
        alert = {
          title: "New Contact",
          body: "#{adder_user} added you as a friend."
        }

        sound = "bells.wav"

        ios_payload = {
          payload: {
            from_user:      from_user.as_json(job: true),
            sender:         from_user.qiscus_email,
            AppID:          from_user.application.app_id,
            pn_type:        'new_contact'
          }
        }

        # check is_contact or not for android payload
				contact_ids = to_user.contacts.pluck(:contact_id)
				is_contact = contact_ids.include?(from_user.id)

				# insert is_contact key and value to from_user
				from_user_json = from_user.as_json
				from_user_json["is_contact"] = is_contact

        # build up payload for android push notification
        android_payload = {
          data: {
            from_user:			      from_user_json,
            sound:                "default",
            title:                "New Contact",
            body:                 "#{adder_user} added you as a friend.",
            avatar_from_user:     from_user.avatar_url,
						pn_type:              "new_contact",
          }
        }

      	# get target user device token
        userdevicetokens = UserDeviceToken.where(user_id: to_user.id)

        registration_ids = Array.new

        userdevicetokens.each do | u |
          # send push notification to ios using apnotic
          if u.user_type == 'ios'
            # ApnoticClient.send(alert, u.devicetoken, custom_payload, sound)
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
  end
end
