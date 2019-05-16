class Bot < ApplicationRecord
    has_one :user
    has_secure_password

    def self.lowercase
        lowercase = "abcdefghijklmnopqrstuvwxyz".split("")
        return lowercase
    end

    def self.numbers
        numbers = "0123456789".split("")
        return numbers
    end

    def self.symbols
        symbols = "_.".split("")
        return symbols
    end

    def self.check_username(params)
        response = {}
        username = params["username"] || "nil"

        if ((username.split("") - Bot.lowercase - Bot.numbers - Bot.symbols) == []) && (username.split("").length >= 9)
            bot = Bot.where(username: username).first
            if bot.nil?
                response = {"message": "masukkan fullname bot anda", "send_now": false}
            else
                response = {"message": "username #{username} sudah terpakai!\nmasukkan username lain!", "send_now": true}
            end
        else
            response[:message] = "format username salah!\nharap ulangi.\n#{Bot.message("format_username")}"
            response[:send_now] = true
        end
        return response
    end

    def self.check_password_format(password)
        response = {}
        if (password.include? " ") || (password.length < 5)
            response[:send_now] = true
            response[:message] = "format password salah!\nharap ulangi.\n#{Bot.message("format_password")}"
        else
            response[:send_now] = false
            response[:message] = "masukkan konfirmasi password bot anda"
        end
        return response
    end

    def self.check_password(params, password_digest)
        value = BCrypt::Engine.hash_secret(params[:password], password_digest) == password_digest
        return value
    end

    def self.create_bot(params)
        response = {}
        fullname = params["fullname"]
        username = params["username"]
        user_id_creator = params["user_id_creator"]
        password = params["password"]
        description = params["description"]
        qiscus_token = params["qiscus_token"]
        application_id = params["application_id"]
        avatar_url = params["avatar_url"]
        application = Application.where(id: application_id).first
        bot_phone_number = Bot.generate_bot_phone_number(12)
        qiscus_email = "627872#{bot_phone_number}@#{application.app_id}.com"
        phone_number = "+627872#{bot_phone_number}"
        email = "#{username}@#{application.app_id}.com"        

        bot = Bot.where(username: username).first
        if bot.nil?
            user = User.new(fullname: fullname, description: description, qiscus_email: qiscus_email, application_id: application_id, qiscus_token: qiscus_token, phone_number: phone_number, email: email, avatar_url: avatar_url)
            Bot.transaction do
                user.save!
                response[:user_save_success] = true
            end
            if response[:user_save_success] == true
                qiscus_email = "userid_#{user.id}_627872#{bot_phone_number}@#{application.app_id}.com"
                qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
                qiscus_token = qiscus_sdk.login_or_register_rest(qiscus_email, password, user.fullname, avatar_url)
                user.update_attributes!(qiscus_email: qiscus_email, qiscus_token: qiscus_token)
                bot = Bot.new(username: username, user_id: user.id, user_id_creator: user_id_creator, password: password, description: description)
                Bot.transaction do
                    bot.save!
                    response[:bot_save_success] = true
                end
                if response[:bot_save_success] == true
                    token = Bot.create_token(bot.user_id)
                    response[:message] = "bot telah dibuat, \ntoken anda : \n#{token}"
                    response[:bot] = bot
                    response[:user] = user
                else
                    Bot.hard_delete(user)
                    response[:message] = "gagal menyimpan bot"
                end
            else
                response[:message] = "gagal menyimpan bot"
            end
        else
            response[:message] = "username sudah terpakai!, harap masukkan username lain"
        end
        return response
    end

    def self.hard_delete(table)
        table.delete
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
                user = User.where(phone_number: "+627872#{bot_phone_number}").first
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
            bot.destroy
            user = User.where(id: bot.user_id, deleted: false).first
        end
        if !user.nil?
            user.destroy
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
        qiscus_sdk = QiscusSdk.new(user.application.app_id, user.application.qiscus_sdk_secret)
        qiscus_token = qiscus_sdk.update_profile(user.qiscus_email, user.fullname, user.avatar_url)
        user.update_attributes!(qiscus_token: qiscus_token)
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
        elsif type == "format_username"
            message = "username hanya boleh berisikan :\n- huruf kecil\n- angka\n- underscore (_)\n- titik (.) \n- tanpa menggunakan spasi\n- minimal 5 digit"
        elsif type == "format_password"
            message = "- password minimal 5 digit\n- tanpa menggunakan spasi"
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

    def self.create_contact(user1_id, user2_id)
        response = {}
        contact1 = Contact.new(user_id: user1_id, contact_id: user2_id)
        contact2 = Contact.new(user_id: user2_id, contact_id: user1_id)
        Contact.transaction do
            contact1.save!
            contact2.save!
            response[:message] = "berhasil menyimpan kontak"
            response[:success] = true
        end
        return response
    end

    def self.create_bot_role(bot_user_id)
        response = {}
        role = Role.where(name: "Bot").first
        if role.nil?
            role = Role.create!(name: "Bot")
        end
        role = UserRole.new(user_id: bot_user_id, role_id: role.id)
        if role.save!
            response[:success] = true
        end
        return response
    end

    def self.create_profile(params, user2_id)
        response = {}
        bot = Bot.create_bot(params)
        if !bot[:bot].nil?
            user1_id = bot[:user].id
            contact = Bot.create_contact(user1_id, user2_id)
            if contact[:success] == true
                role = Bot.create_bot_role(bot[:user].id)
                if role[:success] == true
                    response[:message] = bot[:message]
                end
            end
        end
        response[:message] = response[:message] || "bot gagal dibuat!"
        return response
    end

    def destroy
        self.username = "userid_" + self.id.to_s + "_" + self.username + "_deleted_#{Time.now.to_i}"
        self.save
    end
end
