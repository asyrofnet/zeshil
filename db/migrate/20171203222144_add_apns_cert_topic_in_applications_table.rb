class AddApnsCertTopicInApplicationsTable < ActiveRecord::Migration[5.1]
  def change
    add_column :applications, :apns_cert_topic, :string, null: true, default: ""
  end
end
