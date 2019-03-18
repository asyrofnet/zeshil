class AddCallRoomIdToCallLogsTable < ActiveRecord::Migration[5.1]
  def change
    # default = 0 to avoid error when migrate, since it must not null
    add_column :call_logs, :call_room_id, :integer, null: false, default: 0
  end
end
