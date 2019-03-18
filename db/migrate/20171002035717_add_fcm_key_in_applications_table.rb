class AddFcmKeyInApplicationsTable < ActiveRecord::Migration[5.1]
  def change
		add_column :applications, :fcm_key, :string, null: true, default: ""
  end
end
