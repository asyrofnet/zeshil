class Api::V2::Chat::BroadcastController < ProtectedController
    before_action :authorize_user
  
    # =begin
    # @apiVersion 2.0.0
    # @api {post} /api/v2/chat/send_broadcast Send Broadcast V2
    # @apiDescription Send broadcast to targets by phone numbers
    # @apiName SendBroadcastV2
    # @apiGroup Broadcast
    #
    # @apiParam {String} access_token User access token
    # @apiParam {String} message The Message for Targets
    # @apiParam {Array} phone_number[] Array of normalized phone number, for instance: `phone_number[]=+62...&phone_number[]=+62...`
    # @apiParam {String} type The type of comment, default is text. optional 
    # @apiParam {JsonObject} payload payload needed for type other than text 
    # =end
    def send_broadcast
      begin
        phone_number = params[:phone_number]
        if phone_number.nil? || !phone_number.kind_of?(Array)
          raise InputError.new("phone_number must be present in array form.")
        end
        phone_numbers = Array.new
        current_user_phone_number = @current_user.phone_number
        
        params[:phone_number].each do | phone_number |  
          phone_number = phone_number.strip().delete(' ') # remove all spaces
          phone_number = phone_number.strip().delete('-') # remove dash
          phone_number = phone_number.gsub(/[[:space:]]/, '')

          if phone_number.start_with?("8")
            phone_number = @current_user.country_code + phone_number
          elsif phone_number.start_with?("0")
            phone_number = phone_number[1..-1]
            phone_number = @current_user.country_code + phone_number
          end
          phone_numbers.push(phone_number)
        end

        target_qiscus_emails = User.where(phone_number: phone_numbers).pluck(:qiscus_email)
        type_text = "text"
        type = params[:type] || type_text
        message = params[:message]
        payload = params[:payload]
        if payload.present?
          payload = payload.to_json
        end

        if message.nil? && type == type_text
          raise InputError.new("If type is text please send the message")
        end

        if type != type_text && payload.nil?
            raise InputError.new("If type is not text please send the payload") 
        end
  
        broadcast_message_id = nil  
        ActiveRecord::Base.transaction do
          # insert broadcast message into db
          broadcast_message = BroadcastMessage.new(
            user_id: @current_user.id,
            message: message,
            application_id: @current_user.application.id
          )

          if broadcast_message.save!
            broadcast_message_id = broadcast_message.id
            # send broadcast message in background job
            BroadcastMessageJobV2.perform_later(@current_user, target_qiscus_emails, message, type, payload, broadcast_message.id)
          else
            raise InputError.new("Broadcast message not created") 
          end
        end
  
        render json: {
          status: "success",
          broadcast_message_id: broadcast_message_id,
          phone_numbers: phone_numbers
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
  