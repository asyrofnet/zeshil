class AddApnsCertDevApnsCertProdApnsCertPasswordInApplicationsTable < ActiveRecord::Migration[5.1]
  def change
    add_column :applications, :apns_cert_dev, :string, null: true, default: ""
    add_column :applications, :apns_cert_prod, :string, null: true, default: ""
    add_column :applications, :apns_cert_password, :string, null: true, default: ""
  end
end
