require 'uri'

class Api::V1::Webhooks::BotBuilderController < ApplicationController
  SessionLength = 24.hour.to_i
  def handler
    begin
      def create_bot(exist_session, bot_session, send_now=false)
        response = {}
        if exist_session["state"] == nil
          message = "masukkan username bot anda,\n#{Bot.message("format_username")}"
          exist_session["state"] = "fill_username"

        elsif exist_session["state"] == "fill_username"
          exist_session["params"]["username"] = "#{params[:message][:text]}_bot"
          response = Bot.check_username(exist_session["params"])
          message = response[:message]
          send_now = response[:send_now]
          exist_session["state"] = "fill_fullname"

        elsif exist_session["state"] == "fill_fullname"
          exist_session["params"]["fullname"] = params[:message][:text]
          message = "masukkan password bot anda\n#{Bot.message("format_password")}"
          exist_session["state"] = "fill_password"

        elsif exist_session["state"] == "fill_password"
          exist_session["params"]["password"] = params[:message][:text]
          response = Bot.check_password_format(params[:message][:text])
          message = response[:message]
          send_now = response[:send_now]
          exist_session["state"] = "fill_confirm_password"

        elsif exist_session["state"] == "fill_confirm_password"
          if exist_session["params"]["password"] == params[:message][:text]
            message = "masukkan deskripsi bot anda"
            exist_session["state"] = "fill_description"
          else
            message = "konfirmasi password salah harap ulangi"
          end

        elsif exist_session["state"] == "fill_description"
          exist_session["params"]["avatar_url"] = "www.google.com"
          exist_session["params"]["description"] = params[:message][:text]
          exist_session["state"] = "fill_avatar_url"
          message = "unggah gambar profile bot"
          
        elsif exist_session["state"] == "fill_avatar_url"
          exist_session["params"]["user_id_creator"] = params[:from][:id]
          exist_session["params"]["qiscus_token"] = params[:token]
          exist_session["params"]["application_id"] = params[:chat_room][:application_id]
          exist_session["params"]["avatar_url"] = params[:message][:payload][:url]
          if !exist_session["params"]["avatar_url"].nil?
            bot = Bot.create_profile(exist_session["params"], params[:from][:id])
            message = bot[:message]
            response[:buttons] = ""
            response[:type] = "text"
            $redis.del(bot_session)
            send_now = true
          else
            message = "file gambar tidak sesuai, harap ulangi!"
            send_now = true
          end
        end
        response[:exist_session] = exist_session
        response[:send_now] = send_now
        response[:message] = message
        return response
      end

      def edit_bot(exist_session, bot_session, send_now=false)
        response = {}
        if exist_session["state"] == nil
          bot = Bot.where(user_id_creator: params[:from][:id])
          user_ids = User.where(id: bot.pluck(:user_id), deleted: false).pluck(:id)
          usernames = bot.where(user_id: user_ids).pluck(:username).push("/batal")
          message = "#{Bot.message("list")} :"
          response[:buttons] = {buttons: Bot.create_buttons({buttons: usernames})}        
          exist_session["state"] = "fill_username"

        elsif exist_session["state"] == "fill_username"
          username = "#{params[:message][:text]}"
          params_bot = {username: params[:message][:text], user_id_creator: params[:from][:id]}
          response = Bot.select_bot(params_bot)
          exist_session["params"] = {}
          exist_session["params"]["user"] = response[:user]
          exist_session["params"]["bot"] = response[:bot] 

          if !response[:user].nil?
            params_token = {}
            params_token[:user_id] = response[:user].id
            access_token = Bot.get_token(params_token)
            webhook = response[:user].callback_url
            if webhook == ""
              webhook = "empty"
            end
            message = "#{response[:message]}, \nusername : #{response[:bot].username}\nfullname : #{response[:user].fullname} \ndescription : #{response[:user].description}\nwebhook: #{webhook}\naccess_token : #{access_token}"
            buttons = ["/edit_fullname", "/edit_password", "/edit_access_token", "/edit_description", "/edit_webhook", "/edit_photo", "/batal"]
            buttons = Bot.create_buttons({buttons: buttons})
            response[:type] = "card"
            response[:buttons] = {
              "text": message,
              "image": response[:user].avatar_url,
              "title": response[:bot].username,
              "description": response[:user].description,
              "url": response[:user].avatar_url,
              "buttons": buttons
            }        
          else
            message = "bot tidak ditemukan mohon gunakan username lain"
            send_now = true
          end
          exist_session["state"] = "editable_bot"
          
        elsif exist_session["state"] == "editable_bot"
          if params[:message][:text] == "/edit_fullname"
            message = "masukkan fullname baru"
            exist_session["editable_bot"] = "fullname"
          elsif params[:message][:text] == "/edit_password"
            message = "masukkan password baru\n#{Bot.message("format_password")}"
            exist_session["editable_bot"] = "password"
          elsif params[:message][:text] == "/edit_access_token"
            message = "anda yakin akan ubah access_token?"
            response[:buttons] = {buttons: Bot.create_buttons({buttons: ["ya", "tidak", "/batal"]})}
            exist_session["editable_bot"] = "confirm_access_token"
          elsif params[:message][:text] == "/edit_description"
            message = "masukkan deskripsi baru"
            exist_session["editable_bot"] = "description"
          elsif params[:message][:text] == "/edit_webhook"
            message = "masukkan webhook baru dengan menyertakan http:// atau https://"
            exist_session["editable_bot"] = "webhook"
          elsif params[:message][:text] == "/edit_photo"
            message = Bot.message("upload")
            exist_session["editable_bot"] = "photo"
          elsif params[:message][:text] == "/exit"
            message = "anda keluar dari fitur edit"
            $redis.del(bot_session)
            send_now = true

          elsif exist_session["editable_bot"] == "photo"
            exist_session["params"]["user_id_creator"] = params[:from][:id]
            exist_session["params"]["qiscus_token"] = params[:token]
            exist_session["params"]["application_id"] = params[:chat_room][:application_id]
            attributes = {:"avatar_url" => params[:message][:payload][:url]}
            exist_session["params"]["user"]["id"]
            user = {:"id" => exist_session["params"]["user"]["id"]}
            if !params[:message][:payload][:url].nil?
              message = Bot.update_user(user, attributes)
              response[:buttons] = ""
              response[:type] = "text"
              $redis.del(bot_session)
              send_now = true
            else
              message = "file gambar tidak sesuai, harap ulangi!"
              send_now = true
            end

          elsif exist_session["editable_bot"] == "fullname"
            exist_session["params"]["new_fullname"] = params[:message][:text]
            message = Bot.message("determination")
            response[:buttons] = {buttons: Bot.create_buttons({buttons: ["ya", "tidak", "/batal"]})}  
            exist_session["editable_bot"] = "confirm_fullname"
          elsif exist_session["editable_bot"] == "confirm_fullname"
            if params[:message][:text] == "ya"
              bot_params = exist_session["params"]
              fullname = exist_session["params"]["new_fullname"]
              fullname_params = {fullname: fullname}
              user = {id: bot_params["user"]["id"]}
              message = Bot.update_user(user, fullname_params)
              exist_session["editable_bot"] = ""
              response[:type] = "text"
              send_now = true
              $redis.del(bot_session)
            elsif params[:message][:text] == "tidak"
              message = "silahkan ganti fullname lain, ketik /batal untuk batal"
              exist_session["editable_bot"] = "fullname"
            end


          elsif exist_session["editable_bot"] == "description"
            exist_session["params"]["new_description"] = params[:message][:text]
            message = Bot.message("determination")
            response[:buttons] = {buttons: Bot.create_buttons({buttons: ["ya", "tidak", "/batal"]})}  
            exist_session["editable_bot"] = "confirm_description"
          elsif exist_session["editable_bot"] == "confirm_description"
            if params[:message][:text] == "ya"
              bot_params = exist_session["params"]
              description = exist_session["params"]["new_description"]
              description_params = {description: description}
              user = {id: bot_params["user"]["id"]}
              message = Bot.update_user(user, description_params)
              exist_session["editable_bot"] = ""
              response[:type] = "text"
              send_now = true
              $redis.del(bot_session)
            elsif params[:message][:text] == "tidak"
              message = "silahkan ganti description lain, ketik /batal untuk batal"
              exist_session["editable_bot"] = "description"
            end

          elsif exist_session["editable_bot"] == "webhook"
            begin
              uri = URI.parse(params[:message][:text])
              resp = uri.kind_of?(URI::HTTP)
            rescue URI::InvalidURIError
              resp = false
            end
            if resp == false
              message = "url anda tidak valid, mohon tulis ulang url dengan menyertakan http:// atau https://"
              send_now = true
            else
              exist_session["params"]["new_webhook"] = params[:message][:text]
              message = Bot.message("determination")
              response[:buttons] = {buttons: Bot.create_buttons({buttons: ["ya", "tidak", "/batal"]})}
              exist_session["editable_bot"] = "confirm_webhook"
            end
          elsif exist_session["editable_bot"] == "confirm_webhook"
            if params[:message][:text] == "ya"
              bot_params = exist_session["params"]
              webhook = exist_session["params"]["new_webhook"]
              webhook_params = {callback_url: webhook}
              user = {id: bot_params["user"]["id"]}
              message = Bot.update_user(user, webhook_params)
              exist_session["editable_bot"] = ""
              response[:type] = "text"
              send_now = true
              $redis.del(bot_session)
            elsif params[:message][:text] == "tidak"
              message = "silahkan ganti webhook lain, ketik /batal untuk batal"
              exist_session["editable_bot"] = "webhook"
            end
            
          elsif exist_session["editable_bot"] == "password"
            exist_session["params"]["new_password"] = params[:message][:text]
            response = Bot.check_password_format(params[:message][:text])
            message = response[:message]
            send_now = response[:send_now]
            exist_session["editable_bot"] = "confirm_password"

          elsif exist_session["editable_bot"] == "confirm_password"
            if exist_session["params"]["new_password"] == params[:message][:text]
              message = Bot.message("determination")
              response[:buttons] = {buttons: Bot.create_buttons({buttons: ["ya", "tidak", "/batal"]})}
              exist_session["editable_bot"] = "confirmed_password"
            else
              message = "konfirmasi password salah, silahkan tulis ulang!"
              send_now = true
            end
            
          elsif exist_session["editable_bot"] == "confirmed_password"
            if params[:message][:text] == "ya"
              bot_params = exist_session["params"]
              password = exist_session["params"]["new_password"]
              password_params = {password: password}
              user = {user_id: bot_params["user"]["id"]}
              message = Bot.update_bot(user, password_params)
              exist_session["editable_bot"] = ""
              response[:type] = "text"
              send_now = true
              $redis.del(bot_session)
            elsif params[:message][:text] == "tidak"
              message = "silahkan ganti password lain, ketik /batal untuk batal"
              exist_session["editable_bot"] = "password"
            end  

          elsif exist_session["editable_bot"] == "confirm_access_token"
            if params[:message][:text] == "ya"
              bot_params = exist_session["params"]
              user_id = bot_params["user"]["id"]
              token = Bot.create_token(user_id)
              if token != "failed create token, user not found"
                message = "token baru anda : \n#{token} "
                response[:type] = "text"
                send_now = true
                $redis.del(bot_session)
              else
                message = "token gagal dibuat!"
              end
              exist_session["editable_bot"] = ""
            elsif params[:message][:text] == "tidak"
              message = "edit access_token dibatalkan"
              $redis.del(bot_session)
              send_now = true
            end
          end     
        end
        response[:exist_session] = exist_session
        response[:send_now] = send_now
        response[:message] = message
        return response
      end

      def list_bot(params)
        response = {}
        bot = Bot.where(user_id_creator: params[:from][:id])
        user_ids = User.where(id: bot.pluck(:user_id), deleted: false).pluck(:id)
        usernames = bot.where(user_id: user_ids).pluck(:username).push("/batal")
        response[:message] = "#{Bot.message("list")} :"
        response[:buttons] = Bot.create_buttons({buttons: usernames})
        return response
      end

      def show_bot(exist_session, bot_session, send_now=false)
        response = {}
        if exist_session["state"] == nil
          message = "masukkan username bot anda"
          exist_session["state"] = "fill_username"

        elsif exist_session["state"] == "fill_username"
          params_bot = {username: params[:message][:text], user_id_creator: params[:from][:id]}
          response = Bot.select_bot(params_bot)
          if !response[:user].nil?
            params_token = {}
            params_token[:user_id] = response[:user].id
            access_token = Bot.get_token(params_token)
            webhook = response[:user].callback_url
            if webhook == ""
              webhook = "empty"
            end
            $redis.del(bot_session)
            response[:type] = "card"
            message = "#{response[:message]}, \nusername : #{response[:bot].username}\nfullname : #{response[:user].fullname} \ndescription : #{response[:user].description}\nwebhook: #{webhook}\naccess_token : #{access_token}"
            response[:payload] = {
                "text": message,
                "image": response[:user].avatar_url,
                "title": response[:bot].username,
                "description": response[:user].description,
                "url": response[:user].avatar_url,
                "buttons": [
                ]
              }
          else
            message = "bot tidak ditemukan mohon tulis username lain,\n(ketik /batal untuk batal)"
          end
          send_now = true
        end
        response[:exist_session] = exist_session
        response[:send_now] = send_now
        response[:message] = message
        return response
      end

      def delete_bot(exist_session, bot_session, params, send_now=false)
        response = {}

        if exist_session["state"] == nil
          message = "pilih bot untuk dihapus"
          list_bot = list_bot(params)
          response[:buttons] = list_bot[:buttons]
          exist_session["state"] = "select_bot"

        elsif exist_session["state"] == "select_bot"
          exist_session["params"]["username"] = params[:message][:text]
          bot = Bot.where(username: exist_session["params"]["username"], user_id_creator: params[:from][:id]).first
          user = nil
          if !bot.nil?
              user = User.where(id: bot.user_id, deleted: false).first
          end
          if !user.nil?
            message = "apakah anda yakin untuk hapus bot #{params[:message][:text]}?"
            response[:buttons] = Bot.create_buttons({:buttons => ["ya", "/batal"]})
          else
            message = "bot tidak ditemukan, harap tulis username yang terdaftar"
            send_now = true
          end
          exist_session["state"] = "confirmation"

        elsif exist_session["state"] == "confirmation"
          if params[:message][:text] == "ya"
            response = Bot.delete_bot(exist_session["params"]["username"], params[:from][:id], bot_session)
            message = response[:message]
            response[:type] = "text"
            send_now = response[:send_now]
          elsif params[:message][:text] == "tidak"
            $redis.del(bot_session)
          else
            message = Bot.message("unknown")
            send_now = true
          end
        end
        response[:buttons] = response[:buttons] || [Bot.create_button({:label => "/batal"})]
        response[:exist_session] = exist_session
        response[:send_now] = send_now
        response[:message] = message
        return response
      end

      bot_session = "#{params[:from][:qiscus_email]}"
      exist_session = $redis.get(bot_session)
      send_now = false
      
      if exist_session.nil?
        payload = {}
        payload["params"] = {}
        $redis.set(bot_session, payload.to_json)
        $redis.expire(bot_session, SessionLength)
      end

      exist_session = JSON.parse($redis.get(bot_session)) 

      #commands message input
      if send_now == false
        if exist_session["command"] == nil
          if params[:message][:text] == "/createbot"
            exist_session["command"] = "create bot"

          elsif params[:message][:text] == "/editbot"
            exist_session["command"] = "edit bot"

          elsif params[:message][:text] == "/deletebot"
            exist_session["command"] = "delete bot"

          elsif params[:message][:text] == "/listbot"
            response = list_bot(params)
            content = {"buttons"=>response[:buttons]}
            message = response[:message]
            type = "buttons"
            exist_session["command"] = "show bot"
            exist_session["state"] = "fill_username"
            $redis.set(bot_session, exist_session.to_json)
            $redis.expire(bot_session, SessionLength)
            send_now = true

          elsif params[:message][:text] == "/showbot"
            exist_session["command"] = "show bot"

          elsif params[:message][:text] == "/editbot"
            exist_session["command"] = "edit bot"
          end
        end
      end

      #help and cancel
      if send_now == false
        if params[:message][:text] == "/bantuan"
          message = "berikut perintah yang tersedia :"
          menu = ["/createbot", "/editbot", "/listbot", "/deletebot"]
          content = {:"buttons" => Bot.create_buttons({buttons: menu})}
          type = "buttons"
          send_now = true
        elsif params[:message][:text] == "/batal"
          $redis.del(bot_session)
          exist_session = nil
          send_now = true
          message = "permintaan dibatalkan."
        end
      end

      #commands CRUD
      if send_now == false
        if exist_session["command"] == "create bot"
          response = create_bot(exist_session, bot_session, send_now)
          send_now = response[:send_now]
          message = response[:message]
          exist_session = response[:exist_session]
          content = response[:buttons] || {:"buttons" => Bot.create_buttons({buttons: ["/batal"]})}
          type = response[:type] || "buttons"
          if send_now == false
            $redis.set(bot_session, exist_session.to_json)
            $redis.expire(bot_session, SessionLength)
          end
        elsif exist_session["command"] == "delete bot"
          response = delete_bot(exist_session, bot_session, params, send_now)
          send_now = response[:send_now]
          message = response[:message]
          content = {"buttons" => response[:buttons]}
          exist_session = response[:exist_session]
          type = response[:type] || "buttons"
          if send_now == false
            $redis.set(bot_session, exist_session.to_json)
            $redis.expire(bot_session, SessionLength)
          end
        elsif exist_session["command"] == "show bot"
          response = show_bot(exist_session, bot_session)
          send_now = response[:send_now]
          message = response[:message]
          type = response[:type] || "text"
          content = response[:payload] || ""
          exist_session = response[:exist_session]
          if send_now == false
            $redis.set(bot_session, exist_session.to_json)
            $redis.expire(bot_session, SessionLength)
          end
        elsif exist_session["command"] == "edit bot"
          response = edit_bot(exist_session, bot_session)
          send_now = response[:send_now]
          message = response[:message]
          exist_session = response[:exist_session]
          content = response[:buttons] || {:"buttons" => Bot.create_buttons({buttons: ["/batal"]})}
          type = response[:type] || "buttons"
          if send_now == false
            $redis.set(bot_session, exist_session.to_json)
            $redis.expire(bot_session, SessionLength)
          end
        end
      end

      if message.nil?
        message = Bot.message("unknown")
        if exist_session["command"].present?
          message = message+ ".\nanda sedang dalam proses "+ exist_session["command"]+".\nketik /batal untuk membatalkan proses"
        end
        type = "buttons"
        content = {"buttons" => [Bot.create_button({:label => "/bantuan"})]}
      end

      application = Application.where(id: params[:chat_room][:application_id]).first
      if !application.nil?
        app_id = application.app_id
        qiscus_sdk_secret = application.qiscus_sdk_secret
      else
        raise InputError.new("application is invalid!")
      end
      qiscus_sdk = QiscusSdk.new(app_id, qiscus_sdk_secret)

      account = User.where(id: params[:my_account][:id]).first
      if !account.nil?
        qiscus_token = account.qiscus_token
      else
        raise InputError.new("qiscus_token is invalid!")
      end
      topic_id = params[:chat_room][:qiscus_room_id]
      comment = message
      type =  type || "text"
      content = content.to_json || "".to_json
      comments = qiscus_sdk.post_comment(qiscus_token, topic_id, comment, type, content)

      render json: {
        success: true,
        message: comments
      }
    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

end