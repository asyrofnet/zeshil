require 'jwt'
require 'uri'

class Api::V2::ChannelController < ApplicationController

  def generate_invite_url
    begin
      # params[:username] = "channel_qiscus"
      invite_url = "kiwari.me/?username=#{params[:username]}"
      message = "invite url anda :\n#{invite_url}"

      topic_id =  2456640
      qiscus_token = "D4cAi4F0NctKh8ljtko5"
      app_id = "kiwari-stag"
      qiscus_sdk_secret = "kiwari-stag-123"

      qiscus_sdk = QiscusSdk.new(app_id, qiscus_sdk_secret)
      comments = qiscus_sdk.post_comment(qiscus_token, topic_id, message, "text")

      render json: {
        message: comments
      }
    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

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
                # location = "https://play.google.com/store/apps/details?id=com.qiscus.kiwari&referrer=#{room_id}"
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
