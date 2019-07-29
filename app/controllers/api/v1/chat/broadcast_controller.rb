class Api::V1::Chat::BroadcastController < ProtectedController
  before_action :authorize_user

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/chat/broadcast Update broadcast message status
  # @apiDescription Update broadcast message status. There are some broadcast status = 'delivered', 'read'.
  # Broadcast message always have extras payload like this. {"is_broadcast": "true}
  # @apiName UpdateBroadcastStatus
  # @apiGroup Broadcast
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} qiscus_room_id Qiscus SDK room id
  # @apiParam {String} status Status = 'delivered', 'read'
  # =end
  def create
    begin
      qiscus_room_id = params[:qiscus_room_id]
      if qiscus_room_id.nil? || qiscus_room_id == ""
        raise InputError.new("Qiscus room id can not be blank.")
      end

      status = params[:status]
      if status.nil? || !status.present? || status == ""
        raise InputError.new("Status can not be blank.")
      else
        if status.downcase.delete(' ') != "delivered" && status.downcase.delete(' ') != "read"
          raise InputError.new("Permitted status is 'delivered' or 'read'.")
        end
      end

      chat_room = nil
      ActiveRecord::Base.transaction do
        chat_room = ChatRoom.find_by(qiscus_room_id: qiscus_room_id)
        if chat_room.nil?
          raise InputError.new("Chat room not found. Please check qiscus_room_id value.")
        end

        # Search broadcast receipt histories
        broadcast_receipt_histories = BroadcastReceiptHistory.where(chat_room_id: chat_room.id, user_id: @current_user.id)

        time_now = Time.now

        if status == "delivered"
          # only update status to delivered when delivered_at field is null
          broadcast_delivered = broadcast_receipt_histories.where(delivered_at: nil)
          broadcast_delivered.update_all(:delivered_at => time_now)
        elsif status == "read"
          # handling update status when directly read
          # need to update delivered_at and read_at field
          broadcast_read_delivered = broadcast_receipt_histories.where(delivered_at: nil).where(read_at: nil)
          broadcast_read_delivered.update_all(:delivered_at => time_now, :read_at => time_now)

          # only update status to read when read_at field is null
          broadcast_read = broadcast_receipt_histories.where(read_at: nil)
          broadcast_read.update_all(:read_at => time_now)

        end

      end

      render json: {
        data: chat_room
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
