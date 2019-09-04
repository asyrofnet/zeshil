class Api::V2::Chat::BroadcastHistoryController < ProtectedController
    before_action :authorize_user

    def get_history_by_sender
        user_id = @current_user.id
        history = BroadcastReceiptHistory.get_history(user_id)
        broadcast = []
        history.each |x| do 
            broadcast.push({
                
            })
        end
        render json: {
            status: "success",
            broadcast: broadcast
        }
    end
end
