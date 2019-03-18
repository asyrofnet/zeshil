class Api::V1::Admin::Users::SessionsController < ProtectedController
  before_action :authorize_admin


  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/admin/users/:user_id/sessions List User Session
  # @apiDescription All user session for given user id
  # @apiName AdminUserSessionIndex
  # @apiGroup Admin - User Sessions
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {Number} user_id User id
  # @apiParam {Number} [page=1] Page number
  # =end
  def index
    begin
      user = User.find(params[:user_id])

      auth_sessions = []
      if !user.nil?
        auth_sessions = user.auth_sessions.order(updated_at: :desc).page(params[:page])
      end

      render json: {
        data: auth_sessions
      }
    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {delete} /api/v1/admin/users/:user_id/sessions/:session_id Delete User Session
  # @apiDescription Delete user session
  # @apiName AdminUserSessionDelete
  # @apiGroup Admin - User Sessions
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {Number} user_id User id
  # @apiParam {Number} session_id Session id of this user
  # =end
  def destroy
    begin
      session = AuthSession.find_by(id: params[:id], user_id: params[:user_id])

      if user.id == @current_user.id
        raise Exception.new('You cannot delete your own session since you will have no access anymore. To delete your session please use /me instead.')
      end

      if !session.nil?
        session.destroy
      else
        raise Exception.new("Session with id #{params[:id]} is not found.")
      end

      render json: {
        data: session
      }
    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {delete} /api/v1/admin/users/:user_id/flush_sessions Delete User Sessions
  # @apiDescription Delete all session of this user
  # @apiName AdminUserSessionsDelete
  # @apiGroup Admin - User Sessions
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {Number} user_id User id
  # =end
  def flush
    begin
      session = AuthSession.where(user_id: params[:user_id])

      if params[:user_id].to_i == @current_user.id
        raise Exception.new('You cannot delete your own session since you will have no access anymore. To delete your session please use /me instead.')
      end

      if !session.empty?
        session.destroy_all
      end

      render json: {
        data: session
      }
    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422
    end
  end

end