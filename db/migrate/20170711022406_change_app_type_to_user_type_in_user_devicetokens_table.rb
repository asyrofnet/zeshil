class ChangeAppTypeToUserTypeInUserDevicetokensTable < ActiveRecord::Migration[5.1]
  def change
    rename_column :user_devicetokens, :app_type, :user_type
  end
end
