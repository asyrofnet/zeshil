class RenameUserTokensToUserDevicetokensTable < ActiveRecord::Migration[5.1]
  def change
  	rename_table :user_tokens, :user_devicetokens
  end
end
