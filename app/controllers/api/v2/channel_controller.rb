require 'jwt'
require 'uri'

class Api::V2::ChannelController < ApplicationController

  def generate_invite_url
    begin
      params[:qiscus_email] = "userid_2_6286817281728@kiwari-stag.com"
      invite_url = "kiwari.me/?qiscus_email=#{params[:qiscus_email]}"
      message = "invite url anda :\n#{invite_url} "

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
      location = "http://www.yahoo.com"
      # cuman sekarang belum pakai username channelnya, kalau sudah diimplementasi, apakah harus ubah create channel dengan username juga?
      message = "channel #{username} tidak ditemukan"
      additional_info = UserAdditionalInfo.where(key: "username", value: username).first
      if !additional_info.nil?
        p "additional info ketemu"
        user_id = additional_info.user_id
        user = User.find(user_id)
        if !user.nil?
          p "user ketemu"
          role_ids = user.role_ids
          official_id = [Role.find_official]
          is_official = (role_ids - official_id != role_ids)
          if is_official == true
            p "official account ketemu"
            chat_room = ChatRoom.where(user_id: user_id).first
            if !chat_room.nil?
              p "chat room ketemu"
              is_channel = chat_room.is_channel == true
              if is_channel == true
                # location = "http://www.google.com"
                location = "https://play.google.com/store/apps/details?id=com.qiscus.kiwari&referrer=#{username}"
                success = true
                message = "channel #{username} ditemukan"              
              end
            end
          end
        end
      end
      # render json: {
      #   success: success,
      #   message: message
      # }
      if success == true
        redirect_back fallback_location: location
      else
              render json: {
              success: success,
              message: message
            }
      end

    rescue Exception => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

end
