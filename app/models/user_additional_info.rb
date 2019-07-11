class UserAdditionalInfo < ActiveRecord::Base
  validates :user_id, presence: true
  validates :key, presence: true
  validates :value, presence: true

  belongs_to :user

  default_scope { joins(:user)}

  SUBSCRIBER_KEY = "subscriber"
  IS_CHANNEL_KEY = "is_channel"
  USERNAME_KEY = "username"
  INVITE_URL_KEY = "invite_url"
  INVITE_URL_BEGINNING = "link.kiwari.chat/"

  AUTO_RESPONDER_KEY = "auto_responder"
  AUTO_STARTER_KEY = "auto_starter"

  # Create user additional info
  def self.create_or_update_user_additional_info(user_ids, additional_info_key, additional_info_value)
    users = User.where("id IN (?)", user_ids)
    users.each do | u |
      user_additional_info = UserAdditionalInfo.find_by(key: additional_info_key, user_id: u.id)

      if user_additional_info.nil?
        # create when value not exist
        user_additional_info = UserAdditionalInfo.new
        user_additional_info.key = additional_info_key
        user_additional_info.value = additional_info_value
        user_additional_info.user_id = u.id
        user_additional_info.save
      else
        # update when value was exist
        user_additional_info.update_attribute(:value, additional_info_value)
      end
    end
  end

  def self.check_username(username="nil", leng=5)
    response = {}
    if ((username.split("") - Bot.lowercase - Bot.numbers - Bot.symbols) == []) && (username.split("").length >= leng)
      additional_info = UserAdditionalInfo.where(key: UserAdditionalInfo::USERNAME_KEY, value: username).first
      if additional_info.nil?
        response[:success] = true
      end
    end
    return response
  end

end
