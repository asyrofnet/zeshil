class Provider < ActiveRecord::Base
  validates :provider_name, presence: true

  has_many :user_settings

  def self.twilio
    return Provider.find_or_create_by(provider_name: 'twilio')
  end

  def self.infobip
    return Provider.find_or_create_by(provider_name: 'infobip')
  end

  def self.nexmo
    return Provider.find_or_create_by(provider_name: 'nexmo')
  end

  def self.mainapi
    return Provider.find_or_create_by(provider_name: 'mainapi')
  end

end