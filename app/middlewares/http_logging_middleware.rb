class HttpLoggingMiddleware

  def initialize(app)
    @app = app
  end

  def call(env)
    request_started_on = Time.now
    @status, @headers, @response = @app.call(env)
    request_ended_on = Time.now

    begin
      if ENV["HTTP_DEBUG_LOG"] == true || ENV["HTTP_DEBUG_LOG"] == "true"
        Rails.logger.debug "=" * 60
        Rails.logger.debug "Http Status Code: #{@status}"
        Rails.logger.debug "Request delta time: #{request_ended_on - request_started_on} seconds."
        Rails.logger.debug "Response Header: #{@headers}"
        Rails.logger.debug "Response Body: #{@response.body}"
        Rails.logger.debug "=" * 60
      end
    rescue => e
      # do nothing
    end
    
    return [@status, @headers, @response]
  end

end