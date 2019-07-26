# This is call back controller, 
# YOU SHOULD NOT do any active record query from this controller since this act like third party service
# may be you want to separate this controller into different application written in Node or another language
# so you cannot query anything since you cannot perform database connection to qisme engine 

class Api::V1::Listeners::TelkomNewsBotProductionController < ApplicationController

  # a helpdesk account to be added/removed when some keyword `@helpdesk` is found
  # or to check whether the sender (from) is from heldesk or not, if yes and the keyword `Terima kasih` is found
  # then kick this helpdesk account
  HELPDESK_QISCUS_EMAIL = 'userid_217_helpdesk_telkomnews.mailinator.com@kiwari-prod.com'

  def create
    begin
      response = nil
      parameter_data = params[:telkom_news_bot_production]

      access_token = params[:token]
      sender = params[:from]
      qiscus_room_id = params[:chat_room][:qiscus_room_id]
      api_base_url = params[:api_base_url]
      message = params[:message][:text]

      # Collect participants qiscus email
      participants_qiscus_email = Array.new
      participants = params[:chat_room][:users]

      if participants.is_a?(Array)
        participants.each do | participant |
          participants_qiscus_email.push(participant[:qiscus_email])
        end
      end

      participant_api_url = api_base_url + "/api/v1/chat/conversations/#{qiscus_room_id}/participants/"

      # if message contains `@helpdesk` and not from helpdesk account then add it into participant
      if message.include?("@helpdesk") && sender[:qiscus_email] != HELPDESK_QISCUS_EMAIL
        response = add_participants(participant_api_url, access_token, [HELPDESK_QISCUS_EMAIL])
      elsif message.downcase.strip().gsub(/\s+/, " ").include?("terima kasih") && sender[:qiscus_email] == HELPDESK_QISCUS_EMAIL
        # if message contains "terima kasih" and it is from help desk account,
        # then remove helpdesk account
        response = remove_participants(participant_api_url, access_token, [HELPDESK_QISCUS_EMAIL])
      elsif !participants_qiscus_email.include?(HELPDESK_QISCUS_EMAIL)
        # if helpdesk is not participant in this room or sender is helpdesk, then pass the message to qiscus telkom news AI
        # if message does not meet two conditions above, then call BOT API and return the response to client
        # response = QiscusAI.telkom_news_bot("production", sender[:qiscus_id], sender[:qiscus_email], sender[:fullname], qiscus_room_id, message)
        response = QiscusAI.telkom_news_bot_raw_json("production", parameter_data)
      end

      render json: {
        data: response
      }, status: 200 and return
    rescue => e
      render json: {
        error: {
          message: e.message,
          backtrace: e.backtrace
        }
      }, status: 422 and return
    end
    
  end

  private
    def add_participants(url, jwt_token, qiscus_email)
      begin
        if !qiscus_email.kind_of?(Array) || qiscus_email.empty? || qiscus_email == ""
          raise StandardError.new("Emails is not array or nil.")
        end

        params = {
          "qiscus_email[]" => qiscus_email.to_a,
          "message" => "Hello!"
        }

        uri = URI.parse(url)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = (uri.scheme == "https")

        _headers = {}
        _headers["Content-Type"] = 'application/json'
        _headers["Authorization"] = "Token token=#{jwt_token}"

        req = Net::HTTP::Post.new(uri.path, _headers)
        req.set_form_data(params)

        res = https.request(req)

        if res.is_a?(Net::HTTPSuccess)
          if res.content_type == "application/json"
            message = JSON.parse(res.body)
            return "Helpdesk account added."
          else
            return "Helpdesk account added."
          end
        else
          if res.content_type == "application/json"
            e = JSON.parse(res.body)
            raise StandardError.new( e['error']['message'] )
          end
          raise StandardError.new("Error while calling callback at #{url} return HTTP status code #{res.code} (#{res.message}).")
        end
      rescue => e
        raise StandardError.new(e.message)
      end
    end

    def remove_participants(url, jwt_token, qiscus_email)
      begin
        if !qiscus_email.kind_of?(Array) || qiscus_email.empty? || qiscus_email == ""
          raise StandardError.new("Emails is not array or nil.")
        end

        params = {
          "qiscus_email[]" => qiscus_email.to_a,
          "message" => "Bye..."
        }

        uri = URI.parse(url)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = (uri.scheme == "https")

        _headers = {}
        _headers["Content-Type"] = 'application/json'
        _headers["Authorization"] = "Token token=#{jwt_token}"

        req = Net::HTTP::Delete.new(uri.path, _headers)
        req.set_form_data(params)

        res = https.request(req)

        if res.is_a?(Net::HTTPSuccess)
          if res.content_type == "application/json"
            message = JSON.parse(res.body)
            return "Helpdesk account removed. Thank you!"
          else
            return "Helpdesk account removed. Thank you!"
          end
        else
          if res.content_type == "application/json"
            e = JSON.parse(res.body)
            raise StandardError.new( e['error']['message'] )
          end
          raise StandardError.new("Error while calling callback at #{url} return HTTP status code #{res.code} (#{res.message}).")
        end
      rescue => e
        raise StandardError.new(e.message)
      end
    end

end