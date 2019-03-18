class AddSmsSenderInApplicationsTable < ActiveRecord::Migration[5.1]
  def change
    add_column :applications, :sms_sender, :string, null: true, default: ""
  end
end
