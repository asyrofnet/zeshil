class Api::V1::PushNotificationsController < ProtectedController
  before_action :authorize_user

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/push_notifications Send push notifications
  # @apiDescription Send push notification to spesific user
  # @apiName PushNotification
  # @apiGroup PushNotification
  #
  # @apiHeader {String} Content-Type Content type, must be `application/json`
  # @apiHeaderExample {json} Request-Example:
  # { "Content-Type": "application/json" }
  #
  # @apiParamExample {JSON} Request-Example:
  #   {
  #     "access_token": "jwt_key",
  #     "user_id": 100,
  #     "pn_payload": {
  #         "title": "New Message",
  #         "body": "You have a new message.",
  #         "payload": {
  #               "key": "value",
  #           }
  #      }
  # }
  # @apiParam {String} access_token User access token
  # @apiParam {Number} user_id Target user id
  # @apiParam {Json} pn_payload Payload to send to target user
  # =end
  def create
    begin
      user_id = params[:user_id]
      if user_id.nil? || user_id == ""
        raise InputError.new("user_id cannot be empty.")
      end

      pn_payload = params[:pn_payload]
      if pn_payload.nil? || pn_payload == ""
        raise InputError.new("payload cannot be empty.")
      end

      # ensure title is exist
      if pn_payload["title"].nil? || pn_payload["title"] == ""
        raise InputError.new("title cannot be empty.")
      end

      # ensure body is exist
      if pn_payload["body"].nil? || pn_payload["body"] == ""
        raise InputError.new("body cannot be empty.")
      end

      # alert is used for ios pop up
      alert = {
        title: pn_payload["title"],
        body: pn_payload["body"]
      }

      # payload for ios
      ios_payload = {
        payload: pn_payload["payload"].as_json
      }

      sound = "bells.wav"

      # payload for android
      android_payload = {
        data: {
          title: pn_payload["title"],
          body: pn_payload["body"],
          payload: pn_payload["payload"].as_json
        }
      }

      # send push notification using PushNotificationJob
      PushNotificationJob.perform_later(user_id, alert, ios_payload, sound,  android_payload)

      render json: {
        data: {
          ios_payload: ios_payload,
          android_payload: android_payload
        }
      }
    rescue ActiveRecord::RecordInvalid => e
      msg = ""
      e.record.errors.map do |k, v|
        key = k.to_s.humanize
        msg = msg + "#{key} #{v}, "
      end

      msg = msg.chomp(", ") + "."
      render json: {
        error: {
          message: msg
        }
      }, status: 422 and return

    rescue => e
      render json: {
        error: {
          message: e.message,
          class: e.class.name
        }
      }, status: 422 and return
    end
  end

end