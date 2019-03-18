class Application < ActiveRecord::Base
  validates :app_id, presence: true, uniqueness: { case_sensitive: false }
  validates :app_name, presence: true
  validates :qiscus_sdk_url, presence: true
  validates :qiscus_sdk_secret, presence: true

  has_many :users
  has_many :announcements
  has_many :features
  has_many :provider_settings
  has_many :custom_menus
  has_many :call_logs

  def save_and_add_provider_setting_data(application)
    application.save!
    add_provider_setting_data
  end

  def add_provider_setting_data
    ProviderSetting.insert_provider_setting_data_into_spesific_application(id)
  end
end
