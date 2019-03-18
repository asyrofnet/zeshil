class AddIsSendMessagePnInApplicationsTable < ActiveRecord::Migration[5.1]
  def change
    add_column :applications, :is_send_message_pn, :boolean, default: false
  end
end
