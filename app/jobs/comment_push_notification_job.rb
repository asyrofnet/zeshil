class CommentPushNotificationJob < ActiveJob::Base
  queue_as :push_notifications

  def perform(post_id, post_commenter_id, user_ids, show_media_list_as)
    post = Post.find(post_id)
    post_commenter = User.find(post_commenter_id)
    application = post_commenter.application

    post_commenter_name = post_commenter.fullname
    if post_commenter_name.nil?
      post_commenter_name = post_commenter.phone_number
    end

    # find fcm_key that store in applications table
    fcm_key = post_commenter.application.fcm_key

    # alert is used for ios pop up
    alert = {
      title: "New Comment",
      body: "#{post_commenter_name} commented in a post."
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
        title:              "New Comment",
        body:               "#{post_commenter_name} commented in a post.",
        post:               post_android,
        post_commenter:     post_commenter.as_json,
        pn_type:            "timeline_comment_post"
      }
    }

    # payload for ios
    ios_payload = {
      payload: {
        title:              "New Comment",
        body:               "#{post_commenter_name} commented in a post.",
        post:               post_ios,
        post_commenter:     post_commenter.as_json(job: true),
        pn_type:            "timeline_comment_post"
      }
    }

    registration_ids = Array.new

    user_ids.each do |id|
      user = User.find(id)
      userdevicetokens = user.user_device_tokens # get user device token

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
    end

    # send push notification to android using fcm
    FcmClient.send(fcm_key, registration_ids, android_payload)
  end
end