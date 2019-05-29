require 'csv'
require 'securerandom'

class User < ActiveRecord::Base

  # Validator
  # validates :phone_number, presence: true # change since phone number is null able
  validates :fullname, length: { minimum: 4}, allow_nil: true, allow_blank: false, spaces_only: true
  # the default value
  validates :email, length: { minimum: 1}, email: true, allow_nil: true, allow_blank: true
  validates :qiscus_email, email: true, presence: true # email registered to Qiscus SDK
  # validates :phone_number, phony_plausible: { with: /\A\+\d+/ }, allow_nil: true, allow_blank: true
  validates :phone_number, presence: true, allow_nil: true, allow_blank: true
  # phony_normalize :phone_number
  # validates_plausible_phone :phone_number, with: /\A\+\d+/
  enum gender: [ :male, :female ]
  validates :is_public, inclusion: { in: [ true, false, "true", "false"] }
  validates :callback_url, url: true, allow_nil: true, allow_blank: true

  # Relation info
  belongs_to :application
  has_many :user_roles
  has_many :roles, through: :user_roles

  has_many :contacts
  has_many :users, through: :contacts

  has_many :chat_users
  has_many :chat_rooms, through: :chat_users

  has_many :auth_sessions

  has_many :posts

  has_many :user_features
  has_many :features, through: :user_features

  has_many :user_device_tokens

  has_many :pin_chat_rooms
  has_many :mute_chat_rooms

  has_many :likes
  has_many :post_history, class_name: "PostHistory"

  has_many :user_additional_infos

  has_many :call_logs

  has_one :user_dedicated_passcodes
  has_one :bot

  # Hooks
  before_validation :strip_spaces
  # before_save :update_sdk_profile

  # Update redis cache after create, update and delete
  # after save hooks will called both when Creating or Updating an Object
  after_save :update_redis_cache
  after_destroy :update_redis_cache
  after_commit :auto_add_contact, on: :create

  default_scope { where(deleted: false) }

  def strip_spaces
    self.phone_number = (self.phone_number.nil? || self.phone_number == "") ? "" : self.phone_number.strip()
  end

  # additional attribute
  def is_admin
    self.roles.pluck(:name).include?('Admin')
  end

  def is_official
    self.roles.pluck(:name).include?('Official Account')
  end

  def is_helpdesk
    self.roles.pluck(:name).include?('Helpdesk')
  end

  def self.find_bot_id
    bot = Role.where(name: "Bot").first
    if bot.nil?
      bot_id = nil
    else
      bot_id = bot.id
    end
    return bot_id
  end

  def self.find_user_bot(user_ids, bot_id)
    user_bot = UserRole.where(user_id: user_ids, role_id: bot_id)
    if !user_bot.nil?
      user_bot = user_bot.pluck(:user_id)
    else
      user_bot = []
    end
    return user_bot
  end

  def is_bot
    self.roles.pluck(:name).include?('Bot')
  end

  def additional_infos
    additional_infos = Hash.new
    user_additional_infos.each do | user_additional_info |
      additional_infos[user_additional_info.key] = user_additional_info.value
    end
    return additional_infos
  end

  # static function
  def self.admin_import(file_path, application)
    imported = Array.new
    not_imported = Array.new
    reasons = Array.new

    csv = CSV.new(file_path, :headers => true, :encoding => 'iso-8859-1:utf-8')
    csv.each do |row|
      data = row.to_hash

      phone_number = data["phone_number"]
      phone_number = phone_number.strip().delete(' ')
      # phone_number = PhonyRails.normalize_number(phone_number, default_country_code: 'ID')

      email_sdk = data["phone_number"].tr('+', '').delete(' ')
      email_sdk = email_sdk.downcase.gsub(/[^a-z0-9_.]/i, "") # only get alphanumeric and _ and . string only
      email_sdk = email_sdk + "@" + application.app_id + ".com" # will build string like 085868xxxxxx@app_id.com

      params = {
        fullname: data["fullname"],
        phone_number: phone_number,
        email: data["email"],
        gender: data["gender"],
        date_of_birth: data["date_of_birth"],
        qiscus_email: email_sdk,
        application_id: application.id,
        qiscus_token: "qiscus_token"
      }

      begin
        user = User.create!(params)

        email_sdk = "userid_" + user.id.to_s + "_" + user.qiscus_email
        password = SecureRandom.hex # generate random password for security reason
        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        qiscus_token = qiscus_sdk.login_or_register_rest(email_sdk, password, email_sdk) # get qiscus token

        # this ensure qiscus email sdk to be unique
        user.update_attribute(:qiscus_email, email_sdk)
        user.update_attribute(:qiscus_token, qiscus_token)

        role = Role.member
        user_role = UserRole.new(user_id: user.id, role_id: role.id)
        user_role.save!

        imported.push(user)

      rescue ActiveRecord::RecordNotUnique => e
        not_imported.push(params)

        reason = Hash.new
        reason[:user] = params
        reason[:error_message] = "User with phone number '#{params[:phone_number]}' and application '#{application.app_id}' already exist"
        reasons.push(reason)
      rescue Exception => e
        not_imported.push(params)

        reason = Hash.new
        reason[:user] = params
        reason[:error_message] = e.message
        reasons.push(reason)
      end
    end

    response = OpenStruct.new(
    {
      :imported_total => imported.count,
      :not_imported_total => not_imported.count,
      :imported => imported,
      :not_imported => not_imported,
      :not_imported_reasons => reasons
    })

    return response.marshal_dump
  end

  # json manipulation
  def as_json(options={})
    h = super(
      # :include => [
      #   {
      #     :roles =>
      #     {
      #       :only => [:id, :name]
      #     }
      #   },
      #   {
      #     :application => { :only => [:app_name] }
      #   }
      # ],
      :except => [:passcode, :application_id, :qiscus_token, :lock_version],
      :methods => [ :is_admin, :is_official, :is_bot, :additional_infos ]
    )

    # Overwrite json if has key webhook. This json use only in webhook payload
    if options.has_key?(:webhook)
      h = super(
        :only => [:id, :phone_number, :fullname, :qiscus_email]
      )
    elsif options.has_key?(:job)
      h = super(
        :except => [:passcode, :application_id, :qiscus_token, :lock_version, :updated_at, :created_at],
        :methods => [ :is_admin, :is_official, :is_bot, :additional_infos ]
       )
      h["created_at"] = created_at.iso8601.to_s
      h["updated_at"] = updated_at.iso8601.to_s
    end

    # replace fullname using phone number or email if the fullname is empty
    # if fullname.nil? || fullname == ""
    #   if phone_number.nil? || phone_number == ""
    #     h["fullname"] = email
    #   else
    #     h["fullname"] = phone_number
    #   end
    # end

    # specification: Jika tidak ter-check berarti pengguna lain tidak bisa melihat email, gender, dan DOB.
    # Hanya bisa melihat nama, nomor telepon, dan avatar
    # if has not me keys then it is another user, so it need to be hide
    if options.has_key?(:show_profile)
      # override custom value for users email, gender and date_of_birth
      # hide this properties (just set it to empty string for consistent structure)
      if options[:show_profile] == false && h["is_public"] == false
        h["email"] = ""
        h["gender"] = ""
        h["date_of_birth"] = ""
      end
    end

    # too many query if using this approach
    if options.has_key?(:contact_of)
      contact_of = options[:contact_of]

      contact_user = Contact.find_by(user_id: contact_of["id"], contact_id: h["id"])
      if contact_user.nil? == false
        h["is_favored"] = contact_user["is_favored"]
      end
    end


    # h["is_admin"] = is_admin
    # h["is_official"] = is_official

    # h["additional_infos"] = Hash.new # default additional info key is empty object
    # user_additional_infos = UserAdditionalInfo::where(user_id: h["id"]).all
    # user_additional_infos.each do | user_additional_info |
    #   h["additional_infos"][user_additional_info.key] = user_additional_info.value
    # end

    return h
  end

  # as contact json must replace fullname to phone number or email if fullname is nil or empty string
  def as_contact_json(options={})
    h = as_json # this is method from this class

    # replace fullname using phone number or email if the fullname is empty
    if fullname.nil? || fullname == ""
      if phone_number.nil? || phone_number == ""
        h["fullname"] = email
      else
        h["fullname"] = phone_number
      end
    end

    return h
  end

  # Updating all fullname in SDK to fullname in backend.
  # This is to make name in SDK is same with data in backend (when load conversation list).
  # This should called once before after save and after update hooks implemented.
  def self.update_all_user_sdk_name
    users = User.all
    users.each do | u |
      password = SecureRandom.hex # generate random password for security reason
      qiscus_sdk = QiscusSdk.new(u.application.app_id, u.application.qiscus_sdk_secret)

      username = u.fullname
      # some user may not set their fullname, so use phone number
      if username.nil? || username == ""
        username = u.phone_number

        # but some user may register using email instead phone number, so try to use it in third try
        if username.nil? || username == ""
          username = u.email
        end
      end

      qiscus_sdk.login_or_register_rest(u.qiscus_email, password, username, u.avatar_url) # will return sdk token when success
    end
  end

  # Update all avatar_url since it change to https
  def self.update_all_avatar_url_to_https
    users = User.where('avatar_url LIKE ?', 'http://%')
    users.each do | u |
      old_avatar_url = u.avatar_url
      size = old_avatar_url.size
      raw_avatar_url = old_avatar_url[7...size]
      new_avatar_url = "https://" + raw_avatar_url;
      u.update_attribute(:avatar_url, new_avatar_url)
    end
  end

  # insert user country code, since country code store in  user
  def self.insert_user_country_code
    users = User.all
    users.each do |u|
      if u.secondary_phone_number != ""
        country_code = u.secondary_phone_number.to_s.slice(0..2)
      else
        country_code = u.phone_number.to_s.slice(0..2)
      end

      u.update_attribute(:country_code, country_code)
    end
  end

  # Update SDK profile if user change their fullname (sdk username) or avatar url
  def update_sdk_profile
    if saved_change_to_attribute?(:fullname) || saved_change_to_attribute(:avatar_url)
      # begin
        Rails.logger.debug "Update SDK profile"
        password = SecureRandom.hex # generate random password for security reason
        qiscus_sdk = QiscusSdk.new(application.app_id, application.qiscus_sdk_secret)
        qiscus_sdk.login_or_register_rest(qiscus_email, password, fullname, avatar_url) # get qiscus token
      # rescue Exception => e
      #   message = "Fail when call SDK in update user profile"
      #   Raven.capture_message(message,
      #     level: "error",
      #     extra: {
      #       message: e.message
      #     }
      #   )
      # end
    end
  end

  # because current avatar_url using transparent image
  def self.update_user_avatar_url
    transparent_avatar_url = "https://d1edrlpyc25xu0.cloudfront.net/kiwari-prod/image/upload/U6vHf34i6B/1510890598-ic_account_white_48dp.png"
    new_avatar_url = "https://d1edrlpyc25xu0.cloudfront.net/image/upload/t5XWp2PBRt/1510641299-default_user_avatar.png"

    users = User.where(avatar_url: transparent_avatar_url)
    users.each do | u |
      u.update_attribute(:avatar_url, new_avatar_url)

      qiscus_sdk = QiscusSdk.new(u.application.app_id, u.application.qiscus_sdk_secret)
      qiscus_sdk.update_profile(u.qiscus_email, u.fullname, u.avatar_url)
    end
  end

  # Delete and update redis cache for conversation list to make all data sync after update
  def update_redis_cache
    chat_room_ids = ChatUser.where(user_id: id).pluck(:chat_room_id)
    user_ids = ChatUser.where("chat_users.chat_room_id IN (?)", chat_room_ids).pluck(:user_id)
    user_ids = user_ids.uniq

    ChatRoomHelper.reset_chat_room_cache_for_users(user_ids)
  end

  # Background jobs to add contact automatically
  def auto_add_contact
    application = Application.find(application_id)

    if application.is_auto_friend == true
      users = application.users
      users = users.where.not(id: id) # exclude ownself to be added
      user_ids = users.pluck(:id)

      AutoAddContact.perform_later(user_ids, id)
    end
  end

  # Soft delete mechanism
  def destroy
    unless self.deleted?
      self.deleted = true
      self.deleted_at = Time.now
      if self.email.present?
        email_local_part = self.email.split("@")[0]
        email_domain = self.email.split("@")[1]
        self.email = email_local_part.concat("_deleted_#{Time.now.to_i}_@").concat(email_domain)
      end
      self.phone_number += "_deleted_#{Time.now.to_i}" if self.phone_number.present?
      self.save!
      update_redis_cache
    else
      raise Exception.new("Already deleted")
    end
  end

  def restore
    if self.deleted?
      self.deleted = false
      self.deleted_at = nil
      if self.email.present?
        email_local_part = self.email.split("@")[0]
        email_domain = self.email.split("@")[1]
        email_local_part = email_local_part.split("_deleted")[0]
        self.email = email_local_part.concat("@").concat(email_domain)
      end
      self.phone_number = self.phone_number.split("_deleted")[0] if self.phone_number.present?
      raise Exception.new("Another User already use same registration data") unless self.save
    else
      raise Exception.new("Already restored")
    end
  end

end