class Api::V2::Chat::AutoResponderController < ProtectedController
    before_action :authorize_user
  
    # =begin
    # @apiVersion 2.0.0
    # @api {post} /api/v2/chat/auto_responder Update Auto Responder V2
    # @apiDescription Update Official Auto Starter Responder
    # @apiName Update Auto Responder V2
    # @apiGroup Chat
    #
    # @apiParam {String} access_token User access token
    # @apiParam {String} auto_starter the string to be used as auto starter
    # @apiParam {String} auto_responder the string to be used as auto responder
    # =end
    def create
      begin
        if !@current_user.is_official
          raise InputError.new("Only Official can update auto responder")
        end
        auto_responder = params[:auto_responder]
        auto_starter = params[:auto_starter]
        
        ActiveRecord::Base.transaction do
         

          if auto_starter.present?
            UserAdditionalInfo.create_or_update_user_additional_info(
            [@current_user.id], 
            UserAdditionalInfo::AUTO_STARTER_KEY, 
            auto_starter
            )  
          end

          if auto_responder.present?
            UserAdditionalInfo.create_or_update_user_additional_info(
            [@current_user.id], 
            UserAdditionalInfo::AUTO_RESPONDER_KEY, 
            auto_responder
            )
          end

        end

        auto_responder_data = @current_user.user_additional_infos.where(key: [UserAdditionalInfo::AUTO_RESPONDER_KEY,UserAdditionalInfo::AUTO_STARTER_KEY])
  
        render json: {
          data: auto_responder_data
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


    # =begin
    # @apiVersion 2.0.0
    # @api {post} /api/v2/chat/auto_responder/delete Delete Auto Responder V2
    # @apiDescription Delete Official Auto Starter Responder
    # @apiName Delete Auto Responder V2
    # @apiGroup Chat
    #
    # @apiParam {String} access_token User access token
    # @apiParam {String} delete contains what to delete, "auto_responder","auto_starter" or "both"
    # =end
    def delete
      begin
        delete = params[:delete]
        
        ActiveRecord::Base.transaction do
         

          if delete == UserAdditionalInfo::AUTO_STARTER_KEY
            data = @current_user.user_additional_infos.find_by(key: UserAdditionalInfo::AUTO_STARTER_KEY)
            data.destroy if !data.nil?
          elsif delete == UserAdditionalInfo::AUTO_RESPONDER_KEY
            data = @current_user.user_additional_infos.find_by(key: UserAdditionalInfo::AUTO_RESPONDER_KEY)
            data.destroy if !data.nil?
          elsif delete == "both"
            data = @current_user.user_additional_infos.where(key: [UserAdditionalInfo::AUTO_RESPONDER_KEY,UserAdditionalInfo::AUTO_STARTER_KEY])
            data.destroy_all
          end  

          
        end

        render json: {
          status: "success delete " + delete.to_s
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

    # =begin
    # @apiVersion 2.0.0
    # @api {post} /api/v2/chat/auto_responder/trigger Trigger Auto Responder V2
    # @apiDescription Send auto reply from OA. use either official_id or official_qiscus_email
    # @apiName Trigger Auto Responder V2
    # @apiGroup Chat
    #
    # @apiParam {String} access_token User access token
    # @apiParam {Integer} official_id the user ID of OA. use either this or official_qiscus_email
    # @apiParam {String} official_qiscus_email the qiscus email of OA. use either this or official_id
    # @apiParam {Integer} qiscus_room_id the qiscus room id
    # =end
    def trigger
      
    begin
      status = "fail"
        comments = nil
      ActiveRecord::Base.transaction do
        official = nil
        official_qiscus_email = params[:official_qiscus_email]
        if official_qiscus_email.present?
          official = User.find_by(qiscus_email: official_qiscus_email)
        else    
          official = User.find(params[:official_id])
        end
        qiscus_token = official.qiscus_token
        application = @current_user.application
        additional_info = official.user_additional_infos.find_by(key: UserAdditionalInfo::AUTO_RESPONDER_KEY)
        
        if additional_info.nil? || !additional_info.value.present?
          comments = "No Auto Responder Found"
        else
          status = "success"
          message = additional_info.value

          room_id = params[:qiscus_room_id]

          qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
          comments = qiscus_sdk.post_comment(qiscus_token, room_id, message)
        end
      end

      render json: {
        status: status,
        data: comments
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
  