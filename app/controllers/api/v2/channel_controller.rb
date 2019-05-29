require 'jwt'
require 'uri'

class Api::V2::ChannelController < ApplicationController
  def show
    begin
      success = false
      username = params[:id]

      if request.user_agent.downcase.match(/android/)
        @os = "android"
      elsif request.user_agent.downcase.match(/iphone|ipad/)
        @os = "ios"
      elsif request.user_agent.downcase.match(/mac|windows|linux/)
        @os = "desktop"
      end

      location = "https://kiwari.chat"
      message = "channel #{username} tidak ditemukan"
      additional_info = UserAdditionalInfo.where(key: "username", value: username).first
      if !additional_info.nil?
        p "additional info found"
        user_id = additional_info.user_id
        user = User.find(user_id)
        if !user.nil?
          p "user found"
          role_ids = user.role_ids
          official_id = [Role.find_official]
          is_official = (role_ids - official_id != role_ids)
          if is_official == true
            p "official account found"
            chat_room = ChatRoom.where(user_id: user_id, is_channel: true).first
            if !chat_room.nil?
              p "chat room found"
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

end
