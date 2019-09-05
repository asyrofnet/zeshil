class Api::V2::Chat::BroadcastHistoryController < ProtectedController
    before_action :authorize_user

    def get_history_by_sender
        user_id = @current_user.id
        history = BroadcastReceiptHistory.select('broadcast_message_id').where('user_id = ?', user_id).distinct
        data = []
        history.each do |x| 
            data.push({
                broadcast_id: x.broadcast_message_id
            })
        end
        render json: {
            code: 200,
            status: "Get history list by sender",
            history_list: data
        }
    end

    def get_detail_history
        user_id = @current_user.id
        broadcast_id = params[:broadcast_id]
        history = BroadcastReceiptHistory.where('broadcast_message_id = ?', broadcast_id).where('user_id = ?', user_id)
        data = []
        history.each do |x|
            is_sent = false
            if x.sent_at != nil
                is_sent = true
            end
            data.push({
                id: x.id,
                message: x.broadcast_message.message,
                is_sent: is_sent,
                sent_at: x.sent_at
            })
        end
        render json: {
            code: 200,
            status: "Get detail history",
            sender: {
                id: history[0].user.id,
                name: history[0].user.fullname
            },
            broadcast_history: data
        }
    end
end
