require 'net/http'

class CallbackBotPostcommentWorker < ActiveJob::Base
  queue_as :bot_post_comment

  # do time consuming task here, such calling another service dll
  # all message passed in here is "post_comment"

  def perform(args)
    # can be send to sentry if needed
    args_in_hash = JSON.parse(args)

    # Raven.capture_message("CallbackBotPostcommentWorker#perform1",
    #   extra: {
    #     "response" => args_in_hash.inspect
    #   },
    # )

    Rails.logger.debug "#{self.class.name}: performing with arguments: #{args_in_hash.inspect}"

    response_message = CallbackBotPostcommentWorker.post_to_callback_url(args_in_hash['callback_url'], args_in_hash)

    # send response message from callback service to this room
    # app = Application.find(args_in_hash["application"]["id"])
    # my_account = User.find_by(qiscus_email: args_in_hash["my_account"]["qiscus_email"], application_id: app.id)

    # Raven.capture_message("CallbackBotPostcommentWorker#perform2",
    #   extra: {
    #     "response" => response_message
    #   },
    # )

    # qiscus_sdk = QiscusSdk.new(app.app_id, app.qiscus_sdk_secret)
    # qiscus_sdk.post_comment(my_account.qiscus_token, args_in_hash["chat_room"]["qiscus_room_id"], response_message)
  end

  def self.post_to_callback_url(url, params)
    begin
      uri = URI.parse(url)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = (uri.scheme == "https")

      _headers = {}
      _headers["Content-Type"] = 'application/json'

      uri_path = uri.path
      if uri_path == ""
        uri_path = "/"
      end

      req = Net::HTTP::Post.new(uri_path, _headers)
      # param is a Hash
      req.body = params.to_json
      
      res = https.request(req)

      # Raven.capture_message("CallbackBotPostcommentWorker#post_to_callback_url2",
      #   extra: {
      #     "params" => params.to_json,
      #     "url" => url,
      #     "response" => res
      #   },
      # )

      if res.is_a?(Net::HTTPSuccess)
        if res.content_type == "application/json"
          message = JSON.parse(res.body)

          return message.to_json
        else
          # if not json, then it 
          return res.body
        end
      else
        raise Exception.new("Error while calling callback at #{url} return HTTP status code #{res.code} (#{res.message}): #{res.body}")
      end
    rescue Exception => e
      raise Exception.new(e.message)
    end
  end

end