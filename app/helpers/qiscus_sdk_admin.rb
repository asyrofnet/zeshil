require 'net/http'
require 'curb'
require 'net/http/post/multipart'

class QiscusSdkAdmin
  def initialize()
    @BASE_URL = ENV["QISCUS_SDK_ADMIN_URL"]
    @TOKEN = ENV["QISCUS_SDK_ADMIN_TOKEN"]
  end

  def create_app(app_name)
    create_app_url = "#{@BASE_URL}/api/v2/app/create"
    params = {
      "name" => app_name,
      "token" => @TOKEN,
      "package" => "qisme"
    }

    res = request("POST", create_app_url, params)

    app_id = res["results"]["app"]["code"]
    secret_key = res["results"]["app"]["secret_key"]

    if app_id.nil?
      raise StandardError.new("Qiscus app id name is null.")
    end

    if secret_key.nil?
      raise StandardError.new("Qiscus secret key is null.")
    end

    return app_id, secret_key
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

            Raven.capture_message("Error while calling QiscusSdkAdmin",
              level: "error",
              extra: {
                url: url,
                request_parameter: params,
                response_body: res.body
              }
            )

            raise StandardError.new("Error while calling Qiscus SDK Admin #{uri.host} return HTTP status code #{res.code} (#{res.message})")
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

            Raven.capture_message("Error while calling QiscusSdkAdmin",
              level: "error",
              extra: {
                url: url,
                request_parameter: params,
                response_body: res.body
              }
            )

            raise StandardError.new("Error while calling Qiscus SDK Admin #{uri.host} return HTTP status code #{res.code} (#{res.message})")
          end
        end
      rescue => e
        raise StandardError.new(e.message)
      end
    end

end
