require 'net/http'
require 'curb'
require 'net/http/post/multipart'

class QiscusSdk
  def initialize(app_name = "qisme", qiscus_sdk_secret = "qisme-123")
    @BASE_URL = ENV["QISCUS_SDK_URL"] || "https://api.qiscus.com"
    @QISCUS_SDK_APP_ID = app_name
    @QISCUS_SDK_SECRET = qiscus_sdk_secret
  end

  def login_or_register(email, password, username, avatar_url = nil)

    if email =~ /\A([^@^+\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      login_or_register_url = "#{@BASE_URL}/api/v2/mobile/login_or_register"
      params = {
        "email" => email,
        "password" => password,
        "username" => username,
        "avatar_url" => avatar_url
      }

      res = request("POST", login_or_register_url, params)
      token = res["results"]["user"]["token"]
      if token.nil?
        raise Exception.new("Qiscus token is null.")
      else
        return token
      end

    else
      raise Exception.new("Email is not valid.")
    end
  end

  def login_or_register_rest(email, password, username, avatar_url = nil)

    if email =~ /\A([^@^+\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      login_or_register_url = "#{@BASE_URL}/api/v2/rest/login_or_register"
      params = {
        "email" => email,
        "password" => password,
        "username" => username,
        "avatar_url" => avatar_url
      }

      res = request("POST", login_or_register_url, params)
      token = res["results"]["user"]["token"]
      if token.nil?
        raise Exception.new("Qiscus token is null.")
      else
        return token
      end

    else
      raise Exception.new("Email is not valid.")
    end
  end

  def get_or_create_room_with_target(token, emails, distinct_id = nil, options = nil)
    if token.nil?
      raise Exception.new("Token is empty.")
    end

    if emails.kind_of?(String)
      emails = [emails.to_s]
    end

    url = "#{@BASE_URL}/api/v2/mobile/get_or_create_room_with_target"
    params = {
      "token" => token,
      "emails" => emails.to_a,
      "distinct_id" => distinct_id,
      "options" => options
    }

    res = request("POST", url, params)

    room_name = res["results"]["room"]["room_name"]
    room_id = res["results"]["room"]["id"]
    topic_id = res["results"]["room"]["last_topic_id"]
    chat_type = res["results"]["room"]["chat_type"]

    if room_name.nil?
      raise Exception.new("Qiscus room name is null.")
    end

    if room_id.nil?
      raise Exception.new("Qiscus room id is null.")
    end

    if topic_id.nil?
      raise Exception.new("Qiscus topic id is null.")
    end

    is_group_chat = false
    if chat_type.nil?
      raise Exception.new("Qiscus chat type is null.")
    else
      if chat_type != "single"
        is_group_chat = true
      end
    end

    response = OpenStruct.new(
    {
      :name => room_name,
      :id => room_id,
      :topic_id => topic_id,
      :is_group_chat => is_group_chat
    })

    return response
  end

  def load_comments(token, topic_id, last_comment_id = nil, timestamp = nil, after = nil)
    url = "#{@BASE_URL}/api/v2/mobile/load_comments"
    params = {
      "token" => token,
      "topic_id" => topic_id.to_i,
      "last_comment_id" => last_comment_id.to_i,
      "timestamp" => timestamp,
      "after" => after
    }

    res = request("GET", url, params)
    res = res["results"]["comments"]
    return res.to_a
  end

  def post_comment(token, topic_id, comment, type="text", payload="", unique_temp_id = nil,extras = nil)
    url = "#{@BASE_URL}/api/v2/mobile/post_comment"
    params = {
      "token" => token,
      "topic_id" => topic_id.to_i,
      "comment" => comment,
      "type" => type,
      "payload" => payload,
      "unique_temp_id" => unique_temp_id,
      "extras" => extras
    }

    res = request("POST", url, params)
    res = res["results"]["comment"]
    return res
  end

  def get_room_by_id(token, id)
    url = "#{@BASE_URL}/api/v2/mobile/get_room_by_id"
    params = {
      "token" => token,
      "id" => id.to_i
    }

    res = request("GET", url, params)
    res = res["results"]
    return res
  end

  def sync(token, last_received_comment_id)
    url = "#{@BASE_URL}/api/v2/mobile/sync"
    params = {
      "token" => token,
      "last_received_comment_id" => last_received_comment_id.to_i
    }

    res = request("GET", url, params)
    res = res["results"]["comments"]
    return res.to_a
  end

  def get_rooms_info(user_email, room_id)
    if !user_email.kind_of?(String) || user_email.nil? || user_email == ""
      raise Exception.new("User email is not string or nil.")
    end

    if !room_id.kind_of?(Array) || room_id.nil? || room_id == ""
      raise Exception.new("Room is not array or nil.")
    end

    url = "#{@BASE_URL}/api/v2/rest/get_rooms_info"

    # params = ""
    # room_id = room_id.uniq
    # room_id.to_a.each do |rid|
    #   params += "room_id[]=#{rid}&"
    # end

    # params += "user_email=#{user_email}"

    # url = url + "?" + params
    params = {
      "user_email" => user_email,
      "room_id[]" => room_id.to_a,
      "room_id" => room_id.to_a,
    }

    status, res = curb_post("POST", url, params)
    # status, res = faraday_post('/api/v2/rest/get_rooms_info', params)

    if status == 200
      responses = Hash.new

      rooms_info = res["results"]["rooms_info"]
      rooms_info.to_a.each do |ri|
        tmp = {
          "last_comment_message" => ri["last_comment_message"],
          "last_comment_timestamp" => ri["last_comment_timestamp"],
          "room_id" => ri["room_id"],
          "room_name" => ri["room_name"],
          "room_type" => ri["room_type"],
          "last_comment_id" => ri["last_comment_id"],
          "unread_count" => ri["unread_count"],
          "room_avatar_url" => ri["room_avatar_url"]
        }

        # make room id as index for easy access in chat room model
        responses[ri["room_id"].to_i] = tmp
      end

      return status, responses
    else
      return status, res
    end
  end

  def create_room(name_, participants, creator, avatar_url = nil)
    if !name_.kind_of?(String) || name_.nil? || name_ == ""
      raise Exception.new("Name is not string or nil.")
    end

    if !participants.kind_of?(Array) || participants.nil? || participants == ""
      raise Exception.new("Participants is not array or nil.")
    end

    if !creator.kind_of?(String) || creator.nil? || creator == ""
      raise Exception.new("Creator is not string or nil.")
    end

    url = "#{@BASE_URL}/api/v2/rest/create_room"
    params = {
      "name" => name_,
      "participants[]" => participants.to_a,
      "creator" => creator,
      "avatar_url" => avatar_url
    }

    res = request("POST", url, params)

    response = OpenStruct.new(
    {
      :name => res["results"]["room_name"],
      :id => res["results"]["room_id"],
      :topic_id => res["results"]["room_id"],
      :is_group_chat => true
    })

    return response
  end

  def add_room_participants(emails, room_id)
    if !room_id.kind_of?(Integer) || room_id.nil? || room_id == ""
      raise Exception.new("Room id is not integer or nil.")
    end

    if !emails.kind_of?(Array) || emails.empty? || emails == ""
      raise Exception.new("Emails is not array or nil.")
    end

    url = "#{@BASE_URL}/api/v2/rest/add_room_participants"
    params = {
      "emails[]" => emails.to_a,
      "room_id" => room_id
    }

    res = request("POST", url, params)
    return res
  end

  def remove_room_participants(emails, room_id)
    if !room_id.kind_of?(Integer) || room_id.nil? || room_id == ""
      raise Exception.new("Room id is not integer or nil.")
    end

    if !emails.kind_of?(Array) || emails.empty? || emails == ""
      raise Exception.new("Emails is not array or nil.")
    end

    url = "#{@BASE_URL}/api/v2/rest/remove_room_participants"
    params = {
      "emails[]" => emails.to_a,
      "room_id" => room_id
    }

    res = request("POST", url, params)
    return res
  end

  def update_room(token, room_id, room_name, avatar_url, options = {})
    url = "#{@BASE_URL}/api/v2/mobile/update_room"

    params = {
      token: token,
      id: room_id,
      room_name: room_name,
      avatar_url: avatar_url,
      options: options
    }

    res = request("POST", url, params)
    return res
  end

  def post_system_event_message(system_event_type, room_id, subject_email, object_email = [], updated_room_name = nil, payload = {}, message = "", extras = {})
    url = "#{@BASE_URL}/api/v2/rest/post_system_event_message"
    params = {
      "system_event_type" => system_event_type,
      "room_id" => room_id,
      "subject_email" => subject_email,
      "object_email[]" => object_email.to_a.uniq, # only required when system event type is add_member or remove_member
      "updated_room_name" => updated_room_name, # only required when system event message type is change_room_name or create_room
      "payload" => payload, # only required when system event message type is custom
      "message" => message,
      "extras" => extras
    }

    res = request("POST", url, params)
    res = res["results"]["comment"]
    return res
  end

  def get_or_create_room_with_target_rest(emails, avatar_url = nil)
    # url = "#{@BASE_URL}/api/v2/rest/get_or_create_room_with_target"
    # Its to accommodate params array in GET
    url = "#{@BASE_URL}/api/v2/rest/get_or_create_room_with_target?emails[]=#{emails[0]}&emails[]=#{emails[1]}"
    params = {
      "emails[]" => emails.to_a,
      "avatar_url" => avatar_url
    }

    res = request("GET", url, params)

    room_name = res["results"]["room"]["room_name"]
    room_id = res["results"]["room"]["id"]
    topic_id = res["results"]["room"]["last_topic_id"]
    chat_type = res["results"]["room"]["chat_type"]

    if room_id.nil?
      raise Exception.new("Qiscus room id is null.")
    end

    if topic_id.nil?
      raise Exception.new("Qiscus topic id is null.")
    end

    is_group_chat = false
    if chat_type.nil?
      raise Exception.new("Qiscus chat type is null.")
    else
      if chat_type != "single"
        is_group_chat = true
      end
    end

    response = OpenStruct.new(
    {
      :name => room_name,
      :id => room_id,
      :topic_id => topic_id,
      :is_group_chat => is_group_chat
    })

    return response
  end

  def get_or_create_room_with_unique_id(token, unique_id, chat_name = nil, avatar_url = nil)
    if token.nil?
      raise Exception.new("Token is empty.")
    end

    if unique_id.nil?
      raise Exception.new("Unique id is empty.")
    end

    url = "#{@BASE_URL}/api/v2/mobile/get_or_create_room_with_unique_id"
    params = {
      "token" => token,
      "unique_id" => unique_id,
      "name" => chat_name,
      "avatar_url" => avatar_url
    }

    res = request("POST", url, params)

    room_name = res["results"]["room"]["room_name"]
    room_id = res["results"]["room"]["id"]
    unique_id = res["results"]["room"]["unique_id"]
    chat_type = res["results"]["room"]["chat_type"]

    if room_name.nil?
      raise Exception.new("Qiscus room name is null.")
    end

    if room_id.nil?
      raise Exception.new("Qiscus room id is null.")
    end

    if unique_id.nil?
      raise Exception.new("Qiscus unique_id id is null.")
    end

    is_group_chat = false
    if chat_type.nil?
      raise Exception.new("Qiscus chat type is null.")
    else
      if chat_type != "single"
        is_group_chat = true
      end
    end

    response = OpenStruct.new(
    {
      :name => room_name,
      :id => room_id,
      :unique_id => unique_id,
      :is_group_chat => is_group_chat
    })

    return response
  end

  def get_user_rooms(user_email, page = 1, limit = 100, show_participants = false)
    if !user_email.kind_of?(String) || user_email.nil? || user_email == ""
      raise Exception.new("User email is not string or nil.")
    end

    url = "#{@BASE_URL}/api/v2/rest/get_user_rooms?user_email=#{user_email}"

    params = {
      "user_email" => user_email,
      "page" => page,
      "limit" => limit,
      "show_participants" => show_participants,
    }

    res = request("GET", url, params)

    if res["status"] == 200
      responses = Hash.new

      rooms_info = res["results"]["rooms_info"]
      rooms_info.to_a.each do |ri|
        tmp = {
          "last_comment_message" => ri["last_comment_message"],
          "last_comment_timestamp" => ri["last_comment_timestamp"],
          "room_id" => ri["room_id"],
          "room_name" => ri["room_name"],
          "room_type" => ri["room_type"],
          "last_comment_id" => ri["last_comment_id"],
          "unread_count" => ri["unread_count"],
          "room_avatar_url" => ri["room_avatar_url"]
        }

        # make room id as index for easy access in chat room model
        responses[ri["room_id"].to_i] = tmp
      end

      return res["status"], responses
    else
      return status, res
    end
  end

  def upload_file(token, file)
      if !defined?(file.content_type) || !defined?(file.original_filename)
        raise Exception.new("Invalid file.")
      end

      user = User.find_by(qiscus_token: token)
      if user
        app_id = user.application.app_id
      else
        raise Exception.new("User not found")
      end

      upload_url = "#{@BASE_URL}/api/v2/mobile/upload"
      uri = URI.parse(upload_url)

      req = Net::HTTP::Post::Multipart.new uri.path,
        "file" => UploadIO.new(file, file.content_type, file.original_filename),
        "token" => token

      req.add_field("QISCUS_SDK_APP_ID", app_id)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'

      res = http.start do |h|
        h.use_ssl = (uri.scheme == "https")
        h.request(req)
      end

      res = JSON.parse(res.body)
      puts "RESPONSE #{res}"
      res = res["results"]["file"]["url"]
      return res
  end

  def update_profile(email, name = nil, avatar_url = nil, password =nil)
    update_profile_url = "#{@BASE_URL}/api/v2/rest/update_profile"
    params = {
      "email" => email,
      "name" => name,
      "avatar_url" => avatar_url,
      "password" => password
    }

    res = request("POST", update_profile_url, params)
    token = res["results"]["user"]["token"]
    if token.nil?
      raise Exception.new("Qiscus token is null.")
    else
      return token
    end
  end

  def broadcast(sender_email, emails, message, type = "text", payload = nil, extras = nil)
    url = "#{@BASE_URL}/api/v2/rest/broadcast"
    params = {
      "sender_email" => sender_email,
      "emails[]" => emails,
      "message" => message,
      "type" => type,
      "payload" => payload,
      "extras" => extras,
    }

    res = request("POST", url, params)
    res = res["results"]["comments"]

    return res
  end

  def broadcast_v21(sender_email, emails, message, type = "text", payload = nil, extras = nil)
    url = "#{@BASE_URL}/api/v2.1/rest/broadcast"

    params = {
      "sender_user_id" => sender_email,
      "target_user_ids[]" => emails,
      "message" => message,
      "type" => type,
      "payload" => payload,
      "extras" => extras,
    }

    res = request("POST", url, params)
    res = res["results"]["comments"]

    return res
  end

  def get_or_create_channel(chat_name, unique_id, participants, room_avatar_url=nil)
    if !participants.kind_of?(Array) || participants.nil? || participants == ""
      raise Exception.new("Participants is not array or nil.")
    end

    url = "#{@BASE_URL}/api/v2.1/rest/get_or_create_channel"
    params = {
      "unique_id" => unique_id,
      "chat_name" => chat_name,
      "participants[]" => participants.to_a,
      "room_avatar_url" => room_avatar_url
    }

    res = request("POST", url, params)

    response = OpenStruct.new(
    {
      :name => res["results"]["room_name"],
      :id => res["results"]["room"]["room_id"],
      :is_group_chat => true,
      :is_channel => true,
    })

    return response
  end


  private
    def request(req_method, url, params = {})
      return net_http(req_method, url, params)
    end

    # request using net/http
    def net_http(req_method, url, params = {})
      begin
        uri = URI.parse(url)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = (uri.scheme == "https")

        Rails.logger.debug "#{req_method} #{url} with params #{params}"

        _headers = {}
        _headers["QISCUS_SDK_APP_ID"] = @QISCUS_SDK_APP_ID
        _headers["QISCUS_SDK_SECRET"] = @QISCUS_SDK_SECRET

        if req_method == "POST"
          req = Net::HTTP::Post.new(uri.path, _headers)
          req.set_form_data(params)

          Rails.logger.debug "#{req_method} #{url} with headers #{req}"

          res = https.request(req)

          if res.is_a?(Net::HTTPSuccess)
            res = JSON.parse(res.body)

            Rails.logger.debug "#{req_method} #{url} response #{res}"
            return res
          else
            if res.content_type == "application/json"
              Rails.logger.debug "#{req_method} #{url} response #{JSON.parse(res.body)}"
            else
              Rails.logger.debug "#{req_method} #{url} response #{res.body}"
            end

            Raven.capture_message("Error while calling QiscusSdk",
              level: "error",
              extra: {
                url: url,
                request_parameter: params,
                response_body: res.body
              }
            )

            raise Exception.new("Error while calling Qiscus SDK #{uri.host} return HTTP status code #{res.code} (#{res.message})")
          end

        else
          # GET
          req = Net::HTTP::Get.new(uri, _headers)
          req.set_form_data(params)

          Rails.logger.debug "#{req_method} #{url} with headers #{req}"

          res = https.request(req)

          if res.is_a?(Net::HTTPSuccess)
            res = JSON.parse(res.body)

            Rails.logger.debug "#{req_method} #{url} response #{res}"
            return res
          else
            if res.content_type == "application/json"
              Rails.logger.debug "#{req_method} #{url} response #{JSON.parse(res.body)}"
            else
              Rails.logger.debug "#{req_method} #{url} response #{res.body}"
            end

            Raven.capture_message("Error while calling QiscusSdk",
              level: "error",
              extra: {
                url: url,
                request_parameter: params,
                response_body: res.body
              }
            )

            raise Exception.new("Error while calling Qiscus SDK #{uri.host} return HTTP status code #{res.code} (#{res.message})")
          end
        end
      rescue Exception => e
        raise Exception.new(e.message)
      end
    end

    # request using curb
    def curb_post(req_method, url, params = {})
      begin
        res = Curl.post(url, params) do |curl|
          curl.headers["QISCUS_SDK_APP_ID"] = @QISCUS_SDK_APP_ID
          curl.headers["QISCUS_SDK_SECRET"] = @QISCUS_SDK_SECRET
          # curl.verbose = true
        end

        Rails.logger.debug "#{req_method} #{url} with params #{params}"

        if res.content_type.include?('application/json')
          # should be 200 OK
          if res.response_code == 200
            return 200, JSON.parse(res.body_str)
          else
            error = JSON.parse(res.body_str)
            message = error['error']['detailed_messages'].to_a.join(", ").capitalize
            message = "Error while calling Qiscus SDK #{url} return HTTP status code #{res.response_code}. #{message}."

            Raven.capture_message(message,
              level: "error",
              extra: {
              url: url,
                request_parameter: params,
                response_body: JSON.parse(res.body_str)
              }
            )

            return res.response_code, error
          end
        else
          raise Exception.new("Qiscus SDK return HTTP status code #{res.response_code}.")
        end
      rescue Exception => e
        raise Exception.new(e.message)
      end
    end

    def faraday_post(url, params = {})
      begin
        conn = Faraday.new @BASE_URL do |con|
          con.request :url_encoded
          con.adapter :net_http
          con.headers["QISCUS_SDK_APP_ID"] = @QISCUS_SDK_APP_ID
          con.headers["QISCUS_SDK_SECRET"] = @QISCUS_SDK_SECRET
        end

        resp = conn.post url, params

        Rails.logger.debug "POST #{@BASE_URL}#{url} with params #{params}"

        if resp.status == 200
          res = resp.body
          return resp.status, JSON.parse(res)
        else
          error = JSON.parse(resp.body)
          message = error['error']['detailed_messages'].to_a.join(", ").capitalize
          message = "Error while calling Qiscus SDK #{@BASE_URL}#{url} return HTTP status code #{resp.status}. #{message}."

          Raven.capture_message(message,
            level: "error",
            extra: {
              url: url,
              request_parameter: params,
              response_body: error
            }
          )

          return resp.status, error
        end


      rescue Exception => e
        Raven.capture_message(e.message,
          level: "error",
          extra: {
            url: url
          }
        )
        raise Exception.new(e.message)
      end
    end
end
