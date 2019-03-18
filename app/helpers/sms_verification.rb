require 'nexmo'
require 'twilio-ruby'
require 'base64'
require 'net/http'

class SmsVerification
  SMS_SENDER = ENV["SMS_SENDER"] || "Kiwari"
  NEXMO_API_KEY = ENV['NEXMO_API_KEY'] || "DUMMY_OR_DEVELOPMENT_API_KEY"
  NEXMO_API_SECRET = ENV['NEXMO_API_SECRET'] || "DUMMY_SECRET_API_KEY"
  TWILIO_SID_KEY = ENV['TWILIO_SID_KEY'] || "AC1f0a135ab58088f504d06cac63477238"
  TWILIO_TOKEN_KEY = ENV['TWILIO_TOKEN_KEY'] || "7cf5dbe93359d02e572e62bd9fcefa0c"

  INFOBIP_USERNAME = ENV['INFOBIP_USERNAME'] || "QiscusTekno"
  INFOBIP_PASSWORD = ENV['INFOBIP_PASSWORD'] || "Test1234"
  # this must be base64 encode string from "username:password"
  INFOBIP_AUTHORIZATION_KEY = Base64.encode64("#{INFOBIP_USERNAME}:#{INFOBIP_PASSWORD}")

  MAINAPI_CLIENT_ID = ENV['MAINAPI_CLIENT_ID']
  MAINAPI_CLIENT_SECRET = ENV['MAINAPI_CLIENT_SECRET']
  MAINAPI_GRANT_TYPE = ENV['MAINAPI_GRANT_TYPE']
  MAINAPI_USERNAME = ENV['MAINAPI_USERNAME']
  MAINAPI_PASSWORD = ENV['MAINAPI_PASSWORD']

  def self.request(user, code)
    phone_no = user.phone_number
    attempt = user.verification_attempts
    application_id = user.application_id
		sms_sender = user.application.sms_sender
    verify_text = "Your passcode for #{user.application.app_name} is #{code}"

    provider_setting = ProviderSetting.find_by(application_id: application_id, attempt: attempt)

    # prevent provider setting null error when no one provider setting in db
    if provider_setting.nil?
      raise Exception.new("Provider setting is not exists, you may not receive your passcode.")
    end

    provider_name = provider_setting.provider.provider_name
    provider_id = provider_setting.provider_id

    content = send(provider_name, phone_no, verify_text, user.application.sms_sender)

    # Save sms verification log
    sms_verification_log = SmsVerificationLog.new
    sms_verification_log.user_id = user.id
    sms_verification_log.provider_id = provider_id
    sms_verification_log.content = content
    # sms_verification_log.status = true # Skip this field because for now only need the response from sms provider
    sms_verification_log.save

    if attempt == 0
      user.update_columns(verification_attempts: 1)
    elsif attempt == 1
      user.update_columns(verification_attempts: 2)
    elsif attempt == 2
      user.update_columns(verification_attempts: 0)
    end
  end

  def self.send(provider, phone_no, verify_text, sms_sender)
    if provider == "twilio"
      send_using_twilio(phone_no, verify_text, sms_sender)
    elsif provider == "infobip"
      send_using_infobip(phone_no, verify_text, sms_sender)
    elsif provider == "nexmo"
      send_using_nexmo(phone_no, verify_text, sms_sender)
    elsif provider == "mainapi"
      send_using_mainapi(phone_no, verify_text, sms_sender)
    end
  end

  def self.confirm(secret_code, secret_code2)
    return (secret_code == secret_code2) ? true : false
  end

  def self.nexmo_client
    Nexmo::Client.new(key: NEXMO_API_KEY, secret: NEXMO_API_SECRET)
  end

  def self.send_using_twilio(phone_no, verify_text, sms_sender)
    @client = Twilio::REST::Client.new(TWILIO_SID_KEY, TWILIO_TOKEN_KEY)
      begin
        message = @client.api.account.messages.create(
          from: sms_sender,
          to: phone_no,
          body: verify_text
        )
      rescue Twilio::REST::RestError => e
          puts e.message
      end
  end

  def self.send_using_nexmo(phone_no, verify_text, sms_sender)
    message = nexmo_client.sms.send(to: phone_no, from: sms_sender, text: verify_text)
  end

  def self.generate_code(phone_number, application_id)
    user = User.find_by(phone_number: phone_number, application_id: application_id)

    if user.nil?
      rand(1000..9999).to_s
    else
      user_dedicated_passcode = UserDedicatedPasscode.find_by(user_id: user.id, application_id: application_id)

      if user_dedicated_passcode.nil?
        rand(1000..9999).to_s
      else
        user_dedicated_passcode.passcode
      end
    end
  end

  def self.send_using_infobip(phone_number, verify_text, sms_sender)
    begin
      # infobip url api for sending single text message
      uri = URI.parse('http://107.20.199.106/restapi/sms/1/text/single')
      https = Net::HTTP.new(uri.host, uri.port)

      _headers = {}
      _headers["Authorization"] = "Basic #{INFOBIP_AUTHORIZATION_KEY}"
      _headers["Content-Type"]  = "application/json"
      _headers["Accept"]        = "application/json"

      params = {
        "from": sms_sender,
        "to": phone_number,
        "text": verify_text
      }

      req = Net::HTTP::Post.new(uri.path, _headers)
      req.body = params.to_json

      res = https.request(req)

      if res.is_a?(Net::HTTPSuccess)
        res = JSON.parse(res.body)

        Rails.logger.debug "POST #{uri} response #{res}"
        return res
      else
        if res.content_type == "application/json"
          Rails.logger.debug "POST #{uri} response #{JSON.parse(res.body)}"
        else
          Rails.logger.debug "POST #{uri} response #{res.body}"
        end

        raise Exception.new("Error while calling InfoBip API with HTTP status #{res.code} (#{res.message})")
      end

    rescue Exception => e
      Rails.logger.debug e.message
    end
  end

  def self.send_using_mainapi(phone_number, verify_text, sms_sender)
    begin
      # get mainapi access token
      access_token = get_mainapi_token

      # mainapi url api for sending single text message
      uri = URI.parse('http://api.mainapi.net/smsnotification/1.0.0/messages')
      https = Net::HTTP.new(uri.host, uri.port)

      _headers = {}
      _headers["Authorization"] = "Bearer #{access_token}"
      _headers["Content-Type"]  = "application/x-www-form-urlencoded"
      _headers["X-MainAPI-Senderid"]  = sms_sender
      _headers["X-MainAPI-Username"]  = MAINAPI_USERNAME
      _headers["X-MainAPI-Password"]  = MAINAPI_PASSWORD

      params = {
        "msisdn": phone_number,
        "content": verify_text
      }

      req = Net::HTTP::Post.new(uri.path, _headers)
      req.set_form_data(params)

      res = https.request(req)

      if res.is_a?(Net::HTTPSuccess)
        res = JSON.parse(res.body)

        Rails.logger.debug "POST #{uri} response #{res}"
        return res
      else
        if res.content_type == "application/json"
          Rails.logger.debug "POST #{uri} response #{JSON.parse(res.body)}"
        else
          Rails.logger.debug "POST #{uri} response #{res.body}"
        end

        raise Exception.new("Error while calling Mainapi API with HTTP status #{res.code} (#{res.message})")
      end

    rescue Exception => e
      Rails.logger.debug e.message
    end
  end

  def self.get_mainapi_token()
    begin
      # mainapi url api for getting access token
      uri = URI.parse('http://api.mainapi.net/token')
      https = Net::HTTP.new(uri.host, uri.port)

      _headers = {}
      _headers["Content-Type"]  = "application/x-www-form-urlencoded"

      params = {
        "client_id": MAINAPI_CLIENT_ID,
        "client_secret": MAINAPI_CLIENT_SECRET,
        "grant_type": MAINAPI_GRANT_TYPE
      }

      req = Net::HTTP::Post.new(uri.path, _headers)
      req.set_form_data(params)

      res = https.request(req)

      if res.is_a?(Net::HTTPSuccess)
        res = JSON.parse(res.body)

        Rails.logger.debug "POST #{uri} response #{res}"
        access_token = res["access_token"]
        return access_token
      else
        if res.content_type == "application/json"
          Rails.logger.debug "POST #{uri} response #{JSON.parse(res.body)}"
        else
          Rails.logger.debug "POST #{uri} response #{res.body}"
        end

        raise Exception.new("Error while calling Mainapi API with HTTP status #{res.code} (#{res.message})")
      end

    rescue Exception => e
      Rails.logger.debug e.message
    end
  end

end
