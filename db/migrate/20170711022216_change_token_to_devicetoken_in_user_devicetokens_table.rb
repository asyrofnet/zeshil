class ChangeTokenToDevicetokenInUserDevicetokensTable < ActiveRecord::Migration[5.1]
  def change
    rename_column :user_devicetokens, :token, :devicetoken
  end
end
