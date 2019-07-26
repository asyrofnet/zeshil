class Api::V1::Admin::CallsController < ProtectedController
  before_action :authorize_admin

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/admin/calls Admin List of call logs
  # @apiName AdminListofCallLogs
  # @apiGroup Admin - Calls
  # @apiPermission Admin
  #
  # @apiParam {String} access_token Admin access token
  # @apiParam {Number} user_id User id. if this parameter not used, it will show all user's call logs in the application
  # @apiParam {Number} page Page number
  # @apiParam {Number} limit Limit
  # @apiParam {String} [call_participant] Filter call logs by participant except user_id above. You can use user fullname or user phone number
	# @apiParam {String} [start_date] Filter call logs by date. filter this by start_date and end_date. use format YYYY-MM-DD
	# @apiParam {String} [end_date] Filter call logs by date. filter this by start_date and end_date. use format YYYY-MM-DD
  # =end
  def index
    total_page = 0
    total = 0
    limit = params[:limit]
    page = params[:page]

    begin
      if params[:user_id].present?
        user = User.find_by(id: params[:user_id], application_id: @current_user.application_id)

        if user.nil?
          raise InputError.new("User not found.")
        end

        call_logs = CallLog.where(caller_user_id: user.id, application_id: @current_user.application_id)
        call_logs = call_logs.or(CallLog.where(callee_user_id: user.id, application_id: @current_user.application_id))
      else
        call_logs = CallLog.where(application_id: @current_user.application_id)
      end


      if params[:start_date].present? && params[:end_date].present?
        start_date = params[:start_date].to_time
        end_date = params[:end_date].to_time

        call_logs = call_logs.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
      end

      if params[:call_participant].present? && params[:user_id].present?
        # can input phone number or name
        call_participant = params[:call_participant]
        call_participant = User.where("phone_number LIKE ?", "%#{call_participant}%").or(User.where("fullname ILIKE ?", "%#{call_participant}%")).first

        call_logs = call_logs.where(caller_user_id: call_participant.id, callee_user_id: user.id, application_id: @current_user.application_id)
                    .or(call_logs.where(caller_user_id: user.id, callee_user_id: call_participant.id, application_id: @current_user.application_id))
      elsif params[:call_participant].present? && !params[:user_id].present?
        raise InputError.new("you can not get call history data based on the participant if the user parameter is empty.")
      end

      # update call duration and connected_at from call sdk
      call_logs.each do |call_log|
        if call_log.status == "missed"  # this assume that "missed" status is because the user call is on going
          call_sdk = QiscusCallSdk.new()
          connected_at, duration, status = call_sdk.logs_by_call_room_id(call_log.call_room_id)

          call_log.update(duration: duration, connected_at: connected_at, status: status)
        end
      end

      call_logs = call_logs.order(created_at: :desc)

      total = call_logs.count

      # pagination only when exist
      if page.present?
        call_logs = call_logs.page(page)
      end

      # if limit and page present, then use kaminari pagination
      if limit.present? && page.present?
        call_logs = call_logs.per(limit)
      # else use limit from ActiveRecord
      elsif limit.present?
        call_logs = call_logs.limit(limit)
      else
        limit = 25
        call_logs = call_logs.limit(25)
      end

      total_page = (total / limit.to_f).ceil

      render json: {
        meta: {
          limit: limit.to_i,
          page: page == nil || page.to_i < 0 ? 0 : page.to_i,
          total_page: total_page,
          total: total,
        },
        data: call_logs
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
          message: msg,
          backtrace: e.backtrace
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
