class Bot < ApplicationRecord
    has_one :user
    has_secure_password

    def self.check_username(params)
        username = params["username"]
        bot = Bot.where(username: username).first
        if bot.nil?
            payloads = {"message": "masukkan fullname bot anda", "send_now": false}
        else
            payloads = {"message": "username #{username} sudah terpakai!\n masukkan username lain!", "send_now": true}
        end
        return payloads
    end

    def self.check_password(params, password_digest)
        value = BCrypt::Engine.hash_secret(params[:password], password_digest) == password_digest
        return value
    end

    def self.create_bot(params)
        fullname = params["fullname"]
        username = params["username"]
        user_id_creator = params["user_id_creator"]
        password = params["password"]
        description = params["description"]
        qiscus_token = params["qiscus_token"]
        application_id = params["application_id"]
        avatar_url = params["avatar_url"]
        application = Application.where(id: application_id).first
        qiscus_email = "#{username}@#{application.app_id}.com"
        email = qiscus_email
        bot_phone_number = Bot.generate_bot_phone_number(12)
        phone_number = "bot#{bot_phone_number}"
        bot = Bot.where(username: username).first
        if bot.nil?
            user = User.new(fullname: fullname, description: description, qiscus_email: qiscus_email, application_id: application_id, qiscus_token: qiscus_token, phone_number: phone_number, email: email, avatar_url: avatar_url)
            if (user.save!)
                bot = Bot.new(username: username, user_id: user.id, user_id_creator: user_id_creator, password: password, description: description)
                if (bot.save!)
                    token = Bot.create_token(bot.user_id)
                    return "bot telah dibuat, \n token anda : #{token}"
                else
                    return "gagal menyimpan bot"
                end
            else
                return "gagal menyimpan bot"
            end
        else
            return "username sudah terpakai!, harap masukkan username lain"
        end
    end

    def self.generate_bot_phone_number(digits=12)
        numbers = [0,1,2,3,4,5,6,7,8,9]
        bot_phone_number = []
        digit_loop = digits
        while digit_loop > 0
            bot_phone_number = bot_phone_number.push(numbers.shuffle.first)
            digit_loop = digit_loop - 1
            if digit_loop == 0
                bot_phone_number = bot_phone_number.join("")
                user = User.where(phone_number: "bot#{bot_phone_number}").first
                if !user.nil?
                    digit_loop = digits
                    bot_phone_number = []
                end
            end
        end
        return bot_phone_number
    end

    def self.show_all(params)
        user_ids = Bot.pluck(:user_id)
        users = User.where(id: user_ids, deleted: false)
        if users.nil?
            return "successfully show all users"
        else
            return "failed show all users"
        end        
    end  

    def self.create_token(params)
        user = User.find(params)
        if !user.nil?
            jwt = ApplicationHelper.create_jwt_token(user)
            return jwt
        else
            return "failed create token, user not found"
        end        
    end

    def self.get_token(params)
        access_token = AuthSession.where(params).last
        if !access_token.nil?
            access_token = access_token.jwt_token
        else
            access_token = "empty"
        end
        return access_token
    end

    def self.delete_bot(username, user_id_creator, bot_session)
        bot = Bot.where(username: username, user_id_creator: user_id_creator).first
        user = nil
        if !bot.nil?
            user = User.where(id: bot.user_id, deleted: false).first
        end
        if !user.nil?
            user.update_attributes!(deleted: true)
            message = "bot berhasil dihapus"
            $redis.del(bot_session)
            send_now = true
        else
            message = "bot tidak ditemukan"
            send_now = true
        end
        response = {}
        response[:message] = message
        response[:send_now] = send_now
        return response
    end

    def self.select_bot(params)
        response = {}
        bot = Bot.where(params).first
        if !bot.nil?
            user = User.where(id: bot.user_id, deleted: false).first
        else
            user = nil
        end
        if !user.nil?
            response[:bot] = bot
            response[:user] = user
            response[:message] = "bot ditemukan"
        else
            response[:message] = "bot tidak ditemukan"
        end
        return response
    end

    def self.update_bot(user, attributes)
        bot = Bot.where(user).first
        bot.update_attributes!(attributes)
        return "edit berhasil"
    end

    def self.update_user(user, attributes)
        user = User.where(user).first
        user.update_attributes!(attributes)
        return "edit berhasil!"
    end

    def self.message(type="unknown")
        message = ""
        if type == "list"
            message = "pilih bot anda"
        elsif type == "tidak"
            message = "silahkan tulis ulang"
        elsif type == "cancel"
            message = "tekan /cancel untuk membatalkan proses"
        elsif type == "unknown"
            message = "permintaan tidak diketahui"
        elsif type == "determination"
            message = "apakah anda yakin?"
        elsif type == "upload"
            message = "silahkan unggah foto baru"
        end
        return message
    end

    def self.create_buttons(params)
        buttons = []
        params[:buttons].each do |username|
            buttons.push({
                "label": username,
                "type": "postback",
                "payload": {
                    "url": "www.kiwari.chat",
                    "method": "get",
                    "payload": nil
                }
            })
        end
        return buttons
    end

    def self.create_button(params)
            button = {
                "label": params[:label],
                "type": "postback",
                "postback_text": params[:postback_text],
                "payload": {
                    "url": params[:url] || "https://www.kiwari.chat",
                    "method": "get",
                    "payload": nil
                }
            }
        return button
    end
end
