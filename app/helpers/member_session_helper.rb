require 'jwt'

module MemberSessionHelper

  def authorize_admin
    begin
      if authorized_user
        if @current_user.is_admin
          return true
        else
          render json: {
            error: {
              message: 'Unauthorized Access. User is not admin.'
            }
          }, status: 401
        end
      else
        render json: {
          error: {
            message: 'Unauthorized Access'
          }
        }, status: 401
      end
    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 401
    end
  end

  def authorize_user
    begin
      if authorized_user
        return true
      else
        render json: {
          error: {
            message: 'Unauthorized Access'
          }
        }, status: 401
      end
    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 401
    end
  end

  def authorized_user
    begin
      # access token via post or get parameter
      if params[:access_token] != "" && !params[:access_token].nil?
        @current_user = MemberSessionHelper.lookup_token(params[:access_token])
        @current_jwt_token = params[:access_token]
        return true
      else
        # try using header
        authenticate_with_http_token do |token, options|
          @current_user = MemberSessionHelper.lookup_token(token)
          @current_jwt_token = token
          return true
        end
      end
    rescue Exception => e
      raise Exception.new(e.message)
    end
  end

  # Validate access token
  def self.lookup_token(jwt_token)
    begin
      decoded_token = JWT.decode(jwt_token, ENV['JWT_KEY'], true, { :algorithm => 'HS256' })

      # decoded token must be success
      if !decoded_token.nil?
        auth_session = AuthSession.find_by(jwt_token: jwt_token, user_id: decoded_token.first["user_id"])
        if !auth_session.nil?
          # update last active session
          auth_session.updated_at = Time.now
          auth_session.save()

          # return current user
          return auth_session.user
        else
          raise Exception.new('Session is compromised, you enforced to logout from this application because of invalid token.')
        end
      end
      
    rescue JWT::ExpiredSignature => e
      # Handle expired token, e.g. logout user or deny access
      raise Exception.new(e.message)
    rescue JWT::VerificationError => e
      raise Exception.new(e.message)
    rescue Exception => e
      raise Exception.new(e.message)
    end

  end # end of lookup_token

end
