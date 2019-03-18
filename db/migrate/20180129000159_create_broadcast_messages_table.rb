class CreateBroadcastMessagesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :broadcast_messages do |t|
      t.text :message, null: true
      t.integer :user_id, null: false
      t.integer :application_id, null: false
      t.timestamps
    end

    add_foreign_key :broadcast_messages, :users, column: :user_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
    add_foreign_key :broadcast_messages, :applications, column: :application_id, primary_key: :id, on_delete: :cascade, on_update: :cascade
  end
end
