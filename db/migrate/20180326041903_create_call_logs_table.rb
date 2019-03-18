class CreateCallLogsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :call_logs do |t|
      t.string :call_event, null: false
      t.string :message
      t.integer :caller_user_id, null: false
      t.integer :callee_user_id, null: false
      t.integer :application_id, null: false
      t.timestamps
    end

    add_foreign_key :call_logs, :users, column: :caller_user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :call_logs, :users, column: :callee_user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :call_logs, :applications, column: :application_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
