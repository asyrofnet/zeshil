require 'net/http'

class QiscusCallSdk
  def initialize()
    @BASE_URL = ENV["CALL_SDK_URL"]
    @API_KEY = ENV["CALL_SDK_KEY"]
  end

  def logs_by_call_room_id(call_room_id)
    begin
      @CALL_ROOM_ID = call_room_id
      url = "#{@BASE_URL}/log/room/#{@CALL_ROOM_ID}"
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true   # set up ssl

      # set headers
      req = Net::HTTP::Get.new(uri.request_uri)
      req["Authorization"] = "Bearer #{@API_KEY}"
      res = http.request(req)

      if res.code == "404"
        # assuming that there is unintegrated data between qisme db and call sdk db.
        # this is happen because of this case:
        # when user1 calls user2, but user2 does not pick it up or user1/user2 abort the call, then
        # the data has not been recorded in the Qiscus Call SDK database but it has been recorded
        # in the qisme database. This happens because the process of input data calls to the
        # call logs table coincided with the call post system event message.

        connected_at = nil
        duration = nil
        status = "unknown"

      elsif res.code == "200"
        res = JSON.parse(res.read_body)
        connected_at = res["data"]["time"]
        duration = res["data"]["duration"]
        status = res["data"]["status"]
      else
        raise Exception.new("Error while calling Qiscus call SDK #{uri.host} return HTTP status code #{res.code} (#{res.message})")
      end

      return connected_at, duration, status
    rescue Exception => e
      raise Exception.new(e.message)
    end
  end

end
