class ProviderSetting < ActiveRecord::Base
  validates :attempt, presence: true
  belongs_to :application
  belongs_to :provider

  def as_json(options = {})
    h = super(
      :include => [
      ],

      :except => [:application_id, :provider_id]
    )

    return h
  end

  # For initialization, insert provider setting data into existing application
  def self.insert_provider_setting_data_into_existing_application
    applications = Application.all # get all applications
    new_provider_settings = Array.new
    provider_id = Provider.first.id # set first provider as default provider

    applications.each do | a |
      for attempt in 0..2 # qisme-engine has 3 attempt verification
        new_provider_settings.push({:attempt => attempt, :provider_id => provider_id, :application_id => a.id})
      end
    end

    # add new provider settings
    ProviderSetting.create(new_provider_settings)
  end

  def self.insert_provider_setting_data_into_spesific_application(application_id)
    new_provider_settings = Array.new
    provider_id = Provider.first.id # set first provider as default provider

    for attempt in 0..2 # qisme-engine has 3 attempt verification
      new_provider_settings.push({:attempt => attempt, :provider_id => provider_id, :application_id => application_id})
    end

    # add new provider settings
    ProviderSetting.create(new_provider_settings)
  end
end