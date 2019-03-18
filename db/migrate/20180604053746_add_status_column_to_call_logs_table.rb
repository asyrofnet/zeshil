class AddStatusColumnToCallLogsTable < ActiveRecord::Migration[5.1]
  def change
    # set enum
    # set default value 1 (:unknown) to avoid migration error since there are existing call_logs data
    add_column :call_logs, :status, :integer, null: false, default: 1
  end
end
