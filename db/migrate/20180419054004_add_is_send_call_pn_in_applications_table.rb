class AddIsSendCallPnInApplicationsTable < ActiveRecord::Migration[5.1]
  def change
    add_column :applications, :is_send_call_pn, :boolean, default: false
  end
end
