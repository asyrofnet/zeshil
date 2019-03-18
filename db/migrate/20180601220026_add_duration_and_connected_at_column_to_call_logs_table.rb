class AddDurationAndConnectedAtColumnToCallLogsTable < ActiveRecord::Migration[5.1]
  def change
    add_column :call_logs, :duration, :string, null: true
    add_column :call_logs, :connected_at, :datetime, null: true
  end
end
