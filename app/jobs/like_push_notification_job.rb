class LikePushNotificationJob < ActiveJob::Base
  queue_as :push_notifications

  def perform(post_id, post_owner_id, post_liker_id, show_media_list_as)
    post = Post.find(post_id)
    post_owner = User.find(post_owner_id)
    post_liker = User.find(post_liker_id)
    application = post_owner.application

    post_liker_name = post_liker.fullname
    if post_liker_name.nil?
      post_liker_name = post_liker.phone_number
    end

    # find fcm_key that store in applications table
    fcm_key = post_owner.application.fcm_key

    # alert is used for ios pop up
    alert = {
      title: "New Like",
      body: "#{post_liker_name} like your post."
    }

    sound = "bells.wav"

    if show_media_list_as == "array"
      post_android = post.as_post_list_json
      post_ios = post.as_post_list_json(job: true)
    else
      post_android = post.as_json
      post_ios = post.as_json(job: true)
    end

    # payload for android
    android_payload = {
      data: {
        title:          "New Like",
        body:           "#{post_liker_name} like your post.",
        post:           post_android,
        post_liker:     post_liker.as_json,
        pn_type:        "timeline_like_post"
      }
    }

    # payload for ios
    ios_payload = {
      payload: {
        title:          "New Like",
        body:           "#{post_liker_name} like your post.",
        post:           post_ios,
        post_liker:     post_liker.as_json(job: true),
        pn_type:        "timeline_like_post"
      }
    }

    userdevicetokens = post_owner.user_device_tokens # get user device token

    registration_ids = Array.new

    userdevicetokens.each do | u |
      # send push notification to ios using apnotic
      if u.user_type == "ios"
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