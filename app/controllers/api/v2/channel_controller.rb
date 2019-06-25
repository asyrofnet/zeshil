require 'jwt'
require 'uri'

class Api::V2::ChannelController < ProtectedController
  before_action :authorize_user, only: [:username_to_room_id]

    # =begin
    # @apiVersion 2.0.0
    # @api {get} /api/v2/channel/:id Channel Deeplink V2
    # @apiName Channel Deeplink
    # @apiDescription Request deeplink from username, change the ID in url below. It would return undefined because redirect
    # @apiGroup Channel
    #
    # @apiParam {String} id The username of the accouunt
    # =end
  def show
    begin
      username = params[:id]
      @os = Format.get_os_request(request)

      success = false
      location = "https://kiwari.chat"
      message = "channel #{username} tidak ditemukan"

      additional_info = UserAdditionalInfo.where(key: UserAdditionalInfo::USERNAME_KEY, value: username).first
      if !additional_info.nil?
        user_id = additional_info.user_id
        user = User.find(user_id)
        if !user.nil?
          role_ids = user.role_ids
          official_id = [Role.find_official]
          is_official = (role_ids - official_id != role_ids)
          if is_official == true
            chat_room = ChatRoom.where(user_id: user_id, is_channel: true).first
            if !chat_room.nil?
              room_id = chat_room.qiscus_room_id
              if @os == "android"
                bundle_id = ENV['ANDROID_BUNDLE_ID'] || "com.qiscus.kiwari"
                location = "market://details?id=#{bundle_id}&referrer=#{room_id}"
              elsif @os == "ios"
                bundle_id = ENV['IOS_BUNDLE_ID'] || "id1212085223?mt=8"
                location = "itms://itunes.apple.com/us/app/kiwari/#{bundle_id}&referral=#{room_id}"
              end
              success = true
              message = "channel #{username} ditemukan"              
            end
          end
        end
      end

      redirect_back fallback_location: location

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

    # =begin
    # @apiVersion 2.0.0
    # @api {get} /api/v2/channel/username_to_room_id Username To Room V2
    # @apiName GetRoomByUsername
    # @apiGroup Channel
    #
    # @apiParam {String} access_token User access token    
    # @apiParam {String} username The username of the channel
    # =end  

  def username_to_room_id
    begin
      username = params[:username]
      room_id = nil
      success = false
      message = "channel #{username} tidak ditemukan"
      additional_info = UserAdditionalInfo.where(key: UserAdditionalInfo::USERNAME_KEY, value: username).first
      if !additional_info.nil?
        user = additional_info.user
        if !user.nil?
          if user.is_official
            chat_room = ChatRoom.where(user_id: user.id, is_channel: true).first
            if !chat_room.nil?
              app_id = user.application.app_id
              qiscus_email = user.qiscus_email
              unique_id = "#{app_id}##{qiscus_email}##{app_id}"
              room_id = chat_room.qiscus_room_id
              success = true
              message = "channel #{username} ditemukan"              
            end
          end
        end
      end

      render json: {
        message: message,
        success: success,
        room_id: room_id,
        unique_id: unique_id,
        chat_room: chat_room
      }

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

end
