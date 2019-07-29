class Api::V1::Me::SessionsController < ProtectedController
  before_action :authorize_user

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/me/sessions List My Active Session
  # @apiDescription Get all active session except current session for this user to force logout
  # @apiName Me
  # @apiGroup Profile
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} [page=1] Page number
  # =end
  def index
    begin
      sessions = @current_user.auth_sessions.where.not(jwt_token: @current_jwt_token)
      sessions = sessions.order(updated_at: :desc).page(params[:page])

      render json: {
        data: sessions
      }
    rescue => e
      render json: {
        error: {
          message: e.message,
          class: e.class.name
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {delete} /api/v1/me/sessions/:session_id Delete My Session
  # @apiDescription Delete session. You cannot delete current session, if you want to destroy current session use `GET /api/v1/me/logout` instead.
  # @apiName Me
  # @apiGroup Profile
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} session_id Session id to be deleted
  # =end
  def destroy
    begin
      session = AuthSession.where(id: params[:id]).where(user_id: @current_user.id)
      session = session.where.not(jwt_token: @current_jwt_token)
      session = session.first # get first only

      if !session.nil?
        session.destroy
      end

      render json: {
        data: session
      }

    rescue ActiveRecord::RecordInvalid => e
      msg = ""
      e.record.errors.map do |k, v|
        key = k.to_s.humanize
        msg = msg + "#{key} #{v}, "
      end

      msg = msg.chomp(", ") + "."
      render json: {
        error: {
          message: msg
        }
      }, status: 422 and return

    rescue => e
      render json: {
        error: {
          message: e.message,
          class: e.class.name
        }
      }, status: 422 and return
    end
  end

end