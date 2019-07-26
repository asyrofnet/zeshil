class QiscusAI

  QISCUS_AI_URL = 'http://telkomnews.bots.qiscus.com/v1/handler'
  QISCUS_AI_URL_STAGING = 'http://telkomnews-stag.bots.qiscus.com/v1/handler'
  QISCUS_AI_TELKOMNEWS_BOT_EMAIL = '123456789@qiscuswa.com'


  # send to qiscus AI specific in telkom news bot
  def self.telkom_news_bot(environment, sender_id, email_sdk, username, room_id, message)
    if environment == 'staging'
      url = QISCUS_AI_URL_STAGING
    else
      url = QISCUS_AI_URL
    end

    begin
      params = {
        "bot_id" => QISCUS_AI_TELKOMNEWS_BOT_EMAIL,
        "sender_id" => sender_id,
        "sender_email" => email_sdk,
        "sender_username" => username,
        "topic_id" => room_id,
        "message_type" => "text",
        "message_payload" => message
      }

      # build GET query parameter
      uri_string = url + "?" + params.map{|k,v| "#{k}=#{CGI::escape(v.to_s)}"}.join('&')

      uri = URI.parse(uri_string)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = (uri.scheme == "https")

      _headers = {}
      _headers['Content-Type'] = 'application/json'

      req = Net::HTTP::Get.new(uri.request_uri, _headers)
      res = https.request(req)

      Rails.logger.debug "GET #{uri_string} with params #{params}"

      if res.is_a?(Net::HTTPSuccess)
        Rails.logger.debug "Success while GET #{uri_string}, return #{res.body}"

        messages = ""

        # try to parse response
        res_hash = JSON.parse(res.body)
        res_hash["messages"].to_a.each do | message |
          if message["type"] == "text"
            messages = messages + " " + message["payload"] + "\n"
          end
        end

        # only return string, so it can send to SDK as a message directly
        return messages.strip()
      else # if not HTTP 200 success
        Rails.logger.debug "Error while GET #{uri_string}, return #{res.body}"
        if res.content_type == "application/json"
          res = JSON.parse(res.body)
          messages = "Error "

          if res["message"].is_a?(Hash)
            res["message"].each do |k, v|
              messages = messages + " " + k + ": " + v + "\n"
            end
          else
            messages = messages + "'" + res["message"].to_s + "' from Telkomnews Bot"
          end

          return messages
        else
          # if not application/json
          return res.body
        end
      end
    rescue => e
      # if error is not from response, then throw an exception
      raise StandardError.new(e.message)
    end

  end

  def self.telkom_news_bot_raw_json(environment, payload)
    if environment == 'staging'
      url = QISCUS_AI_URL_STAGING
    else
      url = QISCUS_AI_URL
    end

    begin
      uri = URI.parse(url)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = (uri.scheme == "https")

      _headers = {}
      _headers['Content-Type'] = 'application/json'

      req = Net::HTTP::Post.new(uri.request_uri, _headers)
      req.body = payload.to_json
      res = https.request(req)

      # Raven.capture_message("QiscusAI#telkom_news_bot_raw_json-info",
      #   extra: {
      #     "response" => "POST #{url} with params #{payload.to_json}"
      #   },
      # )

      # Raven.capture_message("QiscusAI#telkom_news_bot_raw_json-result",
      #   extra: {
      #     "response" => res.body
      #   },
      # )

      Rails.logger.debug "POST #{url} with params #{payload.to_json}"

      if res.is_a?(Net::HTTPSuccess)
        Rails.logger.debug "Success while POST #{url}, return #{res.body}"
        # try to parse response
        res_hash = JSON.parse(res.body)
        return res_hash
      else # if not HTTP 200 success
        Rails.logger.debug "Error while POST #{url}, return #{res.body}"
        if res.content_type == "application/json"
          res = JSON.parse(res.body)
          return res
        else
          # if not application/json
          return res.body
        end
      end
    rescue => e
      # if error is not from response, then throw an exception
      raise StandardError.new(e.message)
    end

  end

end
