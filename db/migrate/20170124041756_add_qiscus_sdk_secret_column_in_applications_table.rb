class AddQiscusSdkSecretColumnInApplicationsTable < ActiveRecord::Migration[5.0]
  def change
    add_column :applications, :qiscus_sdk_secret, :string, null: false, default: ""
  end
end
