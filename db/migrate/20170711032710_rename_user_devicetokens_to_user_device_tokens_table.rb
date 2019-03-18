class RenameUserDevicetokensToUserDeviceTokensTable < ActiveRecord::Migration[5.1]
  def change
  	rename_table :user_devicetokens, :user_device_tokens
  end
end
