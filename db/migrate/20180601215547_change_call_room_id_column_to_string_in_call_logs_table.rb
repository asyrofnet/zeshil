class ChangeCallRoomIdColumnToStringInCallLogsTable < ActiveRecord::Migration[5.1]
  def change
    change_column :call_logs, :call_room_id, :string, null: false, default: " "
  end
end
