class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  around_action :log_headers

  include ExceptionHandlingHelper

  rescue_from ActiveRecord::RecordNotFound,
    with: :record_not_found
  rescue_from ActionController::ParameterMissing,
    with: :parameter_missing
  rescue_from ArgumentError,
    with: :invalid_argument
  rescue_from TypeError,
    with: :invalid_type
  rescue_from ActionController::UnpermittedParameters,
    with: :parameter_missing
  rescue_from ActiveModel::UnknownAttributeError,
    with: :parameter_missing
  rescue_from ActiveRecord::RecordInvalid,
    with: :parameter_missing

  def log_headers
    http_envs = {}.tap do |envs|
      request.headers.each do |key, value|
        envs[key] = value
      end
    end

    if ENV["HTTP_DEBUG_LOG"] == true || ENV["HTTP_DEBUG_LOG"] == "true"
      Rails.logger.debug "*" * 60
      Rails.logger.debug "Request Headers: #{http_envs.inspect}"
      Rails.logger.debug "Request Params: #{params.inspect}"
      Rails.logger.debug "*" * 60
      Rails.logger.debug " "
      Rails.logger.debug " "
    end

    access_token = ""
    authenticate_with_http_token do |token, options|
      access_token = token
    end

    if access_token == ""
      access_token = params[:access_token]
    end

    # using qiscus email because it always exist in all user
    user_qiscus_email = ""
    user_id = -1
    app_id = "No Application"
    begin
      begin
        decoded_token = JWT.decode(access_token, ENV['JWT_KEY'], true, { :algorithm => 'HS256' })

        if decoded_token.nil? == false
          user = User.find(decoded_token.first["user_id"])
          if user.nil?
            user_qiscus_email = "Anonymous"
            user_id = 0
            app_id = "No Application"
          else
            user_qiscus_email = user.qiscus_email
            user_id = user.id
            app_id = user.application.app_id
          end
        end

      rescue Exception => error
        raise Exception.new(error.message)
      end

    rescue Exception => e
      # do nothing
    end

    begin
      yield
    ensure
      # send to sentry
      if response.status != 200 && response.status != 401
        error_message = ""

        begin
          error_message = JSON.parse(response.body)['error']['message']
        rescue Exception => e

        end

        extra = {
            parameters: params.inspect,
            http_request_header: http_envs,
            access_token: access_token,
            http_code_response: response.status,
            response_body: response.body
        }

        # bind the logged in user
        Raven.user_context(
          email: user_qiscus_email, # the actor's email address, if available
          ip_address: request.ip # '127.0.0.1'
        )

        Raven.capture_message("#{user_qiscus_email} #{error_message}",
          level: "error",
          logger: "#{user_qiscus_email}",
          extra: extra,
          tags: {'app_id' => app_id}
        )

        Raven::Context.clear!

      end

    end
  end
end
