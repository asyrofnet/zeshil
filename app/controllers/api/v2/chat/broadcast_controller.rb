class Api::V2::Chat::BroadcastController < ProtectedController
    before_action :authorize_user
  
    # =begin
    # @apiVersion 2.0.0
    # @api {post} /api/v1/chat/send_broadcast Send Broadcast V2
    # @apiDescription Send broadcast to targets by qiscus emails
    # @apiName SendBroadcastV2
    # @apiGroup Broadcast
    #
    # @apiParam {String} access_token User access token
    # @apiParam {String} message The Message for Targets
    # @apiParam {Array} target_qiscus_emails the emails of targets in array form 
    # @apiParam {String} type The type of comment, default is text. optional 
    # @apiParam {JsonObject} payload payload needed for type other than text 
    # =end
    def send_broadcast
      begin
        target_qiscus_emails = params[:target_qiscus_emails]
        if target_qiscus_emails.nil? || !target_qiscus_emails.kind_of?(Array)
          raise Exception.new("Target qiscus emails must be present in array form.")
        end
        type_text = "text"
        type = params[:type] || type_text
        message = params[:message]
        payload = params[:payload]

        if message.nil? && type == type_text
          raise Exception.new("If type is text please send the message")
        end

        if type != type_text && payload.nil?
            raise Exception.new("If type is not text please send the payload") 
        end
  
        
        ActiveRecord::Base.transaction do
          # insert broadcast message into db
            broadcast_message = BroadcastMessage.new(
                user_id: @current_user.id,
                message: message,
                application_id: @current_user.application.id
            )

            broadcast_message.save!

            # send broadcast message in background job
            BroadcastMessageJobV2.perform_later(@current_user, target_qiscus_emails,  message,type,payload, broadcast_message.id)
  
        end
  
        render json: {
          status: "success"
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
  
      rescue Exception => e
        render json: {
          error: {
            message: e.message
          }
        }, status: 422 and return
      end
    end
  end
  